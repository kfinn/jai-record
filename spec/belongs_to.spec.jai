#run describe("belongs_to.jai", #code{
  describe(
    "preload",
    before_each=#code {
      connection := postgres_connection();
      execute(connection, "BEGIN");
    },
    after_each=#code {
      connection := postgres_connection();
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
        );

        TestTodoBelongsToTestUser :: BelongsTo(
          TestTodosRepo,
          TestUsersRepo,
          "test_todo",
          "test_user",
          "user_id"
        );

        connection := postgres_connection();

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

        todo_insert_args: struct {
          user_with_some_todos_id: int;
          user_with_one_todo_id: int;
        }
        todo_insert_args.user_with_some_todos_id = test_user_insert_results[0].id;
        todo_insert_args.user_with_one_todo_id = test_user_insert_results[1].id;

        test_todo_insert_results := execute(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO todos (user_id, description)
            VALUES
              (:user_with_some_todos_id, 'first todo for user with some todos'),
              (:user_with_some_todos_id, 'second todo for user with some todos'),
              (:user_with_one_todo_id, 'todo for user with one todo')
            RETURNING id
          SQL,
          todo_insert_args
        );

        first_test_todo_for_user_with_some_todos_id := test_todo_insert_results[0].id;
        second_test_todo_for_user_with_some_todos_id := test_todo_insert_results[1].id;
        test_todo_for_user_with_one_todo_id := test_todo_insert_results[2].id;

        test_todo_ids: [..]int;
        for * test_todo_insert_results array_add(*test_todo_ids, it.id);

        is_test_todo: SqlWhere("id IN (:ids)", struct { ids: []int; });
        is_test_todo.ids = test_todo_ids;

        test_todos_with_test_users := preload(
          TestTodoBelongsToTestUser,
          TestTodosRepo.where(is_test_todo)
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
          inverse_of=BelongsTo(
            TestTodosRepo,
            TestUsersRepo,
            "test_todo",
            "test_user",
            "user_id",
          )
        );

        TestTodoBelongsToTestUser :: BelongsTo(
          TestTodosRepo,
          TestUsersRepo,
          "test_todo",
          "test_user",
          "user_id",
          inverse_of=HasMany(
            TestUsersRepo,
            TestTodosRepo,
            "test_user",
            "test_todos",
            "user_id",
          )
        );

        connection := postgres_connection();

        InsertResult :: struct { id: int; }

        test_user_insert_results := execute(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO users (email)
            VALUES
              ('user_with_one_todo@email.edu')
            RETURNING id;
          SQL
        );

        test_user := test_user_insert_results[0];

        test_todo_insert_results := execute(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO todos (user_id, description)
            VALUES
              (:id, 'todo description')
            RETURNING id
          SQL,
          test_user
        );

        test_todo_id := test_todo_insert_results[0].id;

        is_test_todo: SqlWhere("id = :id", struct { id: int; });
        is_test_todo.id = test_todo_id;

        test_todos_with_test_users := preload(
          TestTodoBelongsToTestUser,
          TestTodosRepo.where(is_test_todo)
        );

        test_todo := test_todos_with_test_users[0];
        expect(test_todo.test_user.test_todos[0].description, to_equal("todo description"));

        test_todo.description = "I'd go for a banana right now";
        expect(test_todo.test_user.test_todos[0].description, to_equal("I'd go for a banana right now"));
      });
    }
  );
});
