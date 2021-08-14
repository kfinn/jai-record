SEC_WEBSOCKET_KEY_HEADER_KEY :: "Sec-WebSocket-Key";
SEC_WEBSOCKET_ACCEPT_MAGIC_STRING :: "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

WEBSOCKET_MEDIUM_CONTENT_LENGTH_MAX :: 65535;


libcrypto :: #foreign_system_library "libcrypto";
SHA1 :: (d: *u8, n: u64, md: *u8) -> *u8 #foreign libcrypto;

WebsocketServer :: struct {
  web_executor: *WebExecutor;
  websocket_connections: [..]*WebsocketConnection;

  mutex: Mutex;

  allocator: Allocator;
  allocator_data: *void;
}

WebsocketConnection :: struct {
  thread: Thread;
  http_request: HttpRequest;
  websocket_server: *WebsocketServer;

  write_mutex: Mutex;
  message_handler: (websocket_message: WebsocketMessage) -> ();
  closed: bool = false;
}

init :: (using websocket_server: *WebsocketServer) {
  remember_allocators(websocket_server);
  init(*mutex);
}

handle_websocket_upgrade_request :: (request: HttpRequest, message_handler: (websocket_message: WebsocketMessage) -> ()) {
  add_connection(*request.http_server.websocket_server, request, message_handler);
};

add_connection :: (using websocket_server: *WebsocketServer, request: HttpRequest, message_handler: (websocket_message: WebsocketMessage) -> ()) {
  sec_websocket_key_header := find_header(request.headers, SEC_WEBSOCKET_KEY_HEADER_KEY);
  if !sec_websocket_key_header {
    write(request.connection_fd, "HTTP/1.1 400 Bad Request\r\nContent-Type: text/plain\r\n\r\nBad Request");
    close(request.connection_fd);
    return;
  }
  sec_websocket_accept_value_with_magic_string := join(
    sec_websocket_key_header.value,
    SEC_WEBSOCKET_ACCEPT_MAGIC_STRING
  );

  sha1_bytes: [20]u8;
  SHA1(
    sec_websocket_accept_value_with_magic_string.data,
    xx sec_websocket_accept_value_with_magic_string.count,
    sha1_bytes.data
  );

  sha1_string: string;
  sha1_string.count = sha1_bytes.count;
  sha1_string.data = sha1_bytes.data;
  sec_websocket_accept_header_value := base64_encode(sha1_string);
  write(request.connection_fd, "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: %\r\n\r\n", sec_websocket_accept_header_value);

  {
    push_lock(*mutex);
    push_allocator(allocator, allocator_data);

    websocket_connection := New(WebsocketConnection);
    init(*websocket_connection.write_mutex);
    websocket_connection.websocket_server = websocket_server;
    websocket_connection.http_request = copy(request);
    websocket_connection.message_handler = message_handler;

    websocket_connection.thread.data = websocket_connection;

    thread_init(*websocket_connection.thread, websocket_connection_proc);
    thread_start(*websocket_connection.thread);

    array_add(*websocket_connections, websocket_connection);

    for websocket_connections {
      if it.closed {
        thread_uninit(*it.thread);
        remove it;
        free(it);
      }
    }
  }
}

websocket_connection_proc :: (thread: *Thread) -> s64 {
  websocket_connection := cast(*WebsocketConnection)thread.data;

  while !websocket_connection.closed {
    pool: Pool;
    set_allocators(*pool);
    defer release(*pool);
    {
      push_allocator(pool_allocator, *pool);
      auto_release_temp();

      websocket_message, success := read_websocket_message(websocket_connection);
      if success {
        add_websocket_message_work(websocket_message);
      } else {
        push_lock(*websocket_connection.write_mutex);
        websocket_connection.closed = true;
      }
    }
  }

  return 0;
}

WebsocketMessageWork :: struct {
  using base: WebExecutorWorkBase;
  base.type = WebsocketMessageWork;
  base.perform = perform_websocket_message_work;
  base.cleanup = cleanup_websocket_message_work;

  websocket_message: WebsocketMessage;
}

copy :: (websocket_message_work: WebsocketMessageWork) -> *WebsocketMessageWork {
  result := New(WebsocketMessageWork);
  <<result = websocket_message_work;

  copied_payload := NewArray(
    websocket_message_work.websocket_message.payload.count,
    u8
  );
  memcpy(
    copied_payload.data,
    websocket_message_work.websocket_message.payload.data,
    size_of(u8) * websocket_message_work.websocket_message.payload.count
  );
  result.websocket_message.payload = copied_payload;
  
  return result;
}

perform_websocket_message_work :: (web_executor_work: *WebExecutorWorkBase) -> Thread_Continue_Status {
  websocket_message_work := cast(*WebsocketMessageWork)web_executor_work;
  websocket_message := websocket_message_work.websocket_message;
  websocket_connection := websocket_message.websocket_connection;

  print("websocket_message.kind: %\n", websocket_message.kind);
  if websocket_message.kind == {
    case .TEXT; #through;
    case .BINARY;
      print("websocket_message.payload: %\n", cast(string)websocket_message.payload);
      websocket_connection
        .message_handler(
          websocket_message
        );
    case .PING;
      push_lock(
        *websocket_connection.write_mutex
      );
      write_websocket_frame(
        websocket_connection.http_request.connection_fd,
        pong_frame_response_from_message(websocket_message)
      );
    case .PONG;
      print("pong: %\n", websocket_message);
    case .CLOSE;
      push_lock(
        *websocket_connection.write_mutex
      );
      write_websocket_frame(
        websocket_connection.http_request.connection_fd,
        close_frame_response_from_message(websocket_message)
      );
      close(websocket_connection.http_request.connection_fd);
      websocket_connection.closed = true;
  }

  return .CONTINUE;
}

cleanup_websocket_message_work :: (web_executor_work: *WebExecutorWorkBase) {
  websocket_message_work := cast(*WebsocketMessageWork)web_executor_work;

  array_free(websocket_message_work.websocket_message.payload);
  free(websocket_message_work);
}

add_websocket_message_work :: (websocket_message: WebsocketMessage) {
  websocket_message_work: WebsocketMessageWork;
  websocket_message_work.websocket_message = websocket_message;

  add_work(
    websocket_message.websocket_connection.websocket_server.web_executor,
    websocket_message_work
  );
}

WebsocketMessage :: struct {
  Kind :: enum {
    TEXT;
    BINARY; 
    CLOSE;
    PING;
    PONG;
  }
  websocket_connection: *WebsocketConnection;
  kind: Kind;
  payload: []u8;
}

read_websocket_message :: (websocket_connection: *WebsocketConnection) -> WebsocketMessage, success: bool {
  validate :: (condition: bool, $message: string = "Internal Server Error", print_args: ..Any) #expand {
    if !condition {
      print(join(message, "\n"), ..print_args);
      `return .{}, false;
    }
  };

  connection_fd := websocket_connection.http_request.connection_fd;

  next_websocket_frame: WebsocketFrame;
  success: bool;
  next_websocket_frame, success = read_websocket_frame(connection_fd);
  validate(success, "unable to read websocket frame");

  websocket_message: WebsocketMessage;
  websocket_message.websocket_connection = websocket_connection;
  websocket_message.kind, success = parse_websocket_message_kind_from_first_frame(next_websocket_frame);
  validate(success, "encountered first frame in message with continuation opcode");

  payload_builder: [..]u8;
  for next_websocket_frame.payload {
    array_add(*payload_builder, it);
  }

  while !next_websocket_frame.fin {
    next_websocket_frame = read_websocket_frame(connection_fd);
    validate(next_websocket_frame.opcode == .CONTINUATION, "encountered subsequent frame in message with non-continuation opcode");

    for next_websocket_frame.payload {
      array_add(*payload_builder, it);
    }
  }

  websocket_message.payload = payload_builder;
  return websocket_message, true;
}

parse_websocket_message_kind_from_first_frame :: (first_websocket_frame: WebsocketFrame) -> WebsocketMessage.Kind, success: bool {
  if #complete first_websocket_frame.opcode == {
    case .CONTINUATION; return 0, false;
    case .TEXT; return .TEXT, true;
    case .BINARY; return .BINARY, true;
    case .CLOSE; return .CLOSE, true;
    case .PING; return .PING, true;
    case .PONG; return .PONG, true;
  }
}

WebsocketFrame :: struct {
  Opcode :: enum {
    CONTINUATION :: 0x0;
    TEXT :: 0x1;
    BINARY :: 0x2;
    CLOSE :: 0x8;
    PING :: 0x9;
    PONG :: 0xA;
  }

  fin: bool;
  opcode: Opcode;
  payload: []u8;
}

read_websocket_frame :: (connection_fd: s32) -> WebsocketFrame, success: bool {
  validate :: (condition: bool, $message: string, print_args: ..Any) #expand {
    if !condition {
      print(join(message, "\n"), ..print_args);
      `return .{}, false;
    }
  };

  websocket_frame: WebsocketFrame;

  bytes_read: ssize_t;
  next_byte: u8;
  bytes_read = read(connection_fd, *next_byte, size_of(u8));
  validate(bytes_read == size_of(u8), "failed to read first byte of frame");

  websocket_frame.fin = parse_fin_from_frame_first_byte(next_byte);
  success := true;
  websocket_frame.opcode, success = parse_opcode_from_frame_first_byte(next_byte);
  validate(success, "failed to parse opcode");

  bytes_read = read(connection_fd, *next_byte, size_of(u8));
  validate(bytes_read == size_of(u8), "failed to read second byte of frame");

  is_masked := parse_is_masked_from_frame_second_byte(next_byte);
  validate(is_masked, "received unmasked data");

  maybe_length := parse_maybe_length_from_frame_second_byte(next_byte);

  length: s64;
  if maybe_length == 126 {
    medium_length: u16;
    bytes_read = read(connection_fd, *medium_length, size_of(u16));
    validate(bytes_read == size_of(u16), "failed to read content length of frame (medium length)");
    length = ntoh(medium_length);
  } else if maybe_length == 127 {
    bytes_read = read(connection_fd, *length, size_of(s64));
    validate(bytes_read == size_of(s64), "failed to read content length of frame");
    length = ntoh(length);
  } else {
    length = maybe_length;
  }

  mask: [4]u8;
  bytes_read = read(connection_fd, *mask, size_of(u8) * 4);
  validate(bytes_read == size_of(u8) * 4, "failed to read frame mask");

  websocket_frame.payload = NewArray(length, u8);
  total_payload_bytes_read := 0;
  while total_payload_bytes_read < length {
    total_payload_bytes_read += read(
      connection_fd,
      websocket_frame.payload.data + total_payload_bytes_read,
      xx (size_of(u8) * (length - total_payload_bytes_read))
    );
  }
  for * websocket_frame.payload {
    <<it = <<it ^ mask[it_index % 4];
  }
  return websocket_frame, true;
}

parse_fin_from_frame_first_byte :: (first_byte: u8) -> bool {
  return (first_byte & (1 << 7)) != 0;
}

parse_opcode_from_frame_first_byte :: (first_byte: u8) -> WebsocketFrame.Opcode, success: bool {
  if first_byte & 0xF == {
    case 0x0; return .CONTINUATION, true;
    case 0x1; return .TEXT, true;
    case 0x2; return .BINARY, true;
    case 0x8; return .CLOSE, true;
    case 0x9; return .PING, true;
    case 0xA; return .PONG, true;
    case;
      print("Invalid opcode: %\n", first_byte & 0xF);
      return 0, false;
  }
}

parse_is_masked_from_frame_second_byte :: (second_byte: u8) -> bool {
  return (second_byte & (1 << 7)) != 0;
}

parse_maybe_length_from_frame_second_byte :: (second_byte: u8) -> u8 {
  return second_byte & 0x7f;
}

write_websocket_message :: (websocket_message: WebsocketMessage) {
  websocket_frame: WebsocketFrame;
  websocket_frame.fin = true;
  if #complete websocket_message.kind == {
    case .TEXT;
      websocket_frame.opcode = .TEXT;
    case .BINARY; 
      websocket_frame.opcode = .BINARY;
    case .CLOSE;
      websocket_frame.opcode = .CLOSE;
    case .PING;
      websocket_frame.opcode = .PING;
    case .PONG;
      websocket_frame.opcode = .PONG;
  }
  websocket_frame.payload = websocket_message.payload;

  write_websocket_frame(websocket_message.websocket_connection.http_request.connection_fd, websocket_frame);
}

write_websocket_frame :: (connection_fd: s32, websocket_frame: WebsocketFrame) {
  bytes_written: ssize_t;
  first_byte := websocket_frame_first_byte(websocket_frame);
  bytes_written = write(connection_fd, *first_byte, size_of(u8));
  assert(bytes_written == size_of(u8), "failed to write first byte of frame");
  
  is_masked_and_content_length_bytes := websocket_frame_is_masked_and_content_length_bytes(websocket_frame);
  bytes_written = write(connection_fd, is_masked_and_content_length_bytes.data, xx (size_of(u8) * is_masked_and_content_length_bytes.count));
  assert(bytes_written == size_of(u8) * is_masked_and_content_length_bytes.count, "failed to write frame is masked and content length");

  total_payload_bytes_written := 0;
  while total_payload_bytes_written < websocket_frame.payload.count {
    total_payload_bytes_written += write(
      connection_fd,
      websocket_frame.payload.data + total_payload_bytes_written,
      xx (size_of(u8) * (websocket_frame.payload.count - total_payload_bytes_written))
    );
  }
}

websocket_frame_first_byte :: (using websocket_frame: WebsocketFrame) -> u8 {
  result: u8;
  if fin {
    result |= 1 << 7;
  }
  if #complete websocket_frame.opcode == {
    case .CONTINUATION; result |= 0x0;
    case .TEXT; result |= 0x1;
    case .BINARY; result |= 0x2;
    case .CLOSE; result |= 0x8;
    case .PING; result |= 0x9;
    case .PONG; result |= 0xA;
  }
  return result;
}

websocket_frame_is_masked_and_content_length_bytes :: (using websocket_frame: WebsocketFrame) -> []u8 {
  result: [..]u8;

  if payload.count > WEBSOCKET_MEDIUM_CONTENT_LENGTH_MAX {
    array_add(*result, 127);
    network_encoded_u64_length := ntoh(payload.count);
    network_encoded_u64_length_bytes: [..]u8;
    network_encoded_u64_length_bytes.count = size_of(u64) / size_of(u8);
    network_encoded_u64_length_bytes.data = xx *network_encoded_u64_length;
    array_add(*result, ..network_encoded_u64_length_bytes);
  } else if payload.count >= 126 {
    array_add(*result, 126);
    network_encoded_u16_length := ntoh(cast(u16)payload.count);
    network_encoded_u16_length_bytes: [..]u8;
    network_encoded_u16_length_bytes.count = size_of(u16) / size_of(u8);
    network_encoded_u16_length_bytes.data = xx *network_encoded_u16_length;
    array_add(*result, ..network_encoded_u16_length_bytes);
  } else {
    array_add(*result, xx payload.count);
  }

  return result;
}

close_frame_response_from_message :: (message: WebsocketMessage) -> WebsocketFrame {
  close_frame: WebsocketFrame;
  close_frame.fin = true;
  close_frame.opcode = .CLOSE;

  if message.payload.count >= 2 {
    close_frame.payload.count = 2;
    close_frame.payload.data = message.payload.data;
  }

  return close_frame;
}

pong_frame_response_from_message :: (message: WebsocketMessage) -> WebsocketFrame {
  pong_frame: WebsocketFrame;
  pong_frame.fin = true;
  pong_frame.opcode = .PONG;
  pong_frame.payload = message.payload;
  return pong_frame;
}
