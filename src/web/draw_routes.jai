find_type_info_struct_member :: (type_info_struct: *Type_Info_Struct, member_name: string) -> *Type_Info_Struct_Member {
  for * type_info_struct.members {
    if it.name == member_name return it;
  }
  return null;
}

RouteComponent :: struct {
  RouteComponentKind :: enum {
    RESOURCE;
    RESOURCES;
  }

  kind: RouteComponentKind;
  name: string;
}

EMPTY_BLOCK :: #code {};


draw_routes :: ($block: Code) -> string {
  parent_route_components :: RouteComponent.[];
  routes_builder: String_Builder;
  defer free_buffers(*routes_builder);

  resources :: ($name: string, $controller: Type, $block: Code = EMPTY_BLOCK) #expand {
    controller_type_info := type_info(controller);

    route_pattern_prefix_builder: String_Builder;
    defer free_buffers(*route_pattern_prefix_builder);

    id_params_count := 0;

    print_to_builder(*route_pattern_prefix_builder, "^");
    for `parent_route_components {
      print_to_builder(*route_pattern_prefix_builder, "/%", it.name);
      if it.kind == .RESOURCES {
        print_to_builder(*route_pattern_prefix_builder, "/([^/]+)");
        id_params_count += 1;
      }
    }
    print_to_builder(*route_pattern_prefix_builder, "/%", name);
    route_pattern_prefix := builder_to_string(*route_pattern_prefix_builder);

    index_member := find_type_info_struct_member(controller_type_info, "index");
    if index_member {
      print_to_builder(*`routes_builder, "  {\n");
      print_to_builder(*`routes_builder, "    index_pattern, compile_pattern_success := compile(\"%/?$\");\n", route_pattern_prefix);
      print_to_builder(*`routes_builder, "    assert(compile_pattern_success, \"failed to compile route pattern\");\n");
      print_to_builder(*`routes_builder, "    matched, captures := match(request_uri, index_pattern);\n");
      print_to_builder(*`routes_builder, "    if matched && request_method == .GET {\n");
      print_to_builder(*`routes_builder, "      %.index(request", controller_type_info.name);
      for id_param_index: 1..id_params_count {
        print_to_builder(*`routes_builder, ", captures[%]", id_param_index);
      }
      print_to_builder(*`routes_builder, ");\n");
      print_to_builder(*`routes_builder, "      close(request.connection_fd);\n");
      print_to_builder(*`routes_builder, "      return true;\n");
      print_to_builder(*`routes_builder, "    }\n");
      print_to_builder(*`routes_builder, "  }\n");
    }

    show_member := find_type_info_struct_member(controller_type_info, "show");
    if show_member {
      show_route_pattern := sprint("%/([^/]+)$", route_pattern_prefix);
      show_id_params_count := id_params_count + 1;

      print_to_builder(*`routes_builder, "  {\n");
      print_to_builder(*`routes_builder, "    show_pattern, compile_pattern_success := compile(\"%/?$\");\n", show_route_pattern);
      print_to_builder(*`routes_builder, "    assert(compile_pattern_success, \"failed to compile route pattern\");\n");
      print_to_builder(*`routes_builder, "    matched, captures := match(request_uri, show_pattern);\n");
      print_to_builder(*`routes_builder, "    if matched && request_method == .GET {\n");
      print_to_builder(*`routes_builder, "      %.show(request", controller_type_info.name);
      for id_param_index: 1..show_id_params_count {
        print_to_builder(*`routes_builder, ", captures[%]", id_param_index);
      }
      print_to_builder(*`routes_builder, ");\n");
      print_to_builder(*`routes_builder, "      close(request.connection_fd);\n");
      print_to_builder(*`routes_builder, "      return true;\n");
      print_to_builder(*`routes_builder, "    }\n");
      print_to_builder(*`routes_builder, "  }\n");
    }

    update_member := find_type_info_struct_member(controller_type_info, "update");
    if update_member {
      patch_route_pattern := sprint("%/([^/]+)$", route_pattern_prefix);
      show_id_params_count := id_params_count + 1;

      print_to_builder(*`routes_builder, "  {\n");
      print_to_builder(*`routes_builder, "    patch_pattern, compile_pattern_success := compile(\"%/?$\");\n", patch_route_pattern);
      print_to_builder(*`routes_builder, "    assert(compile_pattern_success, \"failed to compile route pattern\");\n");
      print_to_builder(*`routes_builder, "    matched, captures := match(request_uri, patch_pattern);\n");
      print_to_builder(*`routes_builder, "    if matched && request_method == .PATCH {\n");
      print_to_builder(*`routes_builder, "      %.update(request", controller_type_info.name);
      for id_param_index: 1..show_id_params_count {
        print_to_builder(*`routes_builder, ", captures[%]", id_param_index);
      }
      print_to_builder(*`routes_builder, ");\n");
      print_to_builder(*`routes_builder, "      close(request.connection_fd);\n");
      print_to_builder(*`routes_builder, "      return true;\n");
      print_to_builder(*`routes_builder, "    }\n");
      print_to_builder(*`routes_builder, "  }\n");
    }

    if block != EMPTY_BLOCK {
      parent_route_components: [..]RouteComponent;
      defer array_free(parent_route_components);

      array_add(*parent_route_components, ..`parent_route_components);
      array_add(*parent_route_components, RouteComponent.{.RESOURCES, name});

      #insert_internal block;
    }
  }

  websocket_connection :: ($route: string, $message_handler: string) #expand {
    assert(`parent_route_components.count == 0);

    print_to_builder(*`routes_builder, "{\n");
    print_to_builder(*`routes_builder, "  if request_uri == \"/%\" && is_websocket_request(request) {\n", route);
    print_to_builder(*`routes_builder, "    handle_websocket_upgrade_request(request, %);\n", message_handler);
    print_to_builder(*`routes_builder, "    return true;\n");
    print_to_builder(*`routes_builder, "  }\n");
    print_to_builder(*`routes_builder, "}\n");
  }

  print_to_builder(*routes_builder, "handle_request_with_resources :: (request: HttpRequest) -> bool {\n");
  print_to_builder(*routes_builder, "  request_uri := request.path;\n");
  print_to_builder(*routes_builder, "  request_method := request.method;\n");
  #insert_internal block;
  print_to_builder(*routes_builder, "  return false;\n");
  print_to_builder(*routes_builder, "}\n");

  return builder_to_string(*routes_builder);
}

is_websocket_request :: (request: HttpRequest) -> bool {
    websocket_upgrade_header: *HttpHeader;
    upgrade_header := find_header(request.headers, UPGRADE_HEADER_KEY);

    return upgrade_header && upgrade_header.value == UPGRADE_HEADER_WEBSOCKET_VALUE;
}
