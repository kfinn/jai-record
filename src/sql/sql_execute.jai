prepare_sql_placeholders_for_args :: (expression: string, args: []Any) -> prepared_sql: string, prepared_args: []Any {
  string_builder: String_Builder;
  defer free_buffers(*string_builder);

  prepared_args: [..]Any;
  current_arg_index := 0;
  next_placeholder_index := 1;
  PLACEHOLDER :: #char "?";
  for character_index: 0..(expression.count - 1) {
    character := expression[character_index];
    if character == PLACEHOLDER {
      arg := args[current_arg_index];
      placeholder_args_count := 1;
      if arg.type.type == .ARRAY {
        arg_array: []Any = <<(cast(*[]Any)arg.value_pointer);
        placeholder_args_count = arg_array.count;
        if placeholder_args_count > 0 {
          for arg_array {
            array_add(*prepared_args, it);
          }
        } else {
          array_add(*prepared_args, null);
          placeholder_args_count = 1;
        }
      } else {
        array_add(*prepared_args, arg);
      }
      for 1..placeholder_args_count {
        print_to_builder(*string_builder, "$%", next_placeholder_index);
        if it < placeholder_args_count {
          print_to_builder(*string_builder, ", ");
        }
        next_placeholder_index = next_placeholder_index + 1;
      }
      current_arg_index += 1;
    } else {
      single_character_string := sprint("_");
      single_character_string.data[0] = character;
      print_to_builder(*string_builder, "%", single_character_string);
    }
  }

  return builder_to_string(*string_builder), prepared_args;
}
