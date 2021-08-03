SEC_WEBSOCKET_KEY_HEADER_KEY :: "Sec-WebSocket-Key";
SEC_WEBSOCKET_ACCEPT_MAGIC_STRING :: "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";


libcrypto :: #foreign_system_library "libcrypto";
SHA1 :: (d: *u8, n: u64, md: *u8) -> *u8 #foreign libcrypto;

WebsocketServer :: struct {
  websocket_connections: [..]*WebsocketConnection;
  mutex: Mutex;
}

WebsocketConnection :: struct {
  thread: Thread;
  http_request: HttpRequest;
  websocket_server: *WebsocketServer;
}

init :: (using websocket_server: *WebsocketServer) {
  init(*mutex);
  remember_allocators(*websocket_connections);
}

add_connection :: (using websocket_server: *WebsocketServer, request: HttpRequest) -> success: bool {
  sec_websocket_key_header := find_header(request.headers, SEC_WEBSOCKET_KEY_HEADER_KEY);
  if !sec_websocket_key_header {
    write(request.connection_fd, "HTTP/1.1 400 Bad Request\r\nContent-Type: text/plain\r\n\r\nBad Request");
    close(request.connection_fd);
    return false;
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
    push_allocator(websocket_connections.allocator, websocket_connections.allocator_data);

    websocket_connection := New(WebsocketConnection);
    websocket_connection.websocket_server = websocket_server;
    websocket_connection.http_request = copy(request);
    websocket_connection.thread.data = websocket_connection;

    thread_init(*websocket_connection.thread, websocket_connection_proc);
    thread_start(*websocket_connection.thread);

    array_add(*websocket_connections, websocket_connection);
  }

  return true;
}

websocket_connection_proc :: (thread: *Thread) -> s64 {
  websocket_connection := cast(*WebsocketConnection)thread.data;

  print("handling websocket\n");

  next_byte: u8;
  bytes_read := read(websocket_connection.http_request.connection_fd, *next_byte, size_of(u8));
  while bytes_read == size_of(u8) {
    current_byte_string: string;
    current_byte_string.count = 1;
    current_byte_string.data = *next_byte;
    print("%", current_byte_string);
    bytes_read := read(websocket_connection.http_request.connection_fd, *next_byte, size_of(u8));
  }
  
  print("closed websocket\n");

  return 0;
}
