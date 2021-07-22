#run describe("postgres", #code{
  describe("execute_with_struct_args", #code{
    describe(
      "with nullable args",
      before_all=#code {
        connection := jai_record_pg_connection();
        execute_with_struct_args(connection, "BEGIN");
      },
      after_all=#code {
        connection := jai_record_pg_connection();
        execute_with_struct_args(connection, "ROLLBACK");
      },
      body=#code{
        connection := jai_record_pg_connection();

          User :: struct {
            id: int;
            email: string;
            created_at: string;
            updated_at: string;
          }

          insert_users_results := execute_with_struct_args(
            connection,
            User,
            "INSERT INTO users (email) VALUES ('some_email@whatever.gov') RETURNING id, email, created_at, updated_at"
          );

          expect(insert_users_results.count, to_equal(1));

          user := insert_users_results[0];

          Todo :: struct {
            id: int;
            user_id: int;
            description: string;
            completed_at: *string;
            created_at: string;
            updated_at: string;
          }

          TodoCreation :: struct {
            using todo: Todo;
            user: *User;
          }

          first_todo_creation: TodoCreation;
          first_todo_creation.user = *user;
          first_todo_creation.description = "some description";
          first_todo_creation.completed_at = null;

          {
            insert_todos_results := execute_with_struct_args(
              connection,
              Todo,
              #string SQL
                INSERT INTO todos (user_id, description, completed_at) VALUES (:user.id, :description, :completed_at) RETURNING *;
              SQL,
              first_todo_creation
            );

            expect(insert_todos_results.count, to_equal(1));
            first_todo := insert_todos_results[0];
            expect(first_todo.user_id, to_equal(user.id));
            expect(first_todo.description, to_equal("some description"));
            expect(first_todo.completed_at, to_be_null());
          }

          second_todo_creation: TodoCreation;
          second_todo_creation.user = *user;
          second_todo_creation.description = "another description";
          completed_at := "2021-05-06 12:34:56";
          second_todo_creation.completed_at = *completed_at;

          {
            insert_todos_results := execute_with_struct_args(
              connection,
              Todo,
              #string SQL
                INSERT INTO todos (user_id, description, completed_at) VALUES (:user.id, :description, :completed_at) RETURNING *;
              SQL,
              second_todo_creation
            );

            expect(insert_todos_results.count, to_equal(1));
            first_todo := insert_todos_results[0];
            expect(first_todo.user_id, to_equal(user.id));
            expect(first_todo.description, to_equal("another description"));
            expect(first_todo.completed_at, to_be_present());
            expect(<<first_todo.completed_at, to_begin_with("2021-05-06"));
          }
        }
    );
    describe(
      "with array args",
      before_all=#code {
        connection := jai_record_pg_connection();
        execute_with_struct_args(connection, "BEGIN");
      },
      after_all=#code {
        connection := jai_record_pg_connection();
        execute_with_struct_args(connection, "ROLLBACK");
      },
      body=#code {
        connection := jai_record_pg_connection();

        InsertResult :: struct {
          id: int;
        }

        insert_results := execute_with_struct_args(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO users (email) VALUES ('first@email.gov'), ('second@email.gov'), ('third@email.gov') RETURNING id
          SQL
        );

        Args :: struct {
          ids: []int;
        }

        ids: [..]int;
        defer array_reset(*ids);
        for insert_results array_add(*ids, it.id);

        args: Args;
        args.ids = ids;

        User :: struct {
          id: int;
          email: string;
        }

        select_results := execute_with_struct_args(
          connection,
          User,
          "SELECT id, email FROM users WHERE id IN (:ids)",
          args
        );

        expect(select_results.count, to_equal(3));
        selected_emails: [..]string;
        defer array_reset(*selected_emails);
        for select_results array_add(*selected_emails, it.email);

        expect(selected_emails, to_contain_exactly(
          "first@email.gov",
          "second@email.gov",
          "third@email.gov"
        ));
      }
    );
  });
});
