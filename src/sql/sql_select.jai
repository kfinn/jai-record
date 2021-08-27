SqlSelect :: struct($SQL_EXPRESSION: string, $Record: Type) {}

sql_select :: ($Record: Type) -> Type {
  sql_expression :: #run () -> string {
    sql_expression_builder: String_Builder;
    defer free_buffers(*sql_expression_builder);

    record_type_info := type_info(Record);

    for member, member_index: record_type_info.members {
      note_sql_expression, has_sql_expression_note := match_note("SqlExpression(", ")", *member);
      member_sql_expression: string;
      if has_sql_expression_note {
        member_sql_expression = sprint("(%) as \"%\"", note_sql_expression, member.name);
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

sql_select_execute :: ($Select: Type, $sql_from: string) -> []Select.Record, success: bool {
  results, success := sql_select_execute(Select, sql_from, EmptySqlWhere.{});
  return results, success;
}

sql_select_execute :: ($Select: Type, $sql_from: string, where: $Where) -> []Select.Record, success: bool {
  connection, postgres_connection_success := postgres_connection();
  if !postgres_connection_success return Select.Record.[], false;

  expression_string :: #run sql_select_to_string(Select.SQL_EXPRESSION, sql_from, Where);
  results, execute_success := execute(connection, Select.Record, expression_string, where);
  if !execute_success return Select.Record.[], false;
  return results, true;
}

sql_select_to_string :: ($select: string, $from: string, $Where: Type) -> string {
  return #run () -> string {
    string_builder: String_Builder;
    defer free_buffers(*string_builder);

    print_to_builder(*string_builder, "SELECT % ", select);
    print_to_builder(*string_builder, "FROM % ", from);

    where_string := Where.to_string();
    if where_string != "" {
      print_to_builder(*string_builder, "WHERE % ", where_string);
    }

    return builder_to_string(*string_builder);
  }();
}
