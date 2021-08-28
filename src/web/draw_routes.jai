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

compile_http_routes :: (route_patterns: []string, compiled_routes: []Regexp) {
  for route_patterns {
    regexp, success := compile(it);
    assert(success, "invalid route pattern: %", it);
    compiled_routes[it_index] = regexp;
  }
}

Route :: struct {
  Kind :: enum {
    COLLECTION;
    SINGLETON;
  }

  name: string;
  controller: Type;
  kind: Kind = .COLLECTION;
}

draw_routes :: ($block: Code) -> string #expand {
  parent_route_components :: RouteComponent.[];

  route_patterns: [..]string;

  routes_builder: String_Builder;
  defer free_buffers(*routes_builder);

  resources :: ($name: string, $controller: Type, $block: Code = EMPTY_BLOCK) #expand {
    #run print("controller: %\n", controller);
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
      array_add(*route_patterns, sprint("\"%/?$\"", route_pattern_prefix));
      route_index := route_patterns.count - 1;

      print_to_builder(*`routes_builder, "  {\n");
      print_to_builder(*`routes_builder, "    index_pattern := COMPILED_ROUTES[%];\n", route_index);
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

      array_add(*route_patterns, sprint("\"%/?$\"", show_route_pattern));
      route_index := route_patterns.count - 1;

      print_to_builder(*`routes_builder, "  {\n");
      print_to_builder(*`routes_builder, "    show_pattern := COMPILED_ROUTES[%];\n", route_index);
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

      array_add(*route_patterns, sprint("\"%/?$\"", patch_route_pattern));
      route_index := route_patterns.count - 1;

      print_to_builder(*`routes_builder, "  {\n");
      print_to_builder(*`routes_builder, "    patch_pattern := COMPILED_ROUTES[%];\n", route_index);
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

    print_to_builder(*`routes_builder, "  {\n");
    print_to_builder(*`routes_builder, "    if request_uri == \"/%\" && is_websocket_request(request) {\n", route);
    print_to_builder(*`routes_builder, "      handle_websocket_upgrade_request(request, %);\n", message_handler);
    print_to_builder(*`routes_builder, "      return true;\n");
    print_to_builder(*`routes_builder, "    }\n");
    print_to_builder(*`routes_builder, "  }\n");
  }

  print_to_builder(*routes_builder, "handle_request_with_resources :: (request: HttpRequest) -> bool {\n");
  print_to_builder(*routes_builder, "  request_uri := request.path;\n");
  print_to_builder(*routes_builder, "  request_method := request.method;\n");
  #insert_internal block;
  print_to_builder(*routes_builder, "  return false;\n");
  print_to_builder(*routes_builder, "}\n");

  print_to_builder(*routes_builder, "`COMPILED_ROUTES: [%]Regexp;\n", route_patterns.count);
  print_to_builder(*routes_builder, "`ROUTE_PATTERNS :: string.[\n");
  for route_patterns {
    print_to_builder(*routes_builder, "%", it);
    if it_index < route_patterns.count - 1 print_to_builder(*routes_builder, ",");
    print_to_builder(*routes_builder, "\n");
  }
  print_to_builder(*routes_builder, "];\n");

  return builder_to_string(*routes_builder);
}

is_websocket_request :: (request: HttpRequest) -> bool {
    websocket_upgrade_header: *HttpHeader;
    upgrade_header := find_header(request.headers, UPGRADE_HEADER_KEY);

    return upgrade_header && upgrade_header.value == UPGRADE_HEADER_WEBSOCKET_VALUE;
}
