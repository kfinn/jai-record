HTTP_HOST :: 0;
HTTP_PORT :: 7000;

HTTP_CONTENT_LENGTH_HEADER_KEY :: "Content-Length";
UPGRADE_HEADER_KEY :: "Upgrade";
UPGRADE_HEADER_WEBSOCKET_VALUE :: "websocket";
SEC_WEBSOCKET_ACCEPT_MAGIC_STRING :: "258EAFA5-E914-47DA-95CA-C5AB0DC85B11";

libcrypto :: #foreign_system_library "libcrypto";
SHA1 :: (d: *u8, n: u64, md: *u8) -> *u8 #foreign libcrypto;

HttpMethod :: enum {
  GET;
  PATCH;
}

HttpRequest :: struct {
  method: HttpMethod;
  path: string;
  headers: HttpHeaders;
  body: string;
  connection_fd: s32;
}

HttpServerWorkBase :: struct {
  Kind :: enum {
    HTTP_CONNECTION;
    WEBSOCKET_CONNECTION;
  }

  kind: Kind;
  connection_fd: s32;
}

HttpConnectionWork :: struct {
  using base: HttpServerWorkBase;
  base.kind = .HTTP_CONNECTION;
}

WebsocketConnectionWork :: struct {
  using base: HttpServerWorkBase;
  base.kind = .WEBSOCKET_CONNECTION;

  pending_message_bytes: []u8;
  mutex: Mutex;
}

http_server_run :: () {
  fd := socket(AF_INET, SOCK_STREAM, 0);
  defer close(fd);

  reuseaddr_value: s32 = 1;
  setsockopt_status := setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, *reuseaddr_value, size_of(s32));

  bind_status := bind(fd, HTTP_HOST, HTTP_PORT);
  assert(bind_status == 0, "Unable to to bind socket to port. Is the socket in use? Status: %", bind_status);

  listen_status := listen(fd, 40);
  assert(listen_status == 0, "Unable to listen to socket. Status: %", listen_status);

  thread_group: Thread_Group;
  thread_group.logging = false;
  init(*thread_group, 5, http_server_work);
  start(*thread_group);

  print("http_server awaiting connections\n");
  while true {
    work := New(HttpConnectionWork);
    work.connection_fd = accept(fd);
    add_work(*thread_group, work);
    clear_completed_work(*thread_group);
  }
}

clear_completed_work :: (thread_group: *Thread_Group) {
  for get_completed_work(thread_group) {
    if #complete (cast(*HttpServerWorkBase)it).kind == {
      case .HTTP_CONNECTION; free(cast(*HttpConnectionWork)it);
      case .WEBSOCKET_CONNECTION; free(cast(*WebsocketConnectionWork)it);
    }
  }
}

http_server_work :: (group: *Thread_Group, thread: *Thread, work: *void) -> Thread_Continue_Status {
  if #complete (cast(*HttpServerWorkBase)work).kind == {
    case .HTTP_CONNECTION;
      return perform_http_connection_work(group, thread, cast(*HttpConnectionWork)work);
    case .WEBSOCKET_CONNECTION;
      return perform_websocket_connection_work(group, thread, cast(*WebsocketConnectionWork)work);
  }

  return .CONTINUE;
}

perform_http_connection_work :: (group: *Thread_Group, thread: *Thread, work: *HttpConnectionWork) -> Thread_Continue_Status {
  connection_fd := (cast(*HttpServerWorkBase)work).connection_fd;

  pool: Pool;
  set_allocators(*pool);
  defer release(*pool);

  {
    push_jai_record_pg_connection_context();
    push_allocator(pool_allocator, *pool);
    auto_release_temp();

    request, success, error_response := parse_http_request(connection_fd);
    if !success {
      write(connection_fd, error_response);
      close(connection_fd);
    }

    print("% % %\n", request.method, request.path, request.body);

    websocket_upgrade_header: *HttpHeader;
    upgrade_header := find_header(request.headers, UPGRADE_HEADER_KEY);
    if upgrade_header && upgrade_header.value == UPGRADE_HEADER_WEBSOCKET_VALUE {
      handle_websocket_upgrade_request(group, thread, request);
    } else if handle_request_with_resources(request) {
      close(connection_fd);
    } else {
      write(connection_fd, "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\n\r\nNot Found");
      close(connection_fd);
    }
  }

  return .CONTINUE;
}

find_header :: (headers: HttpHeaders, key: string) -> *HttpHeader {
  for * headers {
    if it.key == key return it;
  }
  return null;
}

handle_websocket_upgrade_request :: (group: *Thread_Group, thread: *Thread, request: HttpRequest) {
  sec_websocket_accept_header := find_header(request.headers, "Sec-WebSocket-Key");
  if !sec_websocket_accept_header {
    write(request.connection_fd, "HTTP/1.1 400 Bad Request\r\nContent-Type: text/plain\r\n\r\nBad Request");
    close(request.connection_fd);
  }
  sec_websocket_accept_value := sec_websocket_accept_header.value;
  print("sec_websocket_accept_value: %\n", sec_websocket_accept_value);

  sec_websocket_accept_value_with_magic_string := join(sec_websocket_accept_value, SEC_WEBSOCKET_ACCEPT_MAGIC_STRING);

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
  print("sec_websocket_accept_header_value: %\n", sec_websocket_accept_header_value);
  write(request.connection_fd, "HTTP/1.1 101 Switching Protocols\r\nUpgrade: websocket\r\nConnection: Upgrade\r\nSec-WebSocket-Accept: %\r\n\r\n", sec_websocket_accept_header_value);
};

perform_websocket_connection_work :: (group: *Thread_Group, thread: *Thread, work: *WebsocketConnectionWork) -> Thread_Continue_Status {
  print("perform_websocket_connection_work\n");
  return .CONTINUE;
}

parse_http_request :: (connection_fd: s32) -> HttpRequest, success: bool, error_response: string {
  error_response := "";

  validate :: (condition: bool, $message: string = "Internal Server Error", print_args: ..Any) #expand {
    if !condition {
      formatted_message := sprint(message, ..print_args);
      error_response = sprint("HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/plain\r\n\r\n%", formatted_message);
      `return .{}, false, error_response;
    }
  };

  first_line, read_first_line_success := read_http_line(connection_fd);
  validate(read_first_line_success);
  first_line_components := split(first_line, " ");

  validate(first_line_components.count == 3);
  method_string := first_line_components[0];
  method, parse_http_method_success := parse_http_method(method_string);
  validate(parse_http_method_success, "Invalid HTTP method: %", method_string);

  path := first_line_components[1];

  http_version := first_line_components[2];
  validate(http_version == "HTTP/1.1", "Invalid HTTP version: %", http_version);

  headers, parse_http_headers_success := parse_http_headers(connection_fd);
  validate(parse_http_headers_success, "Invalid HTTP headers");

  content_length_header: *HttpHeader;
  for * headers {
    if it.key == HTTP_CONTENT_LENGTH_HEADER_KEY {
      validate(!content_length_header, "Multiple % headers detected on same request", HTTP_CONTENT_LENGTH_HEADER_KEY);
      content_length_header = it;
    }
  }
  content_length := 0;
  body := "";
  if content_length_header {
    content_length, parse_content_length_success := parse_int(*content_length_header.value);
    validate(parse_content_length_success, "Invalid % header: %", HTTP_CONTENT_LENGTH_HEADER_KEY, content_length_header.value);


    read_http_body_success: bool;
    body, read_http_body_success = read_http_body(connection_fd, content_length);
    validate(read_http_body_success, "unable to parse HTTP body");
  }

  request: HttpRequest;
  request.method = method;
  request.path = path;
  request.headers = headers;
  request.body = body;
  request.connection_fd = connection_fd;

  return request, true, "";
}

read_http_line :: (connection_fd: s32) -> string, success: bool {
  bytes: [..]u8;

  next_byte: u8;
  bytes_read := read(connection_fd, *next_byte, size_of(u8));
  while bytes_read == size_of(u8) {
    array_add(*bytes, next_byte);

    if (
      bytes.count >= 2 &&
      bytes[bytes.count - 2] == #char "\r" &&
      bytes[bytes.count - 1] == #char "\n"
    ) break;

    bytes_read := read(connection_fd, *next_byte, size_of(u8));
  }
  if bytes_read != size_of(u8) return "", false;

  if bytes.count == 2 {
    return "", true;
  }

  result: string;
  result.count = bytes.count - 2;
  result.data = bytes.data;
  return result, true;
}

parse_http_method :: (method_string: string) -> HttpMethod, success: bool {
  #insert #run () -> string {
    string_builder: String_Builder;
    defer free_buffers(*string_builder);

    print_to_builder(*string_builder, "if method_string == {\n");
    http_method_type_info := type_info(HttpMethod);
    for http_method_type_info.names {
      print_to_builder(*string_builder, "  case \"%\";\n", it);
      print_to_builder(*string_builder, "    return .%, true;\n", it);
    }
    print_to_builder(*string_builder, "  case;\n");
    print_to_builder(*string_builder, "    return .GET, false;\n");

    print_to_builder(*string_builder, "}");

    return builder_to_string(*string_builder);
  }();
}

HttpHeaders :: []HttpHeader;
HttpHeader :: struct {
  key: string;
  value: string;
};

parse_http_headers :: (connection_fd: s32) -> HttpHeaders, success: bool {
  result: [..]HttpHeader;

  next_line := read_http_line(connection_fd);
  while next_line != "" {
    http_header, parse_http_header_success := parse_http_header(next_line);
    if !parse_http_header_success {
      array_reset(*result);
      return .[], false;
    }

    array_add(*result, http_header);

    next_line = read_http_line(connection_fd);
  }

  return result, true;
}

parse_http_header :: (header_line: string) -> HttpHeader, success: bool {
  DELIMITER :: ": ";

  delimiter_start_index: int;
  delimiter_found := false;

  for 0..(header_line.count - DELIMITER.count - 1) {
    if slice(header_line, it, DELIMITER.count) == DELIMITER {
      delimiter_start_index = it;
      delimiter_found = true;
      break;
    }
  }
  if !delimiter_found return .{}, false;

  result: HttpHeader;
  result.key = slice(header_line, 0, delimiter_start_index);
  result.value = slice(header_line, delimiter_start_index + DELIMITER.count, header_line.count - (delimiter_start_index + DELIMITER.count));
  return result, true;
}

read_http_body :: (connection_fd: s32, content_length: int) -> string, success: bool {
  http_body_bytes := NewArray(content_length, u8);

  bytes_read := 0;
  while bytes_read < content_length {
    bytes_remaining := content_length - bytes_read;
    if bytes_remaining <= 0 return "", false;

    to_read := size_of(u8) * cast(u64)bytes_remaining;
    bytes_read += read(connection_fd, http_body_bytes.data + bytes_read, to_read);
  }

  body: string;
  body.count = http_body_bytes.count;
  body.data = http_body_bytes.data;
  return body, true;
}
