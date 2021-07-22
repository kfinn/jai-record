sql_delete_execute :: ($from: string, where: $SqlWhere) -> success: bool {
  connection, jai_record_pg_connection_success := jai_record_pg_connection();
  if !jai_record_pg_connection_success return false;

  command :: #run sprint(
    "DELETE FROM \"%\" WHERE %;",
    from,
    SqlWhere.to_string()
  );

  return execute_with_struct_args(connection, command, where);
}
