RequestHandler :: #type (http_request: HttpRequest) -> success: bool;


well_bound_draw_routes :: ($routes: Type) -> RequestHandler {
  request_handler :: (http_request: HttpRequest) -> success: bool {
    path_components := split(http_request.path, "/");
    path_components.count -= 1;
    path_components.data += 1;
    if path_components.count == 0 return false;

    #insert #run () -> string {
      string_builder: String_Builder;
      defer free_buffers(*string_builder);

      print_to_builder(*string_builder, "if path_components[0] == {\n");

      routes_type_info := type_info(routes);
      assert(routes_type_info.type == .STRUCT);
      routes_type_info_struct := cast(*Type_Info_Struct)routes_type_info;

      for member: routes_type_info_struct.members {
        route_type_info_struct := get_constant_member_type_info_struct_value(routes_type_info_struct, member);
        controller_member, has_controller_member := find_member(route_type_info_struct, "controller");
        assert(has_controller_member);
        controller_type_info_struct := get_constant_member_type_info_struct_value(route_type_info_struct, controller_member);
        assert(controller_type_info_struct != null);

        print_to_builder(*string_builder, "  case \"%\";\n", member.name);
        has_index_member := has_member(controller_type_info_struct, "index");
        if has_index_member {
          print_to_builder(*string_builder, "    if path_components.count == 1 {\n");
          print_to_builder(*string_builder, "      if #complete http_request.method == {\n");
          print_to_builder(*string_builder, "        case .GET;\n");
          print_to_builder(*string_builder, "          routes.%.controller.index(http_request);\n", member.name);
          print_to_builder(*string_builder, "          return true;\n");
          print_to_builder(*string_builder, "        case .PATCH;\n");
          print_to_builder(*string_builder, "          return false;\n");
          print_to_builder(*string_builder, "      }\n");
          print_to_builder(*string_builder, "    }\n");
        }

        has_show_member := has_member(controller_type_info_struct, "show");
        has_update_member := has_member(controller_type_info_struct, "update");
        if has_show_member || has_update_member {
          print_to_builder(*string_builder, "    if path_components.count == 2 {\n");
          print_to_builder(*string_builder, "      if #complete http_request.method == {\n");
          print_to_builder(*string_builder, "        case .GET;\n");
          if has_show_member {
            print_to_builder(*string_builder, "          routes.%.controller.show(http_request, path_components[1]);\n", member.name);
            print_to_builder(*string_builder, "          return true;\n");
          } else {
            print_to_builder(*string_builder, "          return false;\n");
          }
          print_to_builder(*string_builder, "        case .PATCH;\n");
          if has_update_member {
            print_to_builder(*string_builder, "          routes.%.controller.update(http_request, path_components[1]);\n", member.name);
            print_to_builder(*string_builder, "          return true;\n");
          } else {
            print_to_builder(*string_builder, "          return false;\n");
          }
          print_to_builder(*string_builder, "      }\n");
          print_to_builder(*string_builder, "    }\n");
        }
      }
      print_to_builder(*string_builder, "}\n");

      return builder_to_string(*string_builder);

    }();
    return false;
  };

  return request_handler;
}

parse_path_components :: (path: string) -> []string {
  all_path_components := split(path, "/");
  return slice(all_path_components, 1, all_path_components.count - 1);
}
