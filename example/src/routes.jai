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

handle_http_request_with_routes :: #run draw_routes(Routes);

handle_http_request_with_websockets :: (http_request: *HttpRequest) -> success: bool {
  if http_request.path == "/ws" && is_websocket_request(<<http_request) {
    handle_websocket_upgrade_request(<<http_request, handle_websocket_message);
    return true;
  }
  return false;
};

handle_http_request :: (http_request: *HttpRequest) -> success: bool {
  if handle_http_request_with_routes(http_request) return true;
  if handle_http_request_with_websockets(http_request) return true;
  return false;
}
