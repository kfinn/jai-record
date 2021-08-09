HTTP_HOST :: 0;
HTTP_PORT :: 7000;

HTTP_CONTENT_LENGTH_HEADER_KEY :: "Content-Length";
UPGRADE_HEADER_KEY :: "Upgrade";
UPGRADE_HEADER_WEBSOCKET_VALUE :: "websocket";

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
    WEBSOCKET_MESSAGE;
  }
  kind: Kind;
}

HttpConnectionWork :: struct {
  using base: HttpServerWorkBase;
  base.kind = .HTTP_CONNECTION;

  connection_fd: s32;
}

WebsocketMessageWork :: struct {
  using base: HttpServerWorkBase;
  base.kind = .WEBSOCKET_MESSAGE;

  websocket_message: WebsocketMessage;
}

HttpServer :: struct {
  mutex: Mutex;
  websocket_server: WebsocketServer;
  thread_group: Thread_Group;

  allocator: Allocator;
  allocator_data: *void;
}

http_server_run :: () {
  http_server: HttpServer;
  init(*http_server);
  run(*http_server);
}

init :: (using http_server: *HttpServer) {
  websocket_server.http_server = http_server;
  init(*websocket_server);

  thread_group.logging = false;
  thread_group.data = http_server;
  init(*thread_group, 5, http_server_work);

  remember_allocators(http_server);
}

run :: (using http_server: *HttpServer) {
  socket_fd := socket(AF_INET, SOCK_STREAM, 0);
  defer close(socket_fd);

  reuseaddr_value: s32 = 1;
  setsockopt_status := setsockopt(socket_fd, SOL_SOCKET, SO_REUSEADDR, *reuseaddr_value, size_of(s32));

  bind_status := bind(socket_fd, HTTP_HOST, HTTP_PORT);
  assert(bind_status == 0, "Unable to to bind socket to port. Is the socket in use? Status: %", bind_status);

  listen_status := listen(socket_fd, 40);
  assert(listen_status == 0, "Unable to listen to socket. Status: %", listen_status);

  start(*thread_group);

  print("http_server awaiting connections\n");
  while true {
    connection_fd := accept(socket_fd);
    add_http_connection_work(http_server, connection_fd);
    clear_completed_work(http_server);
  }
}

add_http_connection_work :: (http_server: *HttpServer, connection_fd: s32) {
  push_lock(*http_server.mutex);
  push_allocator(http_server.allocator, http_server.allocator_data);

  http_connection_work := New(HttpConnectionWork);
  http_connection_work.connection_fd = connection_fd;

  add_work(
    *http_server.thread_group,
    http_connection_work
  );
}

add_websocket_message_work :: (http_server: *HttpServer, websocket_message: WebsocketMessage) {
  push_lock(*http_server.mutex);
  push_allocator(http_server.allocator, http_server.allocator_data);

  websocket_message_work := New(WebsocketMessageWork);
  websocket_message_work.websocket_message = websocket_message;
  websocket_message_work.websocket_message.payload = array_copy(websocket_message.payload);

  add_work(
    *http_server.thread_group,
    websocket_message_work
  );
}

clear_completed_work :: (using http_server: *HttpServer) {
  push_lock(*http_server.mutex);
  push_allocator(allocator, allocator_data);

  for get_completed_work(*thread_group) {
    http_server_work_base := cast(*HttpServerWorkBase)it;

    if #complete http_server_work_base.kind == {
      case .HTTP_CONNECTION;
        free(cast(*HttpConnectionWork)it);
      case .WEBSOCKET_MESSAGE; 
        websocket_message_work := cast(*WebsocketMessageWork)it;
        array_free(websocket_message_work.websocket_message.payload);
        free(websocket_message_work);
    }
  }
}

http_server_work :: (group: *Thread_Group, thread: *Thread, work: *void) -> Thread_Continue_Status {
  http_server_work_base := cast(*HttpServerWorkBase)work;
  if #complete http_server_work_base.kind == {
    case .HTTP_CONNECTION;
      return perform_http_connection_work(group, thread, xx http_server_work_base);
    case .WEBSOCKET_MESSAGE;
      return perform_websocket_message_work(group, thread, xx http_server_work_base);
  }
}

perform_http_connection_work :: (group: *Thread_Group, thread: *Thread, work: *HttpConnectionWork) -> Thread_Continue_Status {
  connection_fd := work.connection_fd;

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
      return .CONTINUE;
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

perform_websocket_message_work :: (group: *Thread_Group, thread: *Thread, work: *WebsocketMessageWork) -> Thread_Continue_Status {
  print("perform_websocket_message_work\n");
  print("websocket_message_work payload: %\n", cast(string)(work.websocket_message.payload));

  TodosChannelMessage :: struct {
    channel: string;
    action: string;
    todo_id: int;
  }
  json_parse_success, todos_channel_message, todos_channel_message_meta := parse_json_params(
    TodosChannelMessage,
    cast(string)work.websocket_message.payload
  );

  if todos_channel_message.channel == "TodosChannel" {
    if todos_channel_message.action == {
      case "completed";
        TodosChannel.completed(work.websocket_message.websocket_connection, todos_channel_message.todo_id);
      case "uncompleted";
        TodosChannel.uncompleted(work.websocket_message.websocket_connection, todos_channel_message.todo_id);
      case;
        print("unexpected action: %\n", todos_channel_message.action);
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
  http_server_thread_group_data := cast(*HttpServer)group.data;
  add_connection(*http_server_thread_group_data.websocket_server, request);
};

parse_http_request :: (connection_fd: s32) -> HttpRequest, success: bool, error_response: string {
  validate :: (condition: bool, $message: string = "Internal Server Error", print_args: ..Any) #expand {
    if !condition {
      formatted_message := sprint(message, ..print_args);
      `return .{}, false, sprint("HTTP/1.1 500 Internal Server Error\r\nContent-Type: text/plain\r\n\r\n%", formatted_message);
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

copy :: (http_request: HttpRequest) -> HttpRequest {
  copied_http_request := http_request;
  copied_http_request.path = copy_string(http_request.path);
  copied_http_request.body = copy_string(http_request.body);
  copied_http_request.headers = copy(http_request.headers);
  return copied_http_request;
}

copy :: (http_headers: HttpHeaders) -> HttpHeaders {
  copied_http_headers: [..]HttpHeader;
  for http_headers {
    copied_header: HttpHeader;
    copied_header.key = copy_string(it.key);
    copied_header.value = copy_string(it.value);
    array_add(*copied_http_headers, copied_header);
  }
  return copied_http_headers;
}

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
