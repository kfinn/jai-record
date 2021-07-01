sql_delete_execute :: (from: string, where: *SqlWhere) -> success: bool {
  connection, jai_record_pg_connection_success := jai_record_pg_connection();
  if !jai_record_pg_connection_success return false;

  args: []Any;
  if where != null args = where.args;

  prepared_sql, prepared_args := prepare_sql_placeholders_for_args(sql_where_to_string(where), args);

  command := sprint(
    "DELETE FROM \"%\" WHERE %;",
    from,
    prepared_sql
  );

  return execute(connection, command, ..prepared_args);
}
