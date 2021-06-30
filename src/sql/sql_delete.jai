sql_delete_execute :: (from: string, where: *SqlWhere) -> success: bool {
  connection, jai_record_pg_connection_success := jai_record_pg_connection();
  if !jai_record_pg_connection_success return false;

  command := sprint(
    "DELETE FROM \"%\" WHERE %;",
    from,
    prepare_sql_placeholders_for_args(to_string(where))
  );

  args: []Any;
  if where != null args = where.args;
  return execute(connection, command, ..args);
}
