to_string :: (select: string, from: string, where: *SqlWhere) -> string {
  string_builder: String_Builder;
  defer free_buffers(*string_builder);

  print_to_builder(*string_builder, "SELECT % ", select);
  print_to_builder(*string_builder, "FROM % ", from);

  next_placeholder_index := 1;
  PLACEHOLDER :: #char "?";

  if where != null {
    print_to_builder(*string_builder, "WHERE ");
    for character_index: 0..(where.SQL_EXPRESSION.count - 1) {
      character := where.SQL_EXPRESSION[character_index];
      if character == PLACEHOLDER {
        print_to_builder(*string_builder, "$%", next_placeholder_index);
        next_placeholder_index = next_placeholder_index + 1;
      } else {
        single_character_string := sprint("_");
        single_character_string.data[0] = character;
        print_to_builder(*string_builder, "%", single_character_string);
      }
    }
    print_to_builder(*string_builder, " ");
  }

  return builder_to_string(*string_builder);
}

sql_execute :: (_s: $Select, sql_from: string, where: *SqlWhere) -> []Select.Record, success: bool {
  connection, jai_record_pg_connection_success := jai_record_pg_connection();
  if !jai_record_pg_connection_success return Select.Record.[], false;

  expression_string := to_string(Select.SQL_EXPRESSION, sql_from, where);

  args: []Any;
  if where != null args = where.args; 
  results, execute_success := execute(connection, Select.Record, expression_string, ..args);
  if !execute_success return Select.Record.[], false;
  return results, true;
}

sql_execute_test :: () {
  UserWithUppercaseEmail :: struct {
    user_id: int; @SqlExpression(users.id)
    uppercase_email: string; @SqlExpression(upper(users.email))
  }

  Select :: #run sql_select(UserWithUppercaseEmail);

  UnconditionalWhere :: SqlWhere(SQL_EXPRESSION="TRUE", ARGS_COUNT=0);
  where: UnconditionalWhere;

  _s: Select;
  actual, success := sql_execute(_s, "users", *where);
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
    // assert(expected.user_id == actual[expected_index].user_id, "expected: %, actual: %", expected.user_id, actual[expected_index].user_id);
    assert_equals(expected.uppercase_email, actual[expected_index].uppercase_email);
  }
} @Test;
