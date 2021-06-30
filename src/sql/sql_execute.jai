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

prepare_sql_placeholders_for_args_test :: () {
  test_sql_with_placeholders := "id = ? AND another_thing = ? AND some_id = ?";

  assert_equals(
    "id = $1 AND another_thing = $2 AND some_id = $3",
    prepare_sql_placeholders_for_args(test_sql_with_placeholders)
  );
} @Test;

to_string :: (select: string, from: string, where: *SqlWhere) -> string {
  string_builder: String_Builder;
  defer free_buffers(*string_builder);

  print_to_builder(*string_builder, "SELECT % ", select);
  print_to_builder(*string_builder, "FROM % ", from);

  where_string := to_string(where);
  if where_string != "" {
    print_to_builder(
      *string_builder,
      "WHERE % ",
      prepare_sql_placeholders_for_args(where_string)
    );
  }

  return builder_to_string(*string_builder);
}
