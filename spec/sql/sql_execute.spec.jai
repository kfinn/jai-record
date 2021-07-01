#run describe("sql_execute.jai", #code{
  describe("prepare_sql_placeholders_for_args_test", #code{
    it("replaces ? placeholders with scalar args with indexed $1 placeholders", #code{
      test_sql_with_placeholders := "id = ? AND another_thing = ? AND some_id = ?";

      args: [3]Any;
      args[0] = 1;
      args[1] = 2;
      args[2] = 3;

      prepared_sql, prepared_args := prepare_sql_placeholders_for_args(test_sql_with_placeholders, args);

      expect(prepared_sql, to_equal("id = $1 AND another_thing = $2 AND some_id = $3"));
      expect(<<(cast(*int)prepared_args[0].value_pointer), to_equal(1));
      expect(<<(cast(*int)prepared_args[1].value_pointer), to_equal(2));
      expect(<<(cast(*int)prepared_args[2].value_pointer), to_equal(3));
    });

    it("replaces ? placeholdres with array args with multiple indexed $1 placeholders", #code{
      test_sql_with_placeholders := "id IN (?) AND something_else IN (?)";

      id_args: [..]Any;
      array_add(*id_args, 1);
      array_add(*id_args, 2);

      something_else_args: [..]Any;
      array_add(*something_else_args, 3);
      array_add(*something_else_args, 4);
      array_add(*something_else_args, 5);

      nested_args: [..]Any;
      array_add(*nested_args, id_args);
      array_add(*nested_args, something_else_args);

      prepared_sql, prepared_args := prepare_sql_placeholders_for_args(test_sql_with_placeholders, nested_args);
      expect(prepared_sql, to_equal("id IN ($1, $2) AND something_else IN ($3, $4, $5)"));
      expect(<<(cast(*int)prepared_args[0].value_pointer), to_equal(1));
      expect(<<(cast(*int)prepared_args[1].value_pointer), to_equal(2));
      expect(<<(cast(*int)prepared_args[2].value_pointer), to_equal(3));
      expect(<<(cast(*int)prepared_args[3].value_pointer), to_equal(4));
      expect(<<(cast(*int)prepared_args[4].value_pointer), to_equal(5));
    });
  });
});
