#run describe("belongs_to.jai", #code{
  describe(
    "preload",
    before_all=#code {
      connection := jai_record_pg_connection();
      execute(connection, "BEGIN");
    },
    after_all=#code {
      connection := jai_record_pg_connection();
      execute(connection, "ROLLBACK");
    },
    body=#code{
      it("preloads all associated records", #code{
        TestUser :: struct {
          id: int;
          email: string;
        }
        TestUsersRepo :: #run repo("users", TestUser);

        TestTodo :: struct {
          id: int;
          user_id: int;
          description: string;
        }
        TestTodosRepo :: #run repo("todos", TestTodo);

        TestUserHasManyTestTodos :: HasMany(
          TestUsersRepo,
          TestTodosRepo,
          "test_user",
          "test_todos",
          "user_id",
          inverse_of=TestTodoBelongsToTestUser
        );

        TestTodoBelongsToTestUser :: #run belongs_to(
          TestTodosRepo,
          TestUsersRepo,
          "test_todo",
          "test_user",
          "user_id"
        );

        connection := jai_record_pg_connection();

        InsertResult :: struct { id: int; }

        test_user_insert_results := execute(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO users (email)
            VALUES
              ('user_with_some_todos@email.org'),
              ('user_with_one_todo@email.edu')
            RETURNING id;
          SQL
        );

        user_with_some_todos_id := test_user_insert_results[0].id;
        user_with_one_todo_id := test_user_insert_results[1].id;

        test_todo_insert_results := execute(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO todos (user_id, description)
            VALUES
              ($1, 'first todo for user with some todos'),
              ($1, 'second todo for user with some todos'),
              ($2, 'todo for user with one todo')
            RETURNING id
          SQL,
          user_with_some_todos_id,
          user_with_one_todo_id
        );

        first_test_todo_for_user_with_some_todos_id := test_todo_insert_results[0].id;
        second_test_todo_for_user_with_some_todos_id := test_todo_insert_results[1].id;
        test_todo_for_user_with_one_todo_id := test_todo_insert_results[2].id;

        test_todo_ids: [..]Any;
        for * test_todo_insert_results array_add(*test_todo_ids, it.id);

        is_test_todo: SqlWhere("id IN (?)", 1);
        is_test_todo.args[0] = test_todo_ids;

        test_todos_with_test_users := TestTodoBelongsToTestUser.preload(
          TestTodosRepo.all(*is_test_todo)
        );

        expect(test_todos_with_test_users.count, to_equal(3));

        find_actual_test_todo_by_id :: (id: int, test_todos: []$T) -> *T {
          for * test_todos if it.id == id return it;
          return null;
        }

        first_test_todo_for_user_with_some_todos := find_actual_test_todo_by_id(
          first_test_todo_for_user_with_some_todos_id,
          test_todos_with_test_users
        );
        expect(first_test_todo_for_user_with_some_todos, to_be_present());
        expect(first_test_todo_for_user_with_some_todos.description, to_equal("first todo for user with some todos"));
        expect(first_test_todo_for_user_with_some_todos.test_user, to_be_present());
        expect(first_test_todo_for_user_with_some_todos.test_user.email, to_equal("user_with_some_todos@email.org"));

        second_test_todo_for_user_with_some_todos := find_actual_test_todo_by_id(
          second_test_todo_for_user_with_some_todos_id,
          test_todos_with_test_users
        );
        expect(second_test_todo_for_user_with_some_todos, to_be_present());
        expect(second_test_todo_for_user_with_some_todos.description, to_equal("second todo for user with some todos"));
        expect(second_test_todo_for_user_with_some_todos.test_user, to_be_present());
        expect(second_test_todo_for_user_with_some_todos.test_user.email, to_equal("user_with_some_todos@email.org"));

        test_todo_for_user_with_one_todo := find_actual_test_todo_by_id(
          test_todo_for_user_with_one_todo_id,
          test_todos_with_test_users
        );
        expect(test_todo_for_user_with_one_todo, to_be_present());
        expect(test_todo_for_user_with_one_todo.description, to_equal("todo for user with one todo"));
        expect(test_todo_for_user_with_one_todo.test_user, to_be_present());
        expect(test_todo_for_user_with_one_todo.test_user.email, to_equal("user_with_one_todo@email.edu"));
      });
    }
  );
});
