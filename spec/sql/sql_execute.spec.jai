#run describe("sql_execute.jai", #code{
  describe("prepare_sql_placeholders_for_args_test", #code{
    it("replaces ? placeholders with indexed $1 placeholders", #code{
      test_sql_with_placeholders := "id = ? AND another_thing = ? AND some_id = ?";

      expect(
        prepare_sql_placeholders_for_args(test_sql_with_placeholders),
        to_equal("id = $1 AND another_thing = $2 AND some_id = $3")
      );
    });
  });
});
