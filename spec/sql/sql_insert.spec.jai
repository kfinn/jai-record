#run describe("sql_insert.jai", #code{
  describe("sql_insert", #code{
    describe("SQL_EXPRESSION", #code{
      it("includes value expressions for all fields in the insert type", #code{
        TestInsert :: #run sql_insert(struct {
          height: float;
          nickname: string;
          favorite_ice_cream_flavor_id: int;
        }, int);

        expect(
          TestInsert.SQL_EXPRESSION,
          to_equal(
            "(height, nickname, favorite_ice_cream_flavor_id) VALUES ($1, $2, $3)"
          )
        );
      });
    });

    describe("to_sql_insert_args", #code{
      it("includes all values from the insert", #code{
        TestInsert :: #run sql_insert(struct {
          height: float;
          nickname: string;
          favorite_ice_cream_flavor_id: int;
        }, int);

        test_insert: TestInsert;
        test_insert.height = 2.1;
        test_insert.nickname = "Jamesy";
        test_insert.favorite_ice_cream_flavor_id = 543;

        sql_insert_args := TestInsert.to_sql_insert_args(*test_insert);
        expect(<<(cast(*float) sql_insert_args[0].value_pointer), to_equal(2.1));
        expect(<<(cast(*string) sql_insert_args[1].value_pointer), to_equal("Jamesy"));
        expect(<<(cast(*int) sql_insert_args[2].value_pointer), to_equal(543));
      });
    });
  });

  describe(
    "sql_insert_execute",
    before_all=#code {
      connection := jai_record_pg_connection();
      execute(connection, "BEGIN");
    },
    after_all=#code {
      connection := jai_record_pg_connection();
      execute(connection, "ROLLBACK");
    },
    body=#code{
      connection := jai_record_pg_connection();

      TestUserInsert :: #run sql_insert(struct {
        email: string;
      }, int);

      test_user_to_insert: TestUserInsert;
      test_user_to_insert.email = "some@email.gov";

      inserted_id, execute_success := sql_insert_execute("users", *test_user_to_insert);
      expect(execute_success, to_equal(true));

      User :: struct {
        id: int;
        email: string;
      }

      users, users_success := execute(
        connection,
        User,
        "SELECT id, email FROM users WHERE id = $1",
        inserted_id
      );
      expect(users_success, to_equal(true));
      expect(users.count, to_equal(1));
      user := users[0];
      expect(user.id, to_equal(inserted_id));
      expect(user.email, to_equal("some@email.gov"));
    }
  );
});
