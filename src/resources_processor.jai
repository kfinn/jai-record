Resource :: struct {
  path: string;
  controller_declaration: *Code_Declaration;
}

ResourcesProcessor :: struct {
  resources: [..]Resource;
  workspace: Workspace;
  has_generated_routes: bool;
}

handle_message :: (
  using resources_processor: *ResourcesProcessor,
  message: *Message
) {
  if message.workspace != workspace return;

  if message.kind == .TYPECHECKED {
    typechecked_message := cast(*Message_Typechecked) message;
    for declaration: typechecked_message.declarations {
      resource_path, has_resource_note := match_note("Resource(", ")", declaration);
      if has_resource_note {
        resource: Resource;
        resource.path = resource_path;
        resource.controller_declaration = declaration;
        array_add(*resources, resource);
      }
    }
  }
  if message.kind == .PHASE {
    phase := cast(*Message_Phase) message;
    if phase.phase == .TYPECHECKED_ALL_WE_CAN {
        if !has_generated_routes {
            generate_routes(resources_processor);
            has_generated_routes = true;
        }
    }
  }
}

generate_routes :: (using resources_processor: *ResourcesProcessor) {
  string_builder: String_Builder;
  defer free_buffers(*string_builder);

  print_to_builder(*string_builder, "handle_request_with_resources :: (path: string) -> string {\n");
  print_to_builder(*string_builder, "  if path == {\n");

  for resources {
    print_to_builder(*string_builder, "    case \"%\";\n", it.path);
    print_to_builder(*string_builder, "      return %.index();\n", it.controller_declaration.name);
  }

  print_to_builder(*string_builder, "  }\n");
  print_to_builder(*string_builder, "  return \"404\";\n");
  print_to_builder(*string_builder, "};\n");

  add_build_string(builder_to_string(*string_builder), workspace);
}
