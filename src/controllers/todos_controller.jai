TodosController :: struct {
  index :: () -> string {
    response_builder: String_Builder;
    defer free_buffers(*response_builder);

    print_to_builder(*response_builder, "todos:\n");

    todos := TodosRepo.all();
    for todos {
      print_to_builder(*response_builder, "todo: %\n", it.description);
    }

    return builder_to_string(*response_builder);
  }
}; @Resource(/todos)

UsersController :: struct {
  index :: () -> string {
    response_builder: String_Builder;
    defer free_buffers(*response_builder);

    print_to_builder(*response_builder, "users:\n\n");

    users := preload(
      UserHasManyTodos,
      UsersRepo.all()
    );
    for user: users {
      print_to_builder(*response_builder, "user: %\n", user.email);
      for todo: user.todos {
        print_to_builder(*response_builder, "  todo: %\n", todo.description);
      }
    }

    return builder_to_string(*response_builder);
  }
}; @Resource(/users)
