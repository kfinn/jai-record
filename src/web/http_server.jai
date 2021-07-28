HTTP_HOST :: 0;
HTTP_PORT :: 7000;

HTTP_CONTENT_LENGTH_HEADER_KEY :: "Content-Length";

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

http_server_run :: (handle: (connection_fd: s32) -> () = default_handle) {
  fd := socket(AF_INET, SOCK_STREAM, 0);
  defer close(fd);

  reuseaddr_value: s32 = 1;
  setsockopt_status := setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, *reuseaddr_value, size_of(s32));

  bind_status := bind(fd, HTTP_HOST, HTTP_PORT);
  assert(bind_status == 0, "Unable to to bind socket to port. Is the socket in use? Status: %", bind_status);

  listen_status := listen(fd, 40);
  assert(listen_status == 0, "Unable to listen to socket. Status: %", listen_status);

  print("http_server awaiting connections\n");
  while true {
    connection_fd := accept(fd);
    pool: Pool;
    set_allocators(*pool);
    {
      push_allocator(pool_allocator, *pool);
      auto_release_temp();
      handle(connection_fd);
    }
    reset(*pool);
  }
}

default_handle :: (connection_fd: s32) {
  first_line := read_http_line(connection_fd);
  first_line_components := split(first_line, " ");

  assert(first_line_components.count == 3);
  method_string := first_line_components[0];
  method, parse_http_method_success := parse_http_method(method_string);
  assert(parse_http_method_success, "Invalid HTTP method: %", method_string);

  path := first_line_components[1];

  http_version := first_line_components[2];
  assert(http_version == "HTTP/1.1", "Invalid HTTP version: %", http_version);

  headers, parse_http_headers_success := parse_http_headers(connection_fd);
  assert(parse_http_headers_success, "Invalid HTTP headers");

  content_length_header: *HttpHeader;
  for * headers {
    if it.key == HTTP_CONTENT_LENGTH_HEADER_KEY {
      assert(!content_length_header, "Multiple % headers detected on same request", HTTP_CONTENT_LENGTH_HEADER_KEY);
      content_length_header = it;
    }
  }
  content_length := 0;
  body := "";
  if content_length_header {
    print("reading http body\n");
    content_length, parse_content_length_success := parse_int(*content_length_header.value);
    assert(parse_content_length_success, "Invalid % header: %", HTTP_CONTENT_LENGTH_HEADER_KEY, content_length_header.value);
    print("length: %\n", content_length);


    read_http_body_success: bool;
    body, read_http_body_success = read_http_body(connection_fd, content_length);
    assert(read_http_body_success, "unable to parse HTTP body");
    print("body: % (length: %)\n", body, body.count);
  }

  request: HttpRequest;
  request.method = method;
  request.path = path;
  request.headers = headers;
  request.body = body;
  request.connection_fd = connection_fd;
  
  print("% % %\n", request.method, request.path, request.body);

  handled := handle_request_with_resources(request);

  if !handled {
    response := "HTTP/1.1 404 Not Found\r\nContent-Type: text/plain\r\n\r\nNot Found";
    bytes_written := write(connection_fd, response);
    assert(bytes_written == response.count);
  }

  close(connection_fd);
}

read_http_line :: (connection_fd: s32) -> string {
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
  assert(bytes_read == size_of(u8), "failed reading line");

  if bytes.count == 2 {
    return "";
  }

  result: string;
  result.count = bytes.count - 2;
  result.data = bytes.data;
  return result;
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
    assert(bytes_remaining > 0);

    to_read := size_of(u8) * cast(u64)bytes_remaining;
    bytes_read += read(connection_fd, http_body_bytes.data + bytes_read, to_read);
  }

  body: string;
  body.count = http_body_bytes.count;
  body.data = http_body_bytes.data;
  return body, true;
}
