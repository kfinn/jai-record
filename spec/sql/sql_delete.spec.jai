#run describe(
  "sql_delete.jai", 
  before_all=#code {
    connection := jai_record_pg_connection();
    execute(connection, "BEGIN");
  },
  after_all=#code {
    connection := jai_record_pg_connection();
    execute(connection, "ROLLBACK");
  },
  body=#code {
    it("delete, with a where expression, deletes matching records", #code {
        connection, jai_record_pg_connection_success := jai_record_pg_connection();
        expect(jai_record_pg_connection_success, to_equal(true));

      ExecuteInsertResult :: struct {
        id: int;
      }

      execute_insert_result, execute_insert_success := execute_with_struct_args(
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
        count_result, count_success := execute(
          connection,
          CountResult,
          #string SQL
            SELECT COUNT(*) AS users_count
              FROM users
              WHERE id IN ($1, $2, $3)
          SQL,
          execute_insert_result[0].id,
          execute_insert_result[1].id,
          execute_insert_result[2].id
        );

        expect(count_success, to_equal(true));
        expect(count_result.count, to_equal(1));
        expect(count_result[0].users_count, to_equal(3));
      }

      delete_where: SqlWhere("email LIKE ?", 1);
      delete_where.args[0] = "test_to_delete_with_like_expression%@gmail.com";

      delete_success := sql_delete_execute(
        "users",
        *delete_where      
      );

      expect(delete_success, to_equal(true));

      {
        count_result, count_success := execute(
          connection,
          CountResult,
          #string SQL
            SELECT COUNT(*) AS users_count
              FROM users
              WHERE id IN ($1, $2, $3)
          SQL,
          execute_insert_result[0].id,
          execute_insert_result[1].id,
          execute_insert_result[2].id
        );

        expect(count_success, to_equal(true));
        expect(count_result.count, to_equal(1));
        expect(count_result[0].users_count, to_equal(1));
      }
    }
  );
});
