TodosController :: struct {
  show :: (request: *HttpRequest, todo_id: string) {
    todo := TodosRepo.find(todo_id);
    if (!todo) {
      response := sprint("HTTP/1.1 404 Not Found\r\nContent-Type: text/plan\r\n\r\nNot Found");
      bytes_written := write(request.connection_fd, response);
      assert(bytes_written == response.count);
      return;
    }

    todos_to_preload: [1]Todo;
    todos_to_preload[0] = <<todo;

    preloaded_todos := preload(
      #run nested_preloader(
        TodoHasManyTaggings,
        TaggingBelongsToTag
      ),
      todos_to_preload
    );

    preloaded_todo := preloaded_todos[0];

    todos_show_json_view(request, preloaded_todo);
  }

  update :: (request: *HttpRequest, todo_id: string) {
    Params :: struct {
      todo: struct {
        completed_at: string;
      }
    }

    json_parse_success, params, params_meta := parse_json_params(Params, request.body);
    if !json_parse_success {
      render_error(request, .UNPROCESSABLE_ENTITY);
      return;
    }

    todo := TodosRepo.find(todo_id);
    if (!todo) {
      render_error(request, .NOT_FOUND);
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
      response :: "HTTP/1.1 200 OK\r\n\r\n";
      bytes_written := write(request.connection_fd, response);
      assert(bytes_written == response.count);
    } else {
      render_error(request, .UNPROCESSABLE_ENTITY);
    }
  }
}
