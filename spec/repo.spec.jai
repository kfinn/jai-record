#run describe(
  "repo.jai",
  before_each=#code{
    connection := jai_record_pg_connection();
    execute(connection, "BEGIN");
  },
  after_each=#code{
    connection := jai_record_pg_connection();
    execute(connection, "ROLLBACK");
  },
  body=#code{
    describe("save", #code{
      describe("with an unpersisted record", #code{
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
            "SELECT id, email FROM users WHERE id = :id",
            new_user
          );
          expect(select_results.count, to_equal(1));
          select_result := select_results[0];
          expect(select_result.id, to_equal(new_user.id));
          expect(select_result.email, to_equal("new_user_to_create@email.edu"));
        });
      });
      describe("with a persisted record", #code{
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
          args: struct { user_id: int; };
          args.user_id = user_id;
          select_results := execute(
            connection,
            SelectResult,
            "SELECT id, email FROM users WHERE id = :user_id",
            args
          );
          expect(select_results.count, to_equal(1));
          select_result := select_results[0];
          expect(select_result.id, to_equal(user_id));
          expect(select_result.email, to_equal("updated@email.org"));
        });
      });
    });
    describe("delete", #code{
      describe("with a persisted record", #code{
        it("deletes the record", #code{
          connection := jai_record_pg_connection();
          InsertResult :: struct { id: int; }
          insert_results := execute(
            connection,
            InsertResult,
            "INSERT INTO users (email) VALUES ('to_delete@test.edu') RETURNING id"
          );
          expect(insert_results.count, to_equal(1));
          user_id := insert_results[0].id;

          User :: struct {
            id: int;
            email: string;
          }
          TestMutableUserFields :: struct {
            email: string;
          }
          UsersRepo :: #run repo("users", User, TestMutableUserFields);

          user := UsersRepo.find(user_id);
          expect(user, to_be_present());
          expect(user.email, to_equal("to_delete@test.edu"));
          UsersRepo.delete(user);

          user = UsersRepo.find(user_id);
          expect(user, to_be_null());
        });
      });
    }
  );
});
