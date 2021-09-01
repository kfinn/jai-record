#run describe("sql_udpate.jai", #code{
  describe("sql_update", #code{
    describe("SQL_EXPRESSION", #code {
      it("includes set expressions for all fields in the update type", #code{
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
            "email=:email, pets_count=:pets_count, favorite_pet_id=:favorite_pet_id, born_at=:born_at, percent_complete=:percent_complete"
          )
        );
      });
    });
  });

  describe(
    "sql_update_execute",
    before_each=#code {
      connection := postgres_connection();
      execute(connection, "BEGIN");
    },
    after_each=#code {
      connection := postgres_connection();
      execute(connection, "ROLLBACK");
    },
    body=#code {
      it("updates records in the database", #code {
        connection, postgres_connection_success := postgres_connection();
        expect(postgres_connection_success, to_equal(true));

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

        user_to_update := execute_insert_result[0];
        user_not_to_update := execute_insert_result[1];

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

        with_id: SqlWhere("id = :id", struct { id: int; });
        with_id.id = user_to_update.id;

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
              SELECT id, email FROM users WHERE id = :id
            SQL,
            user_to_update
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
              SELECT id, email FROM users WHERE id = :id
            SQL,
            user_not_to_update
          );
          expect(success, to_equal(true));
          expect(unchanged_results.count, to_equal(1));
          expect(unchanged_results[0].email, to_equal("some_other_user@email.org"));
        }
      });
    }
  );
});
