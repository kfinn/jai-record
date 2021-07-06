SqlUpdate :: struct(
  $SQL_EXPRESSION: string,
  $ARGS_COUNT: int,
  $UpdatableFields: Type,
  $to_sql_update_args: (updatable_fields: *UpdatableFields) -> []Any
) {
  using updatable_fields: UpdatableFields;
}

sql_update :: ($UpdatableFields: Type) -> Type {
  SQL_EXPRESSION :: #run () -> string {
    sql_expression_builder: String_Builder;
    defer free_buffers(*sql_expression_builder);

    updates: [..]string;
    defer array_reset(*updates);

    updatable_fields_type_info := type_info(UpdatableFields);
    for updatable_fields_type_info.members {
      array_add(*updates, sprint("%=?", it.name));
    }

    print_to_builder(*sql_expression_builder, join(..updates, separator=", "));

    return builder_to_string(*sql_expression_builder);
  }();

  ARGS_COUNT ::  #run type_info(UpdatableFields).members.count;

  // TODO: clean up copypasta from ./sql_insert.jai
  to_sql_update_args :: (updatable_fields: *UpdatableFields) -> [..]Any {
    #insert #run () -> string {
      builder: String_Builder;
      defer free_buffers(*builder);

      updatable_fields_type_info := type_info(UpdatableFields);
      print_to_builder(*builder, "result := New([..]Any);\n", updatable_fields_type_info.members.count);
      for updatable_fields_type_info.members {
        print_to_builder(*builder, "array_add(result, updatable_fields.%);\n", it.name);
      }

      print_to_builder(*builder, "return <<result;\n");

      return builder_to_string(*builder);
    }();
  };



  return SqlUpdate(
    SQL_EXPRESSION=SQL_EXPRESSION,
    ARGS_COUNT=ARGS_COUNT,
    UpdatableFields=UpdatableFields,
    to_sql_update_args=to_sql_update_args
  );
}

sql_update_execute :: (table_name: string, update: *$Update, where: *$SqlWhere) -> success: bool {
  connection, jai_record_pg_connection_success := jai_record_pg_connection();
  if !jai_record_pg_connection_success return false;

  expression_string_builder: String_Builder;
  defer free_buffers(*expression_string_builder);

  print_to_builder(*expression_string_builder, "UPDATE % ", table_name);
  print_to_builder(*expression_string_builder, "SET % ", Update.SQL_EXPRESSION);

  where_string := sql_where_to_string(where);
  if where_string != "" {
    print_to_builder(*expression_string_builder, "WHERE % ", where_string);
  }
  print_to_builder(*expression_string_builder, ";");
  expression_string_with_placeholders := builder_to_string(*expression_string_builder);

  args: [Update.ARGS_COUNT + SqlWhere.ARGS_COUNT]Any;

  for Update.to_sql_update_args(*update.updatable_fields) args[it_index] = it;
  if where != null {
    for where.args args[Update.ARGS_COUNT + it_index] = it;
  }

  expression_string, flattened_args := prepare_sql_placeholders_for_args(expression_string_with_placeholders, args);

  return execute(
    connection,
    expression_string,
    ..args
  );
}
