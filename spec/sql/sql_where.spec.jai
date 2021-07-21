#run describe("sql_where.jai", #code{
  describe("sql_where_and", #code{
    it("joins two literal where expressions", #code{
      lhs: SqlWhere("id = ?", 1);
      lhs.args[0] = 12;

      rhs: SqlWhere("birthday BETWEEN ? AND ?", 2);
      rhs.args[0] = "1990-01-01";
      rhs.args[1] = "2000-01-01";

      and := sql_where_and(*lhs, *rhs);

      expect(
        type_of(and).to_string(),
        to_equal("(id = ?) AND (birthday BETWEEN ? AND ?)")
      );

      expect(and.args.count, to_equal(3));
      expect(<<(cast(*int)and.args[0].value_pointer), to_equal(12));
      expect(<<(cast(*string)and.args[1].value_pointer), to_equal("1990-01-01"));
      expect(<<(cast(*string)and.args[2].value_pointer), to_equal("2000-01-01"));
    });

    it("joins arbitrarily many literal and compound where expressions", #code {
      condition_1: SqlWhere("id = ?", 1);
      condition_1.args[0] = 123;
      condition_2: SqlWhere("birthday BETWEEN ? AND ?", 2);
      condition_2.args[0] = "1980-01-01";
      condition_2.args[1] = "1990-01-01";

      condition_3: SqlWhere("favorite_color_id = ?", 1);
      condition_3.args[0] = 543;

      condition_4: SqlWhere("least_favorite_color_id = ?", 1);
      condition_4.args[0] = 654;

      and := sql_where_and(
        *condition_1,
        *sql_where_and(
          *condition_2,
          *sql_where_and(
            *condition_3,
            *condition_4
          )
        )
      );

      expect(
        type_of(and).to_string(),
        to_equal(
          "(id = ?) AND ((birthday BETWEEN ? AND ?) AND ((favorite_color_id = ?) AND (least_favorite_color_id = ?)))"
        )
      );
      expect(and.args.count, to_equal(5));
      expect(<<(cast(*int)and.args[0].value_pointer), to_equal(123));
      expect(<<(cast(*string)and.args[1].value_pointer), to_equal("1980-01-01"));
      expect(<<(cast(*string)and.args[2].value_pointer), to_equal("1990-01-01"));
      expect(<<(cast(*int)and.args[3].value_pointer), to_equal(543));
      expect(<<(cast(*int)and.args[4].value_pointer), to_equal(654));
    });

    describe(
      "with some todos belonging to different users",
      before_all=#code {
        connection := jai_record_pg_connection();
        execute(connection, "BEGIN");

        UserInsertResult :: struct { id: int; };
        user_insert_result := execute_with_struct_args(
          connection,
          UserInsertResult,
          #string SQL
            INSERT INTO users (email)
            VALUES
              ('user_with_todos@email.org'),
              ('user_without_todos@email.org')
            RETURNING id
          SQL
        );

        user_with_todos_id := user_insert_result[0].id;

        execute(
          connection,
          #string SQL
            INSERT INTO todos (user_id, description, completed_at)
            VALUES
              ($1, 'create some todos', NOW()),
              ($1, 'complete the todos', NULL)
          SQL,
          user_with_todos_id
        );
      },
      after_all=#code {
        connection := jai_record_pg_connection();
        execute(connection, "ROLLBACK");
      },
      body=#code {
        it("when used with sql_select_execute, returns records matching compound criteria", #code{
          with_email_address_like: SqlWhere("email LIKE ?", 1);
          with_email_address_like.args[0] = "%with_todos%";

          with_incomplete_todos: SqlWhere(#string SQL
            EXISTS (SELECT id FROM todos WHERE todos.user_id = users.id AND todos.completed_at IS NULL)
          SQL, 0);

          with_completed_todos: SqlWhere(#string SQL
            EXISTS (SELECT id FROM todos WHERE todos.user_id = users.id AND todos.completed_at IS NOT NULL)
          SQL, 0);

          User :: #run sql_select(struct { email: string; });
          matching_users := sql_select_execute(
            User,
            "users",
            *sql_where_and(
              *with_email_address_like,
              *sql_where_and(
                *with_incomplete_todos,
                *with_completed_todos
              )
            )
          );
          expect(matching_users.count, to_equal(1));
          expect(matching_users[0].email, to_equal("user_with_todos@email.org"));
        });
      }
    );
  });
});
