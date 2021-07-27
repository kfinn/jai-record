render_json :: (connection_fd: s32, it: $T, $children: Code) {
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

encode_json_value :: (value: $T) -> string {
  return sprint("%", value);
}
