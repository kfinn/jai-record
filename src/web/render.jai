HttpRepsonseHeaders :: struct {
  status: HttpResponseStatus;
  headers: HttpHeaders;
}

DEFAULT_RESPONSE_HEADERS :: HttpHeader.[
  .{"Content-Type", "application/json"},
  .{"Access-Control-Allow-Origin", "http://localhost:3000"}
];

render_status :: (using http_request: *HttpRequest, status: HttpResponseStatus) {
  assert(response_status == .UNINITIALIZED, "attempted to write response status more than once");

  response_status = status;
  write(connection_fd, "HTTP/1.1 200 OK\r\n");
}

render_headers :: (using http_request: *HttpRequest, override_headers: HttpHeaders) {
  assert(response_status != .UNINITIALIZED, "attempted to write response headers before writing response status");
  assert(!has_repsonse_headers, "attempted to write response headers more than once");

  has_repsonse_headers = true;
  for default_header: DEFAULT_RESPONSE_HEADERS {
    for override_header: override_headers {
      if override_header.key == default_header.key continue;
    }
    write(connection_fd, "%: %\r\n", default_header.key, default_header.value);
  }
  for override_header: override_headers {
    write(connection_fd, "%: %\r\n", override_header.key, override_header.value);
  }
  write(connection_fd, "\r\n");
}

render_error:: (
  using http_request: *HttpRequest,
  status: HttpResponseStatus
) {
  if #complete status == {
    case .UNINITIALIZED; #through;
    case .OK; #through;
    case .CREATED; #through;
    case .NO_CONTENT;
      render_error(http_request, .INTERNAL_SERVER_ERROR);
    case .NOT_FOUND;
      render_status(http_request, status);
      render_headers(http_request, .[.{"Content-Type", "text/plain"}]);
      write(http_request.connection_fd, "Not Found");
    case .UNPROCESSABLE_ENTITY;
      render_status(http_request, status);
      render_headers(http_request, .[.{"Content-Type", "text/plain"}]);
      write(http_request.connection_fd, "Unprocessable Entity");
    case .INTERNAL_SERVER_ERROR;
      render_status(http_request, status);
      render_headers(http_request, .[.{"Content-Type", "text/plain"}]);
      write(http_request.connection_fd, "Internal Server Error");
  }
}

render_json :: (
  using http_request: *HttpRequest,
  it: $T,
  $children: Code,
  status: HttpResponseStatus = .OK,
  override_headers: HttpHeaders = .[]
) {
  render_status(http_request, status);
  render_headers(http_request, override_headers);

  json_object :: ($name: string, it: $T, $children: Code) #expand {
    if `needs_comma_before_next_field write(connection_fd, ",");
    #insert #run sprint("% := it;\n", name);
    needs_comma_before_next_field := false;
    write(connection_fd, "\"%\":{", json_escape(name));
    #insert_internal children;
    write(connection_fd, "}");
    `needs_comma_before_next_field = true;
  }

  json_array :: (name: string, values: []$T, $children: Code) #expand {
    if `needs_comma_before_next_field write(connection_fd, ",");
    write(connection_fd, "\"%\":[", json_escape(name));
    for values {
      write(connection_fd, "{");
      needs_comma_before_next_field := false;
      #insert_internal children;
      write(connection_fd, "}");
      if it_index < values.count - 1 write(connection_fd, ",");
    }
    write(connection_fd, "]");
    `needs_comma_before_next_field = true;
  }

  json_fields :: (value: $T, $fields: ..string) #expand { 
    #insert #run () -> string {
      string_builder: String_Builder;
      defer free_buffers(*string_builder);

      for fields {
        print_to_builder(
          *string_builder,
          "if `needs_comma_before_next_field write(connection_fd, \",\");\n"
        );
        print_to_builder(
          *string_builder,
          "write(connection_fd, \"\\\"%\\\":%%\", encode_json_value(value.%));\n",
          it,
          it
        );
        print_to_builder(*string_builder, "`needs_comma_before_next_field = true;\n");
      }

      return builder_to_string(*string_builder);
    }();
  }

  write(connection_fd, "{");
  needs_comma_before_next_field := false;
  #insert_internal children;
  write(connection_fd, "}");
}

json_escape :: (to_escape: string) -> string {
  return replace(replace(to_escape, "\\", "\\\\"), "\"", "\\\"");
}

encode_json_value :: (value: string) -> string {
  return sprint("\"%\"", json_escape(value));
}

encode_json_value :: (value: *$T) -> string {
  if value == null {
    return "null";
  } else {
    return encode_json_value(<<value);
  }
}

encode_json_value :: (value: $T) -> string #modify {
  if T.type == .POINTER {
    T = null;
  }
} {
  return sprint("%", value);
}
