UsersController :: struct {
  index :: (connection_fd: s32) {
    response_builder: String_Builder;
    defer free_buffers(*response_builder);

    print_to_builder(*response_builder, "users:\n\n");

    users := preload(
      UserHasManyTodos,
      UsersRepo.all()
    );
    for user: users {
      print_to_builder(*response_builder, "user[%]: %\n", user.id, user.email);
      for todo: user.todos {
        print_to_builder(*response_builder, "  todo: %\n", todo.description);
      }
    }

    response_body := builder_to_string(*response_builder);
    response := sprint("Status: 200 OK\r\nContent-Type: text/plain\r\n\r\n%", response_body);
    bytes_written := write(connection_fd, response);
    assert(bytes_written == response.count);
  }

  show :: (connection_fd :s32, user_id: string) {
    user := UsersRepo.find(user_id);

    response_builder: String_Builder;
    defer free_buffers(*response_builder);

    print_to_builder(*response_builder, "user: %\n", user.email);

    with_user: SqlWhere("user_id = ?", 1);
    with_user.args[0] = user.id;
    for todo: TodosRepo.all(*with_user) {
      print_to_builder(*response_builder, "  todo: %\n", todo.description);
    }

    response_body := builder_to_string(*response_builder);
    response := sprint("Status: 200 OK\r\nContent-Type: text/plain\r\n\r\n%", response_body);
    bytes_written := write(connection_fd, response);
    assert(bytes_written == response.count);
  }
}
