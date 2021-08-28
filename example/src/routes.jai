#run draw_routes(#code {
  websocket_connection("blah", "base_handle_message");

  resources("users", UsersController, #code{
    resources("tags", UserTagsController);
  });
  resources("todos", TodosController);
});
