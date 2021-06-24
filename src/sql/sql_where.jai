SqlWhere :: struct($SQL_EXPRESSION: string, ARGS_COUNT: int) {
  args: [ARGS_COUNT]Any;
}

// derived_sql_where_type :: ($LhsSqlWhere: Type, $RhsSqlWhere: Type) -> Type {
//   return SqlWhere(
//     SQL_EXPRESSION=sprint("((%) AND (%))", LhsSqlWhere.SQL_EXPRESSION, RhsSqlWhere.SQL_EXPRESSION),
//     ARGS_COUNT=(LhsSqlWhere.ARGS_COUNT + RhsSqlWhere.ARGS_COUNT)
//   );
// }

// and :: (lhs: *$LhsSqlWhere, rhs: *$RhsSqlWhere) -> derived_sql_where_type(LhsSqlWhere, RhsSqlWhere) {
//   result: derived_sql_where_type(LhsSqlWhere, RhsSqlWhere);
//   for lhs.args result.args[it_index] = it;
//   for rhs.args result.args[it_index + lhs.ARGS_COUNT] = it;

//   return result;
// }

// and_test :: () {
//   with_id: SqlWhere(SQL_EXPRESSION="id = ?", ARGS_COUNT=1);
//   with_id.args[0] = 1;

//   between_dates: SqlWhere(SQL_EXPRESSION="created_at BETWEEN ? AND ?", ARGS_COUNT=2);
//   between_dates.args[0] = "2020-01-01";
//   between_dates.args[1] = "2021-01-01";

//   result := and(*with_id, *between_dates);

//   assert_equals("((id = ?) AND (created_at BETWEEN ? AND ?)))", result.SQL_EXPRESSION);
//   assert_equals(result.ARGS_COUNT, 3);
//   assert_equals(result.args[0].type, type_info(type_of(1)));
//   assert_equals(<<(cast(*int) result.args[0].value_pointer), 1);
//   assert_equals(result.args[1].type, type_info(type_of("2020-01-01")));
//   assert_equals(<<(cast(*string) result.args[1].value_pointer), "2020-01-01");
//   assert_equals(result.args[2].type, type_info(type_of("2021-01-01")));
//   assert_equals(<<(cast(*string) result.args[0].value_pointer), "2021-01-01");
// } @Test;
