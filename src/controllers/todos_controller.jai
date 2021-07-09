TodosController :: struct {
  index :: (connection_fd: s32) {
    response_builder: String_Builder;
    defer free_buffers(*response_builder);

    print_to_builder(*response_builder, "todos:\n");

    todos := TodosRepo.all();
    for todos {
      print_to_builder(*response_builder, "todo: %\n", it.description);
    }

    response_body := builder_to_string(*response_builder);
    response := sprint("Status: 200 OK\r\nContent-Type: text/plain\r\n\r\n%", response_body);
    bytes_written := write(connection_fd, response);
    assert(bytes_written == response.count);
  }
}
