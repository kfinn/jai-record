TodosRoute :: struct {
  controller :: TodosController;
}

UsersRoute :: struct {
  controller :: UsersController;
}

Routes :: struct {
  users :: UsersRoute;
  todos : TodosRoute
}

route_request :: #run well_bound_draw_routes(Routes);

// route_request :: #run well_bound_draw_routes(struct {
//   users :: struct {
//     controller :: UsersController;
//   };
// });


// #run draw_routes(#code {
//   websocket_connection("blah", "base_handle_message");

//   resources("users", UsersController, #code{
//     resources("tags", UserTagsController);
//   });
//   resources("todos", TodosController);
// });
