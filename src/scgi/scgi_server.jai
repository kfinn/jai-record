HOST :: 0;
PORT :: 7000;

REQUEST_URI_HEADER_KEY :: "REQUEST_URI";
REQUEST_METHOD_HEADER_KEY :: "REQUEST_METHOD";
REQUEST_METHOD_GET :: "GET";
REQUEST_METHOD_PATCH :: "PATCH";

CONTENT_LENGTH_HEADER_KEY :: "CONTENT_LENGTH";
SCGI_HEADER_KEY :: "SCGI";
SCGI_HEADER_VALUE :: "1";

ScgiRequest :: struct {
  headers: Table(string, string);
  body: string;
  connection_fd: s32;
}

scgi_server_run :: (handle: (connection_fd: s32) -> () = default_handle) {
  fd := socket(AF_INET, SOCK_STREAM, 0);
  defer close(fd);

  reuseaddr_value: s32 = 1;
  setsockopt_status := setsockopt(fd, SOL_SOCKET, SO_REUSEADDR, *reuseaddr_value, size_of(s32));

  bind_status := bind(fd, HOST, PORT);
  assert(bind_status == 0, "Unable to to bind socket to port. Is the socket in use? Status: %", bind_status);

  listen_status := listen(fd, 40);
  assert(listen_status == 0, "Unable to listen to socket. Status: %", listen_status);

  print("scgi_server awaiting connections\n");
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
  defer close(connection_fd);

  headers_string, parse_headers_netstring_success := next_netstring(connection_fd);
  if !parse_headers_netstring_success {
    return;
  }

  headers, parse_headers_success := parse_headers(headers_string);
  if !parse_headers_success {
    return;
  }

  content_size_string_pointer := table_find_pointer(headers, CONTENT_LENGTH_HEADER_KEY);
  content_size, parse_content_size_success := parse_int(content_size_string_pointer);
  if !parse_content_size_success {
    return;
  }

  body_bytes := NewArray(content_size, u8, initialized=false);
  body_bytes_read := read(connection_fd, body_bytes.data, cast(u64)content_size * size_of(u8));
  if body_bytes_read != content_size {
    return;
  }
  body: string;
  body.count = body_bytes.count;
  body.data = body_bytes.data;

  request_uri, request_uri_present := table_find(headers, "REQUEST_URI");

  request: ScgiRequest;
  request.headers = headers;
  request.body = body;
  request.connection_fd = connection_fd;
  handled := handle_request_with_resources(request);

  if !handled {
    response := "Status: 404 Not Found\r\nContent-Type: text/plain\r\n\r\nNot Found";
    bytes_written := write(connection_fd, response);
    assert(bytes_written == response.count);
  }
}

next_netstring :: (connection_fd: s32) -> []u8, success: bool {
  next_byte: u8;
  netstring_length_bytes_read := read(connection_fd, *next_byte, size_of(u8));

  netstring_length_bytes: [..]u8;
  defer array_reset(*netstring_length_bytes);

  while netstring_length_bytes_read > 0 {
    if next_byte == #char ":" break;
    array_add(*netstring_length_bytes, next_byte);
    netstring_length_bytes_read = read(connection_fd, *next_byte, size_of(u8));
  }
  if netstring_length_bytes_read == 0 return .[], false;

  netstring_length_string: string;
  netstring_length_string.count = netstring_length_bytes.count;
  netstring_length_string.data = netstring_length_bytes.data;
  netstring_length, parse_netstring_length_success := parse_int(*netstring_length_string);
  if !parse_netstring_length_success return .[], false;

  netstring_interpretation := NewArray(netstring_length, u8, initialized=false);
  netstring_interpretation_bytes_read := read(
    connection_fd,
    netstring_interpretation.data,
    size_of(u8) * cast(u64)netstring_length
  );
  if netstring_interpretation_bytes_read != netstring_length return .[], false;

  trailing_comma_byte: u8;
  trailing_comma_bytes_read := read(connection_fd, *trailing_comma_byte, size_of(u8));
  if trailing_comma_bytes_read != 1 || trailing_comma_byte != #char "," return .[] ,false;

  return netstring_interpretation, true;
}

parse_headers :: (headers_netstring: []u8) -> Table(string, string), success: bool {
  State :: enum {
    PARSING_KEY;
    PARSING_VALUE;
  }

  result: Table(string, string);

  current_state := State.PARSING_KEY;

  key_bytes: [..]u8;
  defer array_reset(*key_bytes);
  value_bytes: [..]u8;
  defer array_reset(*value_bytes);

  has_parsed_content_length := false;

  for byte: headers_netstring {
    byte_as_string: string;
    byte_as_string.count = 1;
    byte_as_string.data = *byte;
    if byte == 0 {
      if current_state == .PARSING_VALUE {
        key: string;
        key.count = key_bytes.count;
        key.data = key_bytes.data;

        value: string;
        value.count = value_bytes.count;
        value.data = value_bytes.data;

        if !has_parsed_content_length && key != CONTENT_LENGTH_HEADER_KEY {
          uninit(*result);
          return Table(string, string).{}, false;
        } else {
          has_parsed_content_length = true;
        }

        if table_find_pointer(result, key) != null {
          uninit(*result);
          return Table(string, string).{}, false;
        }

        table_set(*result, copy_string(key), copy_string(value));

        array_reset(*key_bytes);
        array_reset(*value_bytes);

        current_state = .PARSING_KEY;
      } else {
        current_state = .PARSING_VALUE;
      }
    } else {
      if current_state == .PARSING_KEY {
        array_add(*key_bytes, byte);
      } else {
        array_add(*value_bytes, byte);
      }
    }
  }

  scgi_header_value := table_find_pointer(result, SCGI_HEADER_KEY);
  if !scgi_header_value || <<scgi_header_value != SCGI_HEADER_VALUE {
    uninit(*result);
    return Table(string, string).{}, false;
  }

  return result, true;
}
