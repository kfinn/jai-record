#run describe("has_many.jai", #code{
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

        TestTodoBelongsToTestUser :: BelongsTo(
          TestTodosRepo,
          TestUsersRepo,
          "test_todo",
          "test_user",
          "user_id"
        );

        connection := jai_record_pg_connection();

        InsertResult :: struct { id: int; }

        insert_results := execute_with_struct_args(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO users (email)
            VALUES
              ('user_with_some_todos@email.org'),
              ('user_with_no_todos@email.org'),
              ('user_with_one_todo@email.edu')
            RETURNING id;
          SQL
        );

        user_with_some_todos_id := insert_results[0].id;
        user_with_no_todos_id := insert_results[1].id;
        user_with_one_todo_id := insert_results[2].id;

        execute(
          connection,
          #string SQL
            INSERT INTO todos (user_id, description)
            VALUES
              ($1, 'first todo for user with some todos'),
              ($1, 'second todo for user with some todos'),
              ($1, 'third todo for user with some todos'),
              ($2, 'todo for user with one todo')
          SQL,
          user_with_some_todos_id,
          user_with_one_todo_id
        );

        test_user_ids: [..]int;
        for * insert_results array_add(*test_user_ids, it.id);

        is_test_user: SqlWhere("id IN (:ids)", struct { ids: []int; });
        is_test_user.ids = test_user_ids;

        test_users_with_test_todos := preload(
          TestUserHasManyTestTodos,
          TestUsersRepo.where(is_test_user)
        );

        expect(test_users_with_test_todos.count, to_equal(3));

        find_actual_test_user_by_id :: (id: int, test_users: []$T) -> *T {
          for * test_users if it.id == id return it;
          return null;
        }

        actual_test_user_with_some_todos := find_actual_test_user_by_id(
          user_with_some_todos_id,
          test_users_with_test_todos
        );
        expect(actual_test_user_with_some_todos, to_be_present());
        expect(actual_test_user_with_some_todos.test_todos.count, to_equal(3));

        actual_test_user_with_some_todos_todo_descriptions: [..]string;
        for actual_test_user_with_some_todos.test_todos {
          array_add(
            *actual_test_user_with_some_todos_todo_descriptions,
            it.description
          );
        }

        expect(actual_test_user_with_some_todos_todo_descriptions, to_contain_exactly(
          "first todo for user with some todos",
          "second todo for user with some todos",
          "third todo for user with some todos"
        ));

        actual_test_user_with_no_todos := find_actual_test_user_by_id(
          user_with_no_todos_id,
          test_users_with_test_todos
        );
        expect(actual_test_user_with_no_todos, to_be_present());
        expect(actual_test_user_with_no_todos.test_todos, to_be_empty());

        actual_test_user_with_one_todo := find_actual_test_user_by_id(
          user_with_one_todo_id,
          test_users_with_test_todos
        );
        expect(actual_test_user_with_one_todo, to_be_present());
        expect(actual_test_user_with_one_todo.test_todos.count, to_equal(1));
        expect(
          actual_test_user_with_one_todo.test_todos[0].description,
          to_equal("todo for user with one todo")
        );
      });
      it("sets inverses", #code{
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

        TestTodoBelongsToTestUser :: BelongsTo(
          TestTodosRepo,
          TestUsersRepo,
          "test_todo",
          "test_user",
          "user_id"
        );

        connection := jai_record_pg_connection();

        InsertResult :: struct { id: int; }

        insert_results := execute_with_struct_args(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO users (email)
            VALUES
              ('user_with_one_todo@email.edu')
            RETURNING id;
          SQL
        );

        user_with_one_todo_id := insert_results[0].id;

        execute(
          connection,
          #string SQL
            INSERT INTO todos (user_id, description)
            VALUES
              ($1, 'todo for user with one todo')
          SQL,
          user_with_one_todo_id
        );

        is_test_user: SqlWhere("id = :id", struct { id: int; });
        is_test_user.id = user_with_one_todo_id;

        test_users_with_test_todos := preload(
          TestUserHasManyTestTodos,
          TestUsersRepo.where(is_test_user)
        );

        expect(test_users_with_test_todos.count, to_equal(1));

        user_with_one_todo := test_users_with_test_todos[0];
        expect(user_with_one_todo.test_todos[0].test_user.email, to_equal("user_with_one_todo@email.edu"));

        user_with_one_todo.email = "some_new@email.gov";
        expect(user_with_one_todo.test_todos[0].test_user.email, to_equal("some_new@email.gov"));
      });
    }
  );
});
