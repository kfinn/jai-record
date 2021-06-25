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

find_id_column_type :: ($Record: Type) -> Type {
  return type_of(Record.id);
}

WithId :: SqlWhere(
  SQL_EXPRESSION="id = ?",
  ARGS_COUNT=1
);

repo :: ($table_name: string, $Record: Type) -> Type {
  IdType :: #run find_id_column_type(Record);
  Select :: #run sql_select(Record);

  return struct {
    Select :: Select;
    table_name :: table_name;
    find :: (id: IdType) -> *Select.Record, success: bool {
      with_id: WithId;
      with_id.args[0] = id;

      _s: Select;

      records, sql_execute_success := sql_select_execute(_s, table_name, *with_id);
      if !sql_execute_success return null, false;
      if records.count == 0 return null, false;

      return *records[0], true;
    }
  };
}
