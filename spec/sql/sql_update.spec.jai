#run describe("sql_udpate.jai", #code{
  describe("sql_update", #code{
    it("generates a SQL_EXPRESSION setting all fields in the update type", #code{
      TestUpdate :: #run sql_update(struct {
        email: string;
        pets_count: int;
        favorite_pet_id: int;
        born_at: int;
        percent_complete: float;
      });

      expect(
        TestUpdate.SQL_EXPRESSION,
        to_equal(
          "email=?, pets_count=?, favorite_pet_id=?, born_at=?, percent_complete=?"
        )
      );
    });

    it("generates to_sql_update_args for all fields in the update type", #code {
      TestUpdate :: #run sql_update(struct {
        email: string;
        pets_count: int;
        favorite_pet_id: int;
        born_at: int;
        percent_complete: float;
      });

      test_update: TestUpdate;
      test_update.email = "some_great@email.edu";
      test_update.pets_count = 3;
      test_update.favorite_pet_id = 12;
      test_update.born_at = 12345;
      test_update.percent_complete = 0.25;

      sql_update_args := TestUpdate.to_sql_update_args(*test_update);
      expect(<<(cast(*string) sql_update_args[0].value_pointer), to_equal("some_great@email.edu"));
      expect(<<(cast(*int) sql_update_args[1].value_pointer), to_equal(3));
      expect(<<(cast(*int) sql_update_args[2].value_pointer), to_equal(12));
      expect(<<(cast(*int) sql_update_args[3].value_pointer), to_equal(12345));
      expect(<<(cast(*float) sql_update_args[4].value_pointer), to_equal(0.25));
    });
  });

  describe(
    "sql_update_execute",
    before_all=#code {
      connection := jai_record_pg_connection();
      execute(connection, "BEGIN");
    },
    after_all=#code {
      connection := jai_record_pg_connection();
      execute(connection, "ROLLBACK");
    },
    body=#code {
      it("updates records in the database", #code {
        connection, jai_record_pg_connection_success := jai_record_pg_connection();
        expect(jai_record_pg_connection_success, to_equal(true));

        ExecuteInsertResult :: struct { id: int; };
        execute_insert_result, execute_insert_success := execute(
          connection,
          ExecuteInsertResult,
          #string SQL
            INSERT INTO users (email)
            VALUES
              ('initial@email.org'),
              ('some_other_user@email.org')
            RETURNING id;
          SQL
        );

        expect(execute_insert_success, to_equal(true));
        expect(execute_insert_result.count, to_equal(2));

        user_to_update_id := execute_insert_result[0].id;
        user_not_to_update_id := execute_insert_result[1].id;

        UserMutableFields :: struct {
          email: string;
        };

        User :: struct {
          id: int;
          email: string;
        };

        UserUpdate :: #run sql_update(UserMutableFields);

        updated_user: UserUpdate;
        updated_user.email = "some_new@email.org";

        with_id: WithId;
        with_id.args[0] = user_to_update_id;

        sql_update_execute(
          "users",
          *updated_user,
          *with_id
        );

        {
          updated_results, success := execute(
            connection,
            User,
            #string SQL
              SELECT id, email FROM users WHERE id = $1
            SQL,
            user_to_update_id
          );
          expect(success, to_equal(true));
          expect(updated_results.count, to_equal(1));
          expect(updated_results[0].email, to_equal("some_new@email.org"));
        }

        {
          unchanged_results, success := execute(
            connection,
            User,
            #string SQL
              SELECT id, email FROM users WHERE id = $1
            SQL,
            user_not_to_update_id
          );
          expect(success, to_equal(true));
          expect(unchanged_results.count, to_equal(1));
          expect(unchanged_results[0].email, to_equal("some_other_user@email.org"));
        }
      });
    }
  );
});
