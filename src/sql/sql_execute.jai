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

sql_select_execute :: ($Select: Type, sql_from: string, where: *SqlWhere) -> []Select.Record, success: bool {
  connection, jai_record_pg_connection_success := jai_record_pg_connection();
  if !jai_record_pg_connection_success return Select.Record.[], false;

  expression_string := to_string(Select.SQL_EXPRESSION, sql_from, where);

  args: []Any;
  if where != null args = where.args; 
  results, execute_success := execute(connection, Select.Record, expression_string, ..args);
  if !execute_success return Select.Record.[], false;
  return results, true;
}

sql_select_execute_test :: () {
  UserWithUppercaseEmail :: struct {
    user_id: int; @SqlExpression(users.id)
    uppercase_email: string; @SqlExpression(upper(users.email))
  }

  Select :: #run sql_select(UserWithUppercaseEmail);

  WhereIdsInFixtureData :: SqlWhere(SQL_EXPRESSION="id IN (1, 2)", ARGS_COUNT=0);
  where: WhereIdsInFixtureData;

  actual, success := sql_select_execute(Select, "users", *where);
  assert(success);

  expected := UserWithUppercaseEmail.[
    .{
      user_id=2,
      uppercase_email="ANOTHER@EMAIL.EDU"
    },
    .{
      user_id=1,
      uppercase_email="SOMEONE@EMAIL.ORG"
    }
  ];

  assert(expected.count == actual.count);
  for expected, expected_index: expected {
    // TODO: seems like psql ints don't work correctly at compile time, but are fine at run time
    // assert_equals(expected.user_id, actual[expected_index].user_id);
    included := false;
    for actual: actual {
      if expected.uppercase_email == actual.uppercase_email included = true;
    }
    assert(included);
  }
} @Test;
