#run describe("repo.jai", #code{
  describe("save", #code{
    describe(
      "with an unpersisted record",
      before_all=#code {
        connection := jai_record_pg_connection();
        execute(connection, "BEGIN");
      },
      after_all=#code {
        connection := jai_record_pg_connection();
        execute(connection, "ROLLBACK");
      },
      body=#code{
        it("inserts the user into the database and sets the user ID", #code{
          User :: struct {
            id: int;
            email: string;
          }
          TestMutableUserFields :: struct {
            email: string;
          }
          UsersRepo :: #run repo("users", User, TestMutableUserFields);

          new_user: User;
          new_user.email = "new_user_to_create@email.edu";
          expect(new_user.id, to_equal(0));
          save_result := UsersRepo.save(*new_user);
          expect(save_result, to_equal(true));
          expect(new_user.id, not(to_equal(0)));

          SelectResult :: struct {
            id: int;
            email: string;
          }
          connection := jai_record_pg_connection();
          select_results := execute(
            connection,
            SelectResult,
            "SELECT id, email FROM users WHERE id = $1",
            new_user.id
          );
          expect(select_results.count, to_equal(1));
          select_result := select_results[0];
          expect(select_result.id, to_equal(new_user.id));
          expect(select_result.email, to_equal("new_user_to_create@email.edu"));
        });
      }
    );
    describe(
      "with a persisted record",
      before_all=#code {
        connection := jai_record_pg_connection();
        execute(connection, "BEGIN");
      },
      after_all=#code {
        connection := jai_record_pg_connection();
        execute(connection, "ROLLBACK");
      },
      body=#code{
        it("updates the user in the database", #code{
          User :: struct {
            id: int;
            email: string;
          }
          TestMutableUserFields :: struct {
            email: string;
          }
          UsersRepo :: #run repo("users", User, TestMutableUserFields);

          InsertResult :: struct { id: int; }
          connection := jai_record_pg_connection();
          insert_results := execute(
            connection,
            InsertResult,
            "INSERT INTO users (email) VALUES ('existing_user@email.com') RETURNING id"
          );
          expect(insert_results.count, to_equal(1));
          user_id := insert_results[0].id;

          user := UsersRepo.find(user_id);
          expect(user.email, to_equal("existing_user@email.com"));

          user.email = "updated@email.org";
          save_result := UsersRepo.save(user);
          expect(save_result, to_equal(true));
          expect(user.email, to_equal("updated@email.org"));

          SelectResult :: struct { id: int; email: string; }
          select_results := execute(
            connection,
            SelectResult,
            "SELECT id, email FROM users WHERE id = $1",
            user_id
          );
          expect(select_results.count, to_equal(1));
          select_result := select_results[0];
          expect(select_result.id, to_equal(user_id));
          expect(select_result.email, to_equal("updated@email.org"));
        });
      }
    );
  });
});
