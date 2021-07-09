#insert #run draw_routes(#code {
  resources("users", UsersController, #code{
    resources("tags", UserTagsController);
  });
  resources("todos", TodosController);
});
