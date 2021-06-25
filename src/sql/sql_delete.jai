sql_delete_execute :: (from: string, where: *SqlWhere) -> success: bool {
  connection, jai_record_pg_connection_success := jai_record_pg_connection();
  if !jai_record_pg_connection_success return false;

  command := sprint("DELETE FROM \"%\" WHERE %;", from, to_string(where));
  print("delete command: %\n", command);

  args: []Any;
  if where != null args = where.args;
  print("delete args\n");
  for args print("type: %, value: %\n", <<it.type, <<((cast(*int)it.value_pointer)));
  return execute(connection, command, ..args);
}

test_sql_delete_execute :: () {
  UserInsert :: #run sql_insert(struct {
    email: string;
  }, int);

  user_to_insert: UserInsert;
  user_to_insert.email = "test@email.edu";

  id, insert_success := sql_insert_execute("users", *user_to_insert);
  assert(insert_success);

  {
    user := UsersRepo.find(id);
    assert_equals("test@email.edu", user.email);
  }

  {
    with_id: WithId;
    with_id.args[0] = id;

    delete_success := sql_delete_execute("users", *with_id);
    assert(delete_success);
  }

  {
    user, success := UsersRepo.find(id);
    assert(!success);
    assert_equals(null, user);
  }
} @Test;
