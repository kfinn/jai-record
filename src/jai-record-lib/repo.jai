EmptyMutableRecord :: struct {};

repo :: (
  $table_name: string,
  $Record: Type,
  $MutableRecord: Type = EmptyMutableRecord
) -> Type {
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
    where :: #bake_arguments repo_where(repo=Repo);
    all :: #bake_arguments repo_all(repo=Repo);
    save :: #bake_arguments repo_save(repo=Repo);
    delete :: #bake_arguments repo_delete(repo=Repo);
  };

  return Repo;
}

repo_find :: (
  $repo: $RepoType, // TypeDotHack
  id: $T
) -> *repo.Record, success: bool {
  with_id: SqlWhere("id = :id", struct { id: T; });
  with_id.id = id;

  records, all_success := repo.where(with_id);

  if !all_success return null, false;
  if records.count != 1 return null, false;
  return *records[0], true;
}

repo_all :: ($repo: $RepoType) -> []repo.Record, success: bool { // TypeDotHack
  records, success := repo_where(repo, EmptySqlWhere.{});
  return records, success;
}

repo_where :: ($repo: $RepoType, where: $Where) -> []repo.Record, success: bool { // TypeDotHack
  records, success := sql_select_execute(
    repo.Select,
    repo.table_name,
    where
  );
  if !success return .[], false;
  return records, true;
}

repo_save :: ($repo: $RepoType, record: *repo.Record) -> success: bool { // TypeDotHack
  if (record.id == 0) {
    insert: repo.Insert;

    copy_mutable_fields(record, *insert.insertable_fields);
    id, success := sql_insert_execute(
      repo.table_name,
      insert
    );
    if !success return false;
    record.id = id;
    return true;
  } else {
    update: repo.Update;
    where: SqlWhere("id = :id", struct { id: repo.IdType; });
    where.id = record.id;

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

repo_delete :: ($repo: $RepoType, record: *repo.Record) -> success: bool { // TypeDotHack
  where: SqlWhere("id = :id", struct { id: repo.IdType; });
  where.id = record.id;

  return sql_delete_execute(repo.table_name, where);
};
