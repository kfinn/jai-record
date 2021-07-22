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
            "(height, nickname, favorite_ice_cream_flavor_id) VALUES (:height, :nickname, :favorite_ice_cream_flavor_id)"
          )
        );
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

      inserted_id, execute_success := sql_insert_execute("users", test_user_to_insert);
      expect(execute_success, to_equal(true));

      User :: struct {
        id: int;
        email: string;
      }

      args: struct { id: int; };
      args.id = inserted_id;

      users, users_success := execute(
        connection,
        User,
        "SELECT id, email FROM users WHERE id = :id",
        args
      );
      expect(users_success, to_equal(true));
      expect(users.count, to_equal(1));
      user := users[0];
      expect(user.id, to_equal(inserted_id));
      expect(user.email, to_equal("some@email.gov"));
    }
  );
});
