#run describe(
  "sql_delete.jai", 
  before_each=#code {
    connection := postgres_connection();
    execute(connection, "BEGIN");
  },
  after_each=#code {
    connection := postgres_connection();
    execute(connection, "ROLLBACK");
  },
  body=#code {
    it("delete, with a where expression, deletes matching records", #code {
        connection, postgres_connection_success := postgres_connection();
        expect(postgres_connection_success, to_equal(true));

      ExecuteInsertResult :: struct {
        id: int;
      }

      execute_insert_result, execute_insert_success := execute(
        connection,
        ExecuteInsertResult,
        #string SQL
          INSERT INTO users (email)
          VALUES
            ('test_to_delete_with_like_expression_1@gmail.com'),
            ('test_to_delete_with_like_expression_2@gmail.com'),
            ('test_not_to_delete_with_like_expression_3@gmail.com')
          RETURNING id;
        SQL
      );

      expect(execute_insert_success, to_equal(true));
      expect(execute_insert_result.count, to_equal(3));

      CountResult :: struct {
        users_count: int;
      }

      {
        count_args: struct { ids: []int; };
        ids: [3]int;
        ids[0] = execute_insert_result[0].id;
        ids[1] = execute_insert_result[1].id;
        ids[2] = execute_insert_result[2].id;
        count_args.ids = ids;

        count_result, count_success := execute(
          connection,
          CountResult,
          #string SQL
            SELECT COUNT(*) AS users_count
              FROM users
              WHERE id IN (:ids)
          SQL,
          count_args
        );

        expect(count_success, to_equal(true));
        expect(count_result.count, to_equal(1));
        expect(count_result[0].users_count, to_equal(3));
      }

      delete_where: SqlWhere("email LIKE :email_pattern", struct { email_pattern: string; });
      delete_where.email_pattern = "test_to_delete_with_like_expression%@gmail.com";

      delete_success := sql_delete_execute(
        "users",
        delete_where      
      );

      expect(delete_success, to_equal(true));

      {
        count_args: struct { ids: []int; };
        ids: [3]int;
        ids[0] = execute_insert_result[0].id;
        ids[1] = execute_insert_result[1].id;
        ids[2] = execute_insert_result[2].id;
        count_args.ids = ids;

        count_result, count_success := execute(
          connection,
          CountResult,
          #string SQL
            SELECT COUNT(*) AS users_count
              FROM users
              WHERE id IN (:ids)
          SQL,
          count_args
        );

        expect(count_success, to_equal(true));
        expect(count_result.count, to_equal(1));
        expect(count_result[0].users_count, to_equal(1));
      }
    }
  );
});
