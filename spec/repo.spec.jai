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

          found_user := UsersRepo.find(new_user.id);
          expect(found_user.email, to_equal("new_user_to_create@email.edu"));
        });
      }
    );
  });
});
