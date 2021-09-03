draw_routes :: ($routes: Type) -> HttpServer.RequestHandler {
  request_handler_inner :: (http_request: *HttpRequest) -> success: bool {
    path_components := split(http_request.path, "/");
    path_components.count -= 1;
    path_components.data += 1;
    if path_components.count == 0 return false;

    #insert #run () -> string {
      string_builder: String_Builder;
      defer free_buffers(*string_builder);

      draw_nested_routes_to_builder(*string_builder, type_info(routes), 0, .[]);

      return builder_to_string(*string_builder);
    }();
    
    return false;
  };

  request_handler :: (http_request: *HttpRequest) -> success: bool {
    if request_handler_inner(http_request) {
      close(http_request.connection_fd);
      return true;
    }
    return false;
  }

  return request_handler;
}

parse_path_components :: (path: string) -> []string {
  all_path_components := split(path, "/");
  return slice(all_path_components, 1, all_path_components.count - 1);
}

#scope_file

RouteComponent :: struct {
  name: string;
  id_path_component_index: int;
}

draw_nested_routes_to_builder :: (string_builder: *String_Builder, routes_type_info_struct: *Type_Info_Struct, path_component_start_index: int, ancestors: []RouteComponent) {
  print_to_builder(string_builder, "if path_components[%] == {\n", path_component_start_index);

  for member: routes_type_info_struct.members {
    route_type_info_struct := get_constant_member_type_info_struct_value(routes_type_info_struct, member);
    controller_member, has_controller_member := find_member(route_type_info_struct, "controller");
    assert(has_controller_member);
    controller_type_info_struct := get_constant_member_type_info_struct_value(route_type_info_struct, controller_member);
    assert(controller_type_info_struct != null);

    qualified_controller_name_builder: String_Builder;
    defer free_buffers(*qualified_controller_name_builder);

    print_to_builder(*qualified_controller_name_builder, "routes.");
    for ancestors {
      print_to_builder(*qualified_controller_name_builder, "%.children.", it.name);
    }
    print_to_builder(*qualified_controller_name_builder, "%.controller", member.name);
    qualified_controller_name := builder_to_string(*qualified_controller_name_builder);

    print_to_builder(string_builder, "  case \"%\";\n", member.name);
    has_index_member := has_member(controller_type_info_struct, "index");
    if has_index_member {
      print_to_builder(string_builder, "    if path_components.count == % {\n", path_component_start_index + 1);
      print_to_builder(string_builder, "      if #complete http_request.method == {\n");
      print_to_builder(string_builder, "        case .GET;\n");
      print_to_builder(string_builder, "          %.index(http_request", qualified_controller_name);
      for ancestors {
        print_to_builder(string_builder, ", path_components[%]", it.id_path_component_index);
      }
      print_to_builder(string_builder, ");\n");
      print_to_builder(string_builder, "          return true;\n");
      print_to_builder(string_builder, "        case .PATCH;\n");
      print_to_builder(string_builder, "          return false;\n");
      print_to_builder(string_builder, "      }\n");
      print_to_builder(string_builder, "    }\n");
    }

    has_show_member := has_member(controller_type_info_struct, "show");
    has_update_member := has_member(controller_type_info_struct, "update");
    if has_show_member || has_update_member {
      print_to_builder(string_builder, "    if path_components.count == % {\n", path_component_start_index + 2);
      print_to_builder(string_builder, "      if #complete http_request.method == {\n");
      print_to_builder(string_builder, "        case .GET;\n");
      if has_show_member {
        print_to_builder(string_builder, "          %.show(http_request", qualified_controller_name);
        for ancestors {
          print_to_builder(string_builder, ", path_components[%]", it.id_path_component_index);
        }
        print_to_builder(string_builder, ", path_components[%]);\n", path_component_start_index + 1);
        print_to_builder(string_builder, "          return true;\n");
      } else {
        print_to_builder(string_builder, "          return false;\n");
      }
      print_to_builder(string_builder, "        case .PATCH;\n");
      if has_update_member {
        print_to_builder(string_builder, "          %.update(http_request", qualified_controller_name);
        for ancestors {
          print_to_builder(string_builder, ", path_components[%]", it.id_path_component_index);
        }
        print_to_builder(string_builder, ", path_components[%]);\n", path_component_start_index + 1);
        print_to_builder(string_builder, "          return true;\n");
      } else {
        print_to_builder(string_builder, "          return false;\n");
      }
      print_to_builder(string_builder, "      }\n");
      print_to_builder(string_builder, "    }\n");
    }

    children_member, has_children_member := find_member(route_type_info_struct, "children");
    if has_children_member {
      nested_path_component_start_index := path_component_start_index + 2;

      nested_ancestors := NewArray(ancestors.count + 1, RouteComponent);
      defer array_free(nested_ancestors);

      for ancestors {
        nested_ancestors[it_index] = it;
      }
      nested_ancestors[ancestors.count].name = member.name;
      nested_ancestors[ancestors.count].id_path_component_index = path_component_start_index + 1;

      draw_nested_routes_to_builder(
        string_builder,
        get_constant_member_type_info_struct_value(route_type_info_struct, children_member),
        nested_path_component_start_index,
        nested_ancestors
      );
    }
  }
  print_to_builder(string_builder, "}\n");
}
