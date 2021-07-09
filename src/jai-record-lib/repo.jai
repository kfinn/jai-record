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

EmptyMutableRecord :: struct {};

repo :: ($table_name: string, $Record: Type, $MutableRecord: Type = EmptyMutableRecord) -> Type {
  IdType :: type_of(Record.id);
  Select :: #run sql_select(Record);
  Insert :: #run sql_insert(MutableRecord, IdType);
  Update :: #run sql_update(MutableRecord);

  Repo :: struct {
    Select :: Select;
    Insert :: Insert;
    Update :: Update;
    IdType :: IdType;
    Record :: Record;
    MutableRecord :: MutableRecord;
    table_name :: table_name;
    find :: #bake_arguments repo_find(repo=Repo);
    all :: #bake_arguments repo_all(repo=Repo);
    save :: #bake_arguments repo_save(repo=Repo);
    delete :: #bake_arguments repo_delete(repo=Repo);
  };

  return Repo;
}

repo_find :: ($repo: Type, id: $T) -> *repo.Record, success: bool {
  with_id: WithId;
  with_id.args[0] = id;

  records, all_success := repo.all(*with_id);

  if !all_success return null, false;
  if records.count != 1 return null, false;
  return *records[0], true;
}

repo_all :: ($repo: Type, where: *$Where = null) -> []repo.Record, success: bool {
  records, success := sql_select_execute(
    repo.Select,
    repo.table_name,
    where
  );
  if !success return .[], false;
  return records, true;
}

repo_save :: ($repo: Type, record: *repo.Record) -> success: bool {
  if (record.id == 0) {
    insert: repo.Insert;

    copy_mutable_fields(record, *insert.insertable_fields);
    id, success := sql_insert_execute(
      repo.table_name,
      *insert
    );
    if !success return false;
    record.id = id;
    return true;
  } else {
    update: repo.Update;
    where: SqlWhere("id = ?", 1);
    where.args[0] = record.id;

    copy_mutable_fields(record, *update.updatable_fields);
    success := sql_update_execute(repo.table_name, *update, *where);
    return success;
  }
}

copy_mutable_fields :: (record: *$Record, mutable_fields: *$MutableFields) {
  #insert #run () -> string {
    string_builder: String_Builder;
    defer free_buffers(*string_builder);

    for member: type_info(MutableFields).members {
      print_to_builder(*string_builder, "mutable_fields.% = record.%;\n", member.name, member.name);
    }

    return builder_to_string(*string_builder);
  }();
}

repo_delete :: ($repo: Type, record: *repo.Record) -> success: bool {
  where: SqlWhere("id = ?", 1);
  where.args[0] = record.id;

  return sql_delete_execute(repo.table_name, *where);
};
