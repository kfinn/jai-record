prepare_sql_placeholders_for_args :: (expression: string) -> string {
  string_builder: String_Builder;
  defer free_buffers(*string_builder);

  next_placeholder_index := 1;
  PLACEHOLDER :: #char "?";
  for character_index: 0..(expression.count - 1) {
    character := expression[character_index];
    if character == PLACEHOLDER {
      print_to_builder(*string_builder, "$%", next_placeholder_index);
      next_placeholder_index = next_placeholder_index + 1;
    } else {
      single_character_string := sprint("_");
      single_character_string.data[0] = character;
      print_to_builder(*string_builder, "%", single_character_string);
    }
  }

  return builder_to_string(*string_builder);
}
