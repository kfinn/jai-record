parse_json_params :: ($Result: Type, json: string) -> success: bool, result: Result, meta: StructParseMeta(Result) {
  json_value, parse_json_value_success := parse_json_value(json);
  if !parse_json_value_success return false, .{}, .{};
  
  success, result, meta := parse_json_params_from_json_value(Result, json_value);
  return success, result, meta;
}

parse_json_params_from_json_value :: ($Result: Type, json_value: JsonValue) -> success: bool, result: Result, meta: StructParseMeta(Result) {
  if json_value.kind != .OBJECT return false, .{}, .{};

  result: Result;
  meta: StructParseMeta(Result);

  for field: json_value.object_value {
    #insert #run () -> string {
      string_builder: String_Builder;
      defer free_buffers(*string_builder);

      result_type_info := type_info(Result);
      assert(result_type_info.type == .STRUCT);
      result_type_info_struct := cast(*Type_Info_Struct)result_type_info;

    print_to_builder(*string_builder, "if field.key == {\n");
      for member: result_type_info_struct.members {
        if should_skip(member) continue;

        print_to_builder(*string_builder, "  case \"%\";\n", member.name);
        print_to_builder(
          *string_builder,
          "    meta.% = %(*result.%, field.value);\n",
          member.name,
          setter_name_for_member_type(member.type),
          member.name
        );
      }
      print_to_builder(*string_builder, "}\n");
      return builder_to_string(*string_builder);
    }();
  }

  return true, result, meta;
}

operator [] :: (array_of_structs_parse_meta: $T/ArrayOfStructsParseMeta, index: int) -> T.ChildType {
  return array_of_structs_parse_meta.children[index];
}


#scope_file

StructParseMeta :: struct($T: Type) {
  #insert #run () -> string {
    info := type_info(T);
    assert(info.type == .STRUCT);
    type_info_struct := cast(*Type_Info_Struct)info;

    builder: String_Builder;
    defer free_buffers(*builder);
    
    for member: type_info_struct.members {
      if should_skip(member) continue;

      if member.type.type == {
        case .ARRAY;
          array_type_info := cast(*Type_Info_Array)member.type;
          if array_type_info.element_type.type == .STRUCT {
            struct_type_info := cast(*Type_Info_Struct)array_type_info.element_type;
            print_to_builder(*builder, "%: ArrayOfStructsParseMeta(type_of(T.%));\n", member.name, member.name);
          } else {
            print_to_builder(*builder, "%: ScalarParseMeta;\n", member.name);
          }
        case .STRUCT;
          struct_type_info := cast(*Type_Info_Struct)member.type;
          print_to_builder(*builder, "%: StructParseMeta(type_of(T.%));\n", member.name, member.name);
        case;
          print_to_builder(*builder, "%: ScalarParseMeta;\n", member.name);
      }
    }

    return builder_to_string(*builder);
  }();
}

ScalarParseMeta :: struct {
  is_set: bool;
}

ArrayOfStructsParseMeta :: struct($T: Type) {
  ElementType :: #run array_element_type(T);
  ChildType :: StructParseMeta(ElementType);

  is_set: bool;
  children: []ChildType;
}

array_element_type :: ($ArrayType: Type) -> Type {
  type_info_array := type_info(ArrayType);

  converter: union {
    type_info_pointer: *Type_Info;
    type: Type;
  }
  converter.type_info_pointer = type_info_array.element_type;

  return converter.type;
}

should_skip :: (member: Type_Info_Struct_Member) -> bool {
    if member.flags & (member.flags.CONSTANT | member.flags.IMPORTED) return true;
    return false;
}

setter_name_for_member_type :: (member_type: *Type_Info) -> string {
  if member_type.type == {
    case .INTEGER;
      return "set_integer_result_value";
    case .STRING;
      return "set_string_result_value";
    case .ARRAY;
      type_info_array := cast(*Type_Info_Array)member_type;
      if type_info_array.element_type.type == .STRUCT {
        return "set_array_of_structs_result_value";
      } else {
        return "set_array_of_scalars_result_value";
      }
    case .STRUCT;
      return "set_struct_result_value";
  }
  assert(false);
  return "";
}

set_integer_result_value :: (destination: *$T, json_value: JsonValue) -> ScalarParseMeta {
  assert(json_value.kind == .NUMBER);
  parsed_int, parse_success := parse_int(*json_value.number_value, T);
  assert(parse_success);
  <<destination = parsed_int;
  return .{true};
}

set_string_result_value :: (destination: *string, json_value: JsonValue) -> ScalarParseMeta {
  assert(json_value.kind == .STRING);
  <<destination = json_value.string_value;
  return .{true};
}

set_array_of_scalars_result_value :: (destination: *[]$T, json_value: JsonValue) -> ScalarParseMeta {
  assert(json_value.kind == .ARRAY);

  result: [..]T;
  for element_json_value: json_value.array_value {
    element_value: T;
    #insert #run () -> string {
      destination_type_info := type_info(T);
      return sprint(
        "%(*element_value, element_json_value);\n",
        setter_name_for_member_type(destination_type_info)
      );
    }();
    array_add(*result, element_value);
  }
  <<destination = result;
  return .{true};
}

set_struct_result_value :: (destination: *$T, json_value: JsonValue) -> StructParseMeta(T) {
  success, result, meta := parse_json_params_from_json_value(T, json_value);
  assert(success);
  <<destination = result;
  return meta;
}

set_array_of_structs_result_value :: (destination: *$T, json_value: JsonValue) -> ArrayOfStructsParseMeta(T) {
  assert(json_value.kind == .ARRAY);  

  meta: ArrayOfStructsParseMeta(T);
  meta.is_set = true;

  result: [..]meta.ElementType;
  element_metas: [..]meta.ChildType;

  for element_json_value: json_value.array_value {
    success, element, meta := parse_json_params_from_json_value(meta.ElementType, element_json_value);
    array_add(*result, element);
    array_add(*element_metas, meta);
  }

  <<destination = result;
  meta.children = element_metas;

  return meta;
}
