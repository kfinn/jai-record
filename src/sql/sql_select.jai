SqlSelect :: struct($SQL_EXPRESSION: string, $Record: Type) {}

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
