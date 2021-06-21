Nullable :: struct($Value: $T) {
  present: bool;
  value: Value;
}

time_t :: s64;
UUID :: string;

_CONNECTION : *PGconn;

jai_record_pg_connection :: () -> *PGconn, success: bool {
  if _CONNECTION != null return _CONNECTION, true;

  connection, success := connect("postgres://postgres:password@db:5432/postgres");

  if success {
    _CONNECTION = connection;
    return _CONNECTION, true;
  } else {
    return null, false;
  }
}
