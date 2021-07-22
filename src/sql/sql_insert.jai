SqlInsert :: struct(
  $SQL_EXPRESSION: string,
  $IdType: Type,
  $InsertableFields: Type,
) {
  using insertable_fields: InsertableFields;
}

sql_insert :: ($InsertableFields: Type, $IdType: Type) -> Type {
  SQL_EXPRESSION :: #run () -> string {
    sql_expression_builder: String_Builder;
    defer free_buffers(*sql_expression_builder);

    insertable_fields_type_info := type_info(InsertableFields);
    insertable_field_names: [..]string;
    defer array_reset(*insertable_field_names);
    insertable_field_placeholders: [..]string;
    defer array_reset(*insertable_field_placeholders);
    for insertable_fields_type_info.members {
      array_add(*insertable_field_names, it.name);
      array_add(*insertable_field_placeholders, sprint(":%", it.name));
    }

    return sprint(
      "(%) VALUES (%)", 
      join(..insertable_field_names, separator=", "),
      join(..insertable_field_placeholders, separator=", ")
    );
  }();

  return SqlInsert(
    SQL_EXPRESSION=SQL_EXPRESSION,
    IdType=IdType,
    InsertableFields=InsertableFields
  );
}

sql_insert_execute :: ($into: string, insert: $Insert) -> id: Insert.IdType, success: bool {
  connection, jai_record_pg_connection_success := jai_record_pg_connection();
  if !jai_record_pg_connection_success return 0, false;

  expression_string :: #run sprint("INSERT INTO % % RETURNING id;", into, Insert.SQL_EXPRESSION);

  Result :: struct {
    id: Insert.IdType;
  }

  results, execute_success := execute_with_struct_args(
    connection,
    Result,
    expression_string,
    insert
  );

  if !execute_success return 0, false;
  if results.count != 1 return 0, false;
  return results[0].id, true;
}
