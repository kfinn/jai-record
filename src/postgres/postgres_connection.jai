#add_context postgres_connection: *PGconn;

postgres_connection :: () -> *PGconn, success: bool {
  if context.postgres_connection != null return context.postgres_connection, true;

  connection, success := connect("postgres://postgres:password@db:5432/postgres");

  if success {
    context.postgres_connection = connection;
    return context.postgres_connection, true;
  } else {
    return null, false;
  }
}

push_postgres_connection_context :: () #expand {
  previous_postgres_connection := context.postgres_connection;
  context.postgres_connection = null;
  `defer {
      if context.postgres_connection {
        close_postgres_connection(context.postgres_connection);
      }
      context.postgres_connection = previous_postgres_connection;
  }
}

close_postgres_connection :: (connection: *PGconn) {
  PQfinish(connection);
}
