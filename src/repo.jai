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

WithId :: SqlWhere(
  SQL_EXPRESSION="id = ?",
  ARGS_COUNT=1
);

repo :: ($table_name: string, $Record: Type) -> Type {
  IdType :: type_of(Record.id);
  Select :: #run sql_select(Record);

  Repo :: struct {
    Select :: Select;
    IdType :: IdType;
    Record :: Record;
    table_name :: table_name;
    find :: (id: IdType) -> *Select.Record, success: bool {
      with_id: WithId;
      with_id.args[0] = id;

      records, all_success := Repo.all(*with_id);

      if !all_success return null, false;
      if records.count != 1 return null, false;
      return *records[0], true;
    };
    all :: (where: *$Where = null) -> []Select.Record, success: bool {
      records, success := sql_select_execute(
        Select,
        table_name,
        where
      );
      if !success return .[], false;
      return records, true;
    };
  };

  return Repo;
}
