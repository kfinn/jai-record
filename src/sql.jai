SqlFrom :: string;

SqlWhere :: struct($SQL_EXPRESSION: string, ARGS_COUNT: int) {
  args: [ARGS_COUNT]Any;
}

to_string :: (select: string, from: string, wheres: []SqlWhere) -> string {
  string_builder: String_Builder;
  defer free_buffers(*string_builder);

  print_to_builder(*string_builder, "SELECT % ", select);
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

sql_execute :: (_s: $Select/SqlSelect, sql_from: string, wheres: ..SqlWhere) -> []Select.Record, success: bool {
  connection, jai_record_pg_connection_success := jai_record_pg_connection();
  if !jai_record_pg_connection_success return Select.Record.[], false;

  expression_string := to_string(Select.SQL_EXPRESSION, sql_from, wheres);

  args: [..]Any;
  defer array_reset(*args);

  for where: wheres {
    for arg: where.args {
      array_add(*args, arg);
    }
  }

  results, execute_success := execute(connection, Select.Record, expression_string, ..args);
  if !execute_success return Select.Record.[], false;
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

SqlSelect :: struct($SQL_EXPRESSION: string, $Record: Type) {
  record: Record;
}

sql_select :: ($Record: Type) -> Type {
  sql_expression :: #run () -> string {
    sql_expression_builder: String_Builder;
    defer free_buffers(*sql_expression_builder);

    record_type_info := type_info(Record);

    for member, member_index: record_type_info.members {
      sql_expression_note: string;
      SQL_EXPRESSION_NOTE_PREFIX :: "SqlExpression(";
      SQL_EXPRESSION_NOTE_SUFFIX :: ")";

      for note: member.notes {
        if !has_prefix(note, SQL_EXPRESSION_NOTE_PREFIX) continue;
        if !has_suffix(note, SQL_EXPRESSION_NOTE_SUFFIX) continue;

        sql_expression_note = note;
      }

      member_sql_expression: string;
      if sql_expression_note {
        slice_start_index :: SQL_EXPRESSION_NOTE_PREFIX.count;
        slice_end_index := sql_expression_note.count - SQL_EXPRESSION_NOTE_SUFFIX.count - 1;

        member_sql_expression_source := slice(
          sql_expression_note,
          slice_start_index,
          slice_end_index
        );

        member_sql_expression = sprint("(%) as %", member_sql_expression_source, member.name);
      } else {
        member_sql_expression = sprint("\"%\"", member.name);
      }
      print_to_builder(*sql_expression_builder, "%", member_sql_expression);
      if member_index < record_type_info.members.count - 1 {
        print_to_builder(*sql_expression_builder, ", ");
      }
    }

    return builder_to_string(*sql_expression_builder);
  }();

  return SqlSelect(SQL_EXPRESSION=sql_expression, Record=Record);
};

sql_select_test :: () {
  SomeRecord :: struct {
    id: int;
    name: string;
    uppercase_email: string; @SqlExpression(upper(email))
  }

  actual :: #run sql_select(SomeRecord);

  assert(actual.Record == SomeRecord);
  assert_equals(
    "\"id\", \"name\", (upper(email)) as uppercase_email", actual.SQL_EXPRESSION
  );
} @Test;
