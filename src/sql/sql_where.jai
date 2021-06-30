sql_where_to_string :: (where: *$T/SqlWhere) -> string {
  if where == null return "";
  return #run static_sql_where_to_string(T);
}

sql_where_to_string :: (where: *$T/SqlWhereAnd) -> string {
  if where == null return "";
  return #run static_sql_where_to_string(T);
}

DefaultSqlWhere :: SqlWhere("", 0);
DefautlSqlWhereAnd :: SqlWhereAnd(DefaultSqlWhere, DefaultSqlWhere, 0);

static_sql_where_to_string :: ($Where: Type) -> string {
  #if #run type_info(Where).type != .STRUCT {
    return "";
  }

  #if #run (cast(*Type_Info_Struct)type_info(Where)).polymorph_source_struct == type_info(DefaultSqlWhere).polymorph_source_struct {
    return Where.SQL_EXPRESSION;
  }
  #if #run (cast(*Type_Info_Struct)type_info(Where)).polymorph_source_struct == type_info(DefautlSqlWhereAnd).polymorph_source_struct {
    return sprint(
      "((%) AND (%))",
      static_sql_where_to_string(Where.LhsSqlWhere),
      static_sql_where_to_string(Where.RhsSqlWhere)
    );
  }
  
  return "";
}

SqlWhere :: struct(SQL_EXPRESSION: string, ARGS_COUNT: int) {
  args: [ARGS_COUNT]Any;
}

SqlWhereAnd :: struct(LhsSqlWhere: Type, RhsSqlWhere: Type, ARGS_COUNT: int) {
  args: [ARGS_COUNT]Any;
}

sql_where_and :: (lhs: *$LhsSqlWhere, rhs: *$RhsSqlWhere) -> SqlWhereAnd(LhsSqlWhere, RhsSqlWhere, LhsSqlWhere.ARGS_COUNT + RhsSqlWhere.ARGS_COUNT) {
  result: SqlWhereAnd(LhsSqlWhere, RhsSqlWhere, LhsSqlWhere.ARGS_COUNT + RhsSqlWhere.ARGS_COUNT);
  for lhs.args result.args[it_index] = it;
  for rhs.args result.args[it_index + lhs.ARGS_COUNT] = it;

  return result;
}
