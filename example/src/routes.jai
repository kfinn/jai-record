UserTagsRoute :: struct {
  controller :: UserTagsController;
}

TodosRoute :: struct {
  controller :: TodosController;
}

UsersRouteChildren :: struct {
  tags :: UserTagsRoute;
}

UsersRoute :: struct {
  controller :: UsersController;
  children :: UsersRouteChildren;
}

Routes :: struct {
  users :: UsersRoute;
  todos :: TodosRoute;
}

route_request :: #run well_bound_draw_routes(Routes);
