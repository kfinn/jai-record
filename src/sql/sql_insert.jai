SqlInsert :: struct(
  $SQL_EXPRESSION: string,
  $IdType: Type,
  $InsertableFields: Type,
  $to_sql_insert_args: (insertable_fields: *InsertableFields) -> []Any
) {
  using insertable_fields: InsertableFields;
}

sql_insert :: ($InsertableFields: Type, $IdType: Type) -> Type {
  SQL_EXPRESSION :: #run () -> string {
    sql_expression_builder: String_Builder;
    defer free_buffers(*sql_expression_builder);

    insertable_fields_type_info := type_info(InsertableFields);
    insertable_field_names: [..]string;
    defer array_reset(*insertable_field_names);
    insertable_field_placeholders: [..]string;
    defer array_reset(*insertable_field_placeholders);
    for insertable_fields_type_info.members {
      array_add(*insertable_field_names, it.name);
      array_add(*insertable_field_placeholders, sprint("$%", it_index + 1));
    }

    return sprint("(%) VALUES (%)", join(insertable_field_names), join(insertable_field_placeholders));
  }();

  to_sql_insert_args :: (insertable_fields: *InsertableFields) -> [..]Any {
    #insert #run () -> string {
      builder: String_Builder;
      defer free_buffers(*builder);

      insertable_fields_type_info := type_info(InsertableFields);
      print_to_builder(*builder, "result := New([..]Any);\n", insertable_fields_type_info.members.count);
      for insertable_fields_type_info.members {
        print_to_builder(*builder, "array_add(result, insertable_fields.%);\n", it.name);
      }

      print_to_builder(*builder, "return <<result;\n");

      return builder_to_string(*builder);
    }();
  };

  return SqlInsert(
    SQL_EXPRESSION=SQL_EXPRESSION,
    IdType=IdType,
    InsertableFields=InsertableFields,
    to_sql_insert_args=to_sql_insert_args
  );
}

sql_insert_execute :: (into: string, insert: *$Insert) -> id: Insert.IdType, success: bool {
  connection, jai_record_pg_connection_success := jai_record_pg_connection();
  if !jai_record_pg_connection_success return 0, false;

  expression_string := sprint("INSERT INTO % % RETURNING id;", into, Insert.SQL_EXPRESSION);

  args := Insert.to_sql_insert_args(insert);
  defer array_free(args);

  Result :: struct {
    id: Insert.IdType;
  }

  results, execute_success := execute(
    connection,
    Result,
    expression_string,
    ..args
  );

  if !execute_success return 0, false;
  if results.count != 1 return 0, false;
  return results[0].id, true;
}

sql_insert_test :: () {
  TestUser :: struct {
    id: int;
    email: string;
    // created_at: time_t;
    // updated_at: time_t;
  }

  TestUsersRepo :: #run repo("users", TestUser);

  TestUserInsert :: #run sql_insert(struct {
    email: string;
    // created_at: time_t;
    // updated_at: time_t;
  }, int);

  // assert_equals("(email, created_at, updated_at) VALUES ($1, $2, $3)", TestUserInsert.SQL_EXPRESSION);
  assert_equals("(email) VALUES ($1)", TestUserInsert.SQL_EXPRESSION);
  assert_equals(int, TestUserInsert.IdType);

  test_user_to_insert: TestUserInsert;
  test_user_to_insert.email = "some@email.gov";
  // test_user_to_insert.created_at = 12345; 
  // test_user_to_insert.updated_at = 1234567;

  args := TestUserInsert.to_sql_insert_args(*test_user_to_insert);
  assert_equals(Type_Info_Tag.STRING, args[0].type.type);
  assert_equals("some@email.gov", <<(cast(*string)args[0].value_pointer));
  // assert_equals(Type_Info_Tag.INTEGER, args[1].type.type);
  // assert_equals(12345, <<(cast(*int)args[1].value_pointer));
  // assert_equals(Type_Info_Tag.INTEGER, args[2].type.type);
  // assert_equals(1234567, <<(cast(*int)args[2].value_pointer));

  inserted_id, execute_success := sql_insert_execute("users", *test_user_to_insert);
  assert(execute_success);

  found_user, find_success := TestUsersRepo.find(inserted_id);
  assert(find_success);

  assert_equals("some@email.gov", found_user.email);
  // assert_equals(12345, found_user.created_at);
  // assert_equals(1234567, found_user.updated_at);
} @Test;
