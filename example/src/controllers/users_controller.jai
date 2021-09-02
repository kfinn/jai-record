UsersController :: struct {
  index :: (request: HttpRequest) {
    response_builder: String_Builder;
    defer free_buffers(*response_builder);

    print_to_builder(*response_builder, "users:\n\n");

    users := UsersRepo.all();
    
    write(
      request.connection_fd,
      "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: http://localhost:3000\r\n\r\n"
    );
    users_index_json_view(request.connection_fd, users);
  }

  show :: (request: HttpRequest, user_id: string) {
    user := UsersRepo.find(user_id);

    response_builder: String_Builder;
    defer free_buffers(*response_builder);

    print_to_builder(*response_builder, "user: %\n", user.email);

    with_user: SqlWhere("user_id = :id", struct { id: int; });
    with_user.id = user.id;
    for todo: TodosRepo.where(with_user) {
      print_to_builder(*response_builder, "  todo[%]: %\n", todo.id, todo.description);
    }

    response_body := builder_to_string(*response_builder);
    response := sprint("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n%", response_body);
    bytes_written := write(request.connection_fd, response);
    assert(bytes_written == response.count);
  }
}
