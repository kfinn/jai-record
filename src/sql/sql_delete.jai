sql_delete_execute :: ($from: string, where: $SqlWhere) -> success: bool {
  connection, postgres_connection_success := postgres_connection();
  if !postgres_connection_success return false;

  command :: #run sprint(
    "DELETE FROM \"%\" WHERE %;",
    from,
    SqlWhere.to_string()
  );

  return execute(connection, command, where);
}
