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

find_id_column_type :: (sql_selections: []SqlSelection) -> Type {
  for sql_selections {
    if it.name == "id" return it.type;
  }
  assert(false, "no id column found in table_repo selects");
}

repo :: ($table_name: string, $sql_selections: ..SqlSelection) -> Type {
  IdType :: #run find_id_column_type(sql_selections);
  Select :: #run sql_select(..sql_selections);

  return struct {
    find :: (id: IdType) -> *Select, success: bool {
      records, sql_execute_success := sql_execute(Select, table_name, "id = $1", id);
      if !sql_execute_success return null, false;
      if records.count == 0 return null, false;

      return *records[0], true;
    }
  };
}
