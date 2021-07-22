#run describe("sql_where.jai", #code{
  describe("sql_where_and", #code{
    it("joins two literal where expressions", #code{
      lhs: SqlWhere("id = :id", struct { id: int; });
      lhs.id = 12;

      rhs: SqlWhere("birthday BETWEEN :start_date AND :end_date", struct { start_date: string; end_date: string; });
      rhs.start_date = "1990-01-01";
      rhs.end_date = "2000-01-01";

      and := sql_where_and(*lhs, *rhs);

      expect(
        type_of(and).to_string(),
        to_equal("(id = :lhs.id) AND (birthday BETWEEN :rhs.start_date AND :rhs.end_date)")
      );

      expect(and.lhs.id, to_equal(12));
      expect(and.rhs.start_date, to_equal("1990-01-01"));
      expect(and.rhs.end_date, to_equal("2000-01-01"));
    });

    it("joins arbitrarily many literal and compound where expressions", #code {
      condition_1: SqlWhere("id = :id", struct { id: int; });
      condition_1.id = 123;
      condition_2: SqlWhere("birthday BETWEEN :start_date AND :end_date", struct { start_date: string; end_date: string; });
      condition_2.start_date = "1980-01-01";
      condition_2.end_date = "1990-01-01";

      condition_3: SqlWhere("favorite_color_id = :color_id", struct { color_id: int; });
      condition_3.color_id = 543;

      condition_4: SqlWhere("least_favorite_color_id = :color_id", struct { color_id: int; });
      condition_4.color_id = 654;

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
          "(id = :lhs.id) AND ((birthday BETWEEN :rhs.lhs.start_date AND :rhs.lhs.end_date) AND ((favorite_color_id = :rhs.rhs.lhs.color_id) AND (least_favorite_color_id = :rhs.rhs.rhs.color_id)))"
        )
      );
      expect(and.lhs.id, to_equal(123));
      expect(and.rhs.lhs.start_date, to_equal("1980-01-01"));
      expect(and.rhs.lhs.end_date, to_equal("1990-01-01"));
      expect(and.rhs.rhs.lhs.color_id, to_equal(543));
      expect(and.rhs.rhs.rhs.color_id, to_equal(654));
    });

    describe(
      "with some todos belonging to different users",
      before_all=#code {
        connection := jai_record_pg_connection();
        execute_with_struct_args(connection, "BEGIN");

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

        user_with_todos := user_insert_result[0];

        execute_with_struct_args(
          connection,
          #string SQL
            INSERT INTO todos (user_id, description, completed_at)
            VALUES
              (:id, 'create some todos', NOW()),
              (:id, 'complete the todos', NULL)
          SQL,
          user_with_todos
        );
      },
      after_all=#code {
        connection := jai_record_pg_connection();
        execute_with_struct_args(connection, "ROLLBACK");
      },
      body=#code {
        it("when used with sql_select_execute, returns records matching compound criteria", #code{
          with_email_address_like: SqlWhere("email LIKE :email_pattern", struct { email_pattern: string; });
          with_email_address_like.email_pattern = "%with_todos%";

          with_incomplete_todos: SqlWhere(#string SQL
            EXISTS (SELECT id FROM todos WHERE todos.user_id = users.id AND todos.completed_at IS NULL)
          SQL);

          with_completed_todos: SqlWhere(#string SQL
            EXISTS (SELECT id FROM todos WHERE todos.user_id = users.id AND todos.completed_at IS NOT NULL)
          SQL);

          User :: #run sql_select(struct { email: string; });
          matching_users := sql_select_execute(
            User,
            "users",
            sql_where_and(
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
