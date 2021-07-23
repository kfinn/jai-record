TodosController :: struct {
  index :: (request: ScgiRequest) {
    response_builder: String_Builder;
    defer free_buffers(*response_builder);

    print_to_builder(*response_builder, "todos:\n");

    todos := TodosRepo.all();
    for todos {
      print_to_builder(*response_builder, "todo: %\n", it.description);
    }

    response_body := builder_to_string(*response_builder);
    response := sprint("Status: 200 OK\r\nContent-Type: text/plain\r\n\r\n%", response_body);
    bytes_written := write(request.connection_fd, response);
    assert(bytes_written == response.count);
  }

  show :: (request: ScgiRequest, todo_id: string) {
    todo := TodosRepo.find(todo_id);
    if (!todo) {
      response := sprint("Status: 404 Not Found\r\nContent-Type: text/plan\r\n\r\nNot Found");
      bytes_written := write(request.connection_fd, response);
      assert(bytes_written == response.count);
      return;
    }

    response_builder: String_Builder;
    defer free_buffers(*response_builder);

    print_to_builder(*response_builder, "todo:\n");
    print_to_builder(*response_builder, "%\n", todo.description);
    if todo.completed_at {
      print_to_builder(*response_builder, "completed: %\n", <<todo.completed_at);
    } else {
      print_to_builder(*response_builder, "not completed\n");
    }

    response_body := builder_to_string(*response_builder);
    response := sprint("Status: 200 OK\r\nContent-Type: text/plain\r\n\r\n%", response_body);
    bytes_written := write(request.connection_fd, response);
    assert(bytes_written == response.count);
  }

  PatchParams :: struct {
    completed_at: string;
  }

  update :: (request: ScgiRequest, todo_id: string) {
    Params :: struct {
      todo: struct {
        completed_at: string;
      }
    }
    json_parse_success, params, params_meta := parse_json_params(Params, request.body);
    if !json_parse_success {
      response := sprint("Status: 422 Unprocessable Entity\r\nContent-Type: text/plan\r\n\r\nUnprocessable Entity");
      bytes_written := write(request.connection_fd, response);
      assert(bytes_written == response.count);
      return;
    }

    todo := TodosRepo.find(todo_id);
    if (!todo) {
      response := sprint("Status: 404 Not Found\r\nContent-Type: text/plan\r\n\r\nNot Found");
      bytes_written := write(request.connection_fd, response);
      assert(bytes_written == response.count);
      return;
    }

    if params_meta.todo.completed_at.is_set {
      if params.todo.completed_at {
        todo.completed_at = *params.todo.completed_at;
      } else {
        todo.completed_at = null;
      }
    }

    if TodosRepo.save(todo) {
      response :: "Status: 200 OK\r\n\r\n";
      bytes_written := write(request.connection_fd, response);
      assert(bytes_written == response.count);
    } else {
      response :: "Status: 422 Unprocessable Entity\r\n\r\n";
      bytes_written := write(request.connection_fd, response);
      assert(bytes_written == response.count);
    }
  }
}
