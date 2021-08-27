#insert #run () -> string {
  print("about to call draw_routes\n");

  result := draw_routes(#code {
    websocket_connection("blah", "base_handle_message");

    resources("users", UsersController, #code{
      resources("tags", UserTagsController);
    });
    resources("todos", TodosController);
  });

  print("routes:\n\n%\n\n", result);

  return result;
}();
