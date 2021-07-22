SqlUpdate :: struct(
  $SQL_EXPRESSION: string,
  $UpdatableFields: Type
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
      array_add(*updates, sprint("%=:%", it.name, it.name));
    }

    print_to_builder(*sql_expression_builder, join(..updates, separator=", "));

    return builder_to_string(*sql_expression_builder);
  }();

  return SqlUpdate(
    SQL_EXPRESSION=SQL_EXPRESSION,
    UpdatableFields=UpdatableFields
  );
}

sql_update_execute :: ($table_name: string, update: $Update) -> success: bool {
  return sql_update_execute(table_name, update, EmptySqlWhere.{});
}

sql_update_execute :: ($table_name: string, update: $Update, where: $SqlWhere) -> success: bool {
  connection, jai_record_pg_connection_success := jai_record_pg_connection();
  if !jai_record_pg_connection_success return false;

  expression_string :: #run () -> string {
    expression_string_builder: String_Builder;
    defer free_buffers(*expression_string_builder);

    print_to_builder(*expression_string_builder, "UPDATE % ", table_name);
    print_to_builder(*expression_string_builder, "SET ");

    for update_component: parse_sql(Update.SQL_EXPRESSION) {
      component_string := slice(Update.SQL_EXPRESSION, update_component.start_index, update_component.count);
      if #complete update_component.kind == {
        case .SQL;
          print_to_builder(
            *expression_string_builder,
            "%",
            component_string
          );
        case .PLACEHOLDER;
          print_to_builder(
            *expression_string_builder,
            "%update.%",
            SQL_PLACEHOLDER_PREFIX,
            component_string
          );
      }
    }

    where_string := SqlWhere.to_string();
    if where_string == "" {
      return builder_to_string(*expression_string_builder);
    }

    print_to_builder(*expression_string_builder, " WHERE ");
    for where_component: parse_sql(where_string) {
      component_string := slice(where_string, where_component.start_index, where_component.count);
      if #complete where_component.kind == {
        case .SQL;
          print_to_builder(
            *expression_string_builder,
            "%",
            component_string
          );
        case .PLACEHOLDER;
          print_to_builder(
            *expression_string_builder,
            "%where.%",
            SQL_PLACEHOLDER_PREFIX,
            component_string
          );
      }
    }

    return builder_to_string(*expression_string_builder);
  }();

  args: struct {
    update: Update;
    where: SqlWhere;
  }
  args.update = update;
  args.where = where;

  return execute(
    connection,
    expression_string,
    args
  );
}
