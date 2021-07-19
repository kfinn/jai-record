EmptySqlWhere :: struct {
  to_string :: () -> string { return ""; };
  args :: Any.[];
};

SqlWhere :: struct(SQL_EXPRESSION: string, ARGS_COUNT: int) {
  to_string :: () ->  string {
    return SQL_EXPRESSION;
  };
  args: [ARGS_COUNT]Any;
}

SqlWhereAnd :: struct(LhsSqlWhere: Type, RhsSqlWhere: Type, ARGS_COUNT: int) {
  to_string :: () -> string {
    return sprint(
      "(%) AND (%)",
      LhsSqlWhere.to_string(),
      RhsSqlWhere.to_string()
    );
  };
  args: [ARGS_COUNT]Any;
}

sql_where_and :: (lhs: *$LhsSqlWhere, rhs: *$RhsSqlWhere) -> SqlWhereAnd(LhsSqlWhere, RhsSqlWhere, LhsSqlWhere.ARGS_COUNT + RhsSqlWhere.ARGS_COUNT) {
  result: SqlWhereAnd(LhsSqlWhere, RhsSqlWhere, LhsSqlWhere.ARGS_COUNT + RhsSqlWhere.ARGS_COUNT);
  for lhs.args result.args[it_index] = it;
  for rhs.args result.args[it_index + lhs.ARGS_COUNT] = it;

  return result;
}
