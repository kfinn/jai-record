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
  result: *Type;
  for sql_selections {
    if it.name == "id" { 
      result = *it.type;
      break;
    }
  }
  // TODO: test this
  assert(result != null, "no ID column specified for repo");
  return <<result;
}

WithId :: SqlWhere(
  SQL_EXPRESSION="id = ?",
  ARGS_COUNT=1
);

repo :: ($table_name: string, $sql_selections: ..SqlSelection) -> Type {
  IdType :: #run find_id_column_type(sql_selections);
  Select :: #run sql_select(..sql_selections);

  return struct {
    Select :: Select;
    table_name :: table_name;
    find :: (id: IdType) -> *Select, success: bool {
      with_id: WithId;
      with_id.args[0] = id;

      records, sql_execute_success := sql_execute(Select, table_name, with_id);
      if !sql_execute_success return null, false;
      if records.count == 0 return null, false;

      return *records[0], true;
    }
  };
}
