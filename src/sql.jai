SqlFrom :: string;

SqlWhere :: struct($SQL_EXPRESSION: string, ARGS_COUNT: int) {
  args: [ARGS_COUNT]Any;
}

to_string :: ($select: Type, from: string, wheres: []SqlWhere) -> string {
  string_builder: String_Builder;
  defer free_buffers(*string_builder);

  print_to_builder(*string_builder, "SELECT % ", select.SQL_EXPRESSION);
  print_to_builder(*string_builder, "FROM % ", from);

  next_placeholder_index := 1;
  PLACEHOLDER :: #char "?";

  if wheres.count > 0 {
    print_to_builder(*string_builder, "WHERE ");
    for where: wheres {
      print_to_builder(*string_builder, "(");
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
      print_to_builder(*string_builder, ")");
      if it_index < wheres.count - 1 print_to_builder(*string_builder, " AND ");
    }
    print_to_builder(*string_builder, " ");
  }

  return builder_to_string(*string_builder);
}

sql_execute :: ($Select: Type, sql_from: string, wheres: ..SqlWhere) -> []Select, success: bool {
  connection, jai_record_pg_connection_success := jai_record_pg_connection();
  if !jai_record_pg_connection_success return Select.[], false;

  expression_string := to_string(Select, sql_from, wheres);

  args: [..]Any;
  defer array_reset(*args);

  for where: wheres {
    for arg: where.args {
      array_add(*args, arg);
    }
  }

  results, execute_success := execute(connection, Select, expression_string, ..args);
  if !execute_success return Select.[], false;
  return results, true;
}

// TODO: figure out why this won't compile anymore
// sql_execute_test :: () {
//   Select :: #run sql_select(
//     SqlSelection.{
//       name="user_id",
//       type=int,
//       expression="users.id"
//     },
//     SqlSelection.{
//       name="uppercase_email",
//       type=string,
//       expression="upper(users.email)"
//     }
//   );

//   actual, success := sql_execute(Select, "users");
//   assert(success);

//   expected := Select.[
//     Select.{
//       user_id=2,
//       uppercase_email="ANOTHER@EMAIL.EDU"
//     },
//     Select.{
//       user_id=1,
//       uppercase_email="SOMEONE@EMAIL.ORG"
//     }
//   ];

//   assert(expected.count == actual.count);
//   for expected, expected_index: expected {
//     // TODO: seems like psql ints don't work correctly at compile time, but are fine at run time
//     // assert(expected.user_id == actual[expected_index].user_id, "expected: %, actual: %", expected.user_id, actual[expected_index].user_id);
//     assert(expected.uppercase_email == actual[expected_index].uppercase_email, "expected: %, actual: %", expected.uppercase_email, actual[expected_index].uppercase_email);
//   }
// } @Test;

SqlSelection :: struct {
  name: string;
  type: Type;
  expression: string;
};

sql_select :: ($sql_selections: .. SqlSelection) -> Type {
  #insert #run () -> string {
    type_string_builder: String_Builder;
    defer free_buffers(*type_string_builder);

    sql_expression_builder: String_Builder;
    defer free_buffers(*sql_expression_builder);

    print_to_builder(*type_string_builder, "return struct {\n");

    for sql_selections {
      print_to_builder(*type_string_builder, "  %: %;\n", it.name, it.type);
      print_to_builder(*sql_expression_builder, "(%) as %", it.expression, it.name);
      if it_index < sql_selections.count - 1 print_to_builder(*sql_expression_builder, ", ");
    }

    print_to_builder(*type_string_builder, "  SQL_EXPRESSION :: \"%\";\n", builder_to_string(*sql_expression_builder));

    print_to_builder(*type_string_builder, "};\n");
    return builder_to_string(*type_string_builder);
  }();
};

sql_select_type_test :: () {
  actual :: #run sql_select(
    SqlSelection.{
      name="user_id",
      type=int,
      expression="users.id"
    },
    SqlSelection.{
      name="uppercase_email",
      type=string,
      expression="upper(users.email)"
    }
  );

  expected :: struct {
    user_id: int;
    uppercase_email: string;
    SQL_EXPRESSION :: "(users.id) as user_id, (upper(users.email)) as uppercase_email";
  };

  expected_info := type_info(expected);
  actual_info := type_info(actual);

  for expected_member: expected_info.members {
    matches := false;
    for actual_member: actual_info.members {
      if (
        actual_member.name == expected_member.name &&
        actual_member.type == expected_member.type
      ) {
          matches = true;
          break;
        }
    }
    assert(matches, "expected (%) member to be present in (%)", expected_member, actual_info.members);
    assert(expected.SQL_EXPRESSION == actual.SQL_EXPRESSION); 
  }
} @Test;
