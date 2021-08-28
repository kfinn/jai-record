Route :: struct {
  Kind :: enum {
    COLLECTION;
    SINGLETON;
  }

  name: string;
  controller: Type;
  children: []Route;
  kind: Kind;
}

RouteWork :: struct {
  path_prefix_components: []string;
  route: *Route;
}

well_bound_draw_routes :: ($routes: []Route) -> (#type (http_request: HttpRequest) -> success: bool) {
  #assert routes.count > 0;

  #insert #run () -> string {
    string_builder: String_Builder;
    defer free_buffers(*string_builder);

    print_to_builder(*string_builder, "handle_request :: (http_request: HttpRequest) -> success: bool {\n");
    print_to_builder(*string_builder, "  path_components := split(http_request.path, \"/\");\n");

    remaining_route_works: [..]RouteWork;

    initial_route_work: RouteWork;
    initial_route_work.path_prefix_components = string.[];
    initial_route_work.route = *routes[0];
    array_add(*remaining_route_works, initial_route_work);

    while remaining_route_works {
      next_route_work := pop(*remaining_route_works);


      print_to_builder(*string_builder, "  if (\n");
      for path_prefix_component: next_route_work.path_prefix_components {

      }


      for * next_route_work.route.children {
        route_work: RouteWork;
        route_work.route = it;
        route_work.path_prefix_components = ???;

        array_add(*remaining_route_works, route_work);
      }
    }

    print_to_builder(*string_builder, "}\n");

    return builder_to_string(*string_builder);
  }();

  return handle_request;
}
