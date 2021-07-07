HOST :: "0.0.0.0";
PORT :: 7000;

CONTENT_LENGTH_HEADER_KEY :: "CONTENT_LENGTH";
SCGI_HEADER_KEY :: "SCGI";
SCGI_HEADER_VALUE :: "1";

scgi_server_run :: () {
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
    connection := accept(fd);
    handle(connection);
  }
}

handle :: (connection: s32) {
  defer close(connection);

  headers_string, parse_headers_netstring_success := next_netstring(connection);
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

  body, parse_body_netstring_success := next_netstring_interpretation(connection, content_size);
  if !parse_body_netstring_success {
    return;
  }

  response := "Status: 200 OK\r\nContent-Type: text/plain\r\n\r\n42";
  bytes_written := write(connection, response);
}

next_netstring :: (connection: s32) -> []u8, success: bool {
  next_byte: u8;
  bytes_read := read(connection, *next_byte, size_of(u8));
  netstring_size_bytes: [..]u8;
  defer array_reset(*netstring_size_bytes);

  while bytes_read > 0 {
    if next_byte == #char ":" break;
    array_add(*netstring_size_bytes, next_byte);
    bytes_read = read(connection, *next_byte, size_of(u8));
  }
  if bytes_read == 0 return .[], false;

  headers_size_string: string;
  headers_size_string.count = netstring_size_bytes.count;
  headers_size_string.data = netstring_size_bytes.data;
  headers_size, parse_headers_size_success := parse_int(*headers_size_string);
  if !parse_headers_size_success return .[], false;

  result, next_interpretation_success := next_netstring_interpretation(connection, headers_size);
  if !next_interpretation_success {
    return .[], false;
  }
  return result, true;
}

next_netstring_interpretation :: (connection: s32, count: int) -> []u8, success: bool {
  if count == 0 return .[], true;

  result: [..]u8;

  next_byte: u8;
  bytes_read := read(connection, *next_byte, size_of(u8));
  netstring_interpretation_total_bytes_read := bytes_read;
  while bytes_read > 0 && netstring_interpretation_total_bytes_read <= count {
    array_add(*result, next_byte);
    bytes_read = read(connection, *next_byte, size_of(u8));
    netstring_interpretation_total_bytes_read += bytes_read;
  }

  if bytes_read != 1 return .[], false;
  if next_byte != #char "," return .[], false;
  
  return result, true;
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
