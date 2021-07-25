#run describe("sql_select.jai", #code{
  describe("sql_select", #code{
    describe("SQL_EXPRESSION", #code{
      it("escapes and joins all the struct fields", #code{
        TestSelect :: #run sql_select(struct {
          id: int;
          email: string;
          full_name: string; @SqlExpression(first_name||'-'||last_name)
        });

        expect(
          TestSelect.SQL_EXPRESSION,
          to_equal(
            "\"id\", \"email\", (first_name||'-'||last_name) as \"full_name\""
          )
        );
      });
    });
  });

  describe(
    "sql_select_execute",
    before_each=#code {
      connection := jai_record_pg_connection();
      execute(connection, "BEGIN");
    },
    after_each=#code {
      connection := jai_record_pg_connection();
      execute(connection, "ROLLBACK");
    },
    body=#code{
      it("executes the SQL SELECT", #code{
        connection := jai_record_pg_connection();

        execute(
          connection,
          #string SQL
            INSERT INTO users
              (email)
            VALUES
              ('sql_select.spec_1@First_email.com'),
              ('sql_select.spec_2@SECOND_email.com'),
              ('sql_select.spec_3@ThIrD_email.com')
          SQL
        );

        SelectUserWithUppercaseEmail :: #run sql_select(struct {
          user_id: int; @SqlExpression(users.id)
          uppercase_email: string; @SqlExpression(upper(users.email))
        });

        WithEmailPattern :: SqlWhere("email LIKE :email_pattern", struct { email_pattern: string; });
        with_sql_select_spec_email_prefix: WithEmailPattern;
        with_sql_select_spec_email_prefix.email_pattern = "sql_select.spec_%@%_email.com";

        selected_users, success := sql_select_execute(
          SelectUserWithUppercaseEmail,
          "users",
          with_sql_select_spec_email_prefix
        );

        expect(success, to_equal(true));

        actual_uppercase_emails: [..]string;
        for selected_users array_add(*actual_uppercase_emails, it.uppercase_email);

        expect(
          actual_uppercase_emails,
          to_contain_exactly(
            "SQL_SELECT.SPEC_1@FIRST_EMAIL.COM",
            "SQL_SELECT.SPEC_2@SECOND_EMAIL.COM",
            "SQL_SELECT.SPEC_3@THIRD_EMAIL.COM",
          )
        );
      });
    }
  );
});
