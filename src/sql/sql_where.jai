EmptySqlWhere :: struct {
  to_string :: () -> string { return ""; };
  args :: Any.[];
};

SqlWhere :: struct(SQL_EXPRESSION: string, Args: Type = struct {}) {
  to_string :: () ->  string {
    return SQL_EXPRESSION;
  };
  using args: Args;
}

SqlWhereAnd :: struct(LhsSqlWhere: Type, RhsSqlWhere: Type) {
  to_string :: () -> string {
    string_builder: String_Builder;
    defer free_buffers(*string_builder);

    print_to_builder(*string_builder, "(");

    lhs_string := LhsSqlWhere.to_string();
    for lhs_component: parse_sql(lhs_string) {
      component_string := slice(lhs_string, lhs_component.start_index, lhs_component.count);
      if #complete lhs_component.kind == {
        case .SQL;
          print_to_builder(
            *string_builder,
            "%",
            component_string
          );
        case .PLACEHOLDER;
          print_to_builder(
            *string_builder,
            "%lhs.%",
            SQL_PLACEHOLDER_PREFIX,
            component_string
          );
      }
    }

    print_to_builder(*string_builder, ") AND (");

    rhs_string := RhsSqlWhere.to_string();
    for rhs_component: parse_sql(rhs_string) {
      component_string := slice(rhs_string, rhs_component.start_index, rhs_component.count);
      if #complete rhs_component.kind == {
        case .SQL;
          print_to_builder(
            *string_builder,
            "%",
            component_string
          );
        case .PLACEHOLDER;
          print_to_builder(
            *string_builder,
            "%rhs.%",
            SQL_PLACEHOLDER_PREFIX,
            component_string
          );
      }
    }

    print_to_builder(*string_builder, ")");
    return builder_to_string(*string_builder);
  };
  lhs: *LhsSqlWhere;
  rhs: *RhsSqlWhere;
}

sql_where_and :: (lhs: *$LhsSqlWhere, rhs: *$RhsSqlWhere) -> SqlWhereAnd(LhsSqlWhere, RhsSqlWhere) {
  result: SqlWhereAnd(LhsSqlWhere, RhsSqlWhere);
  result.lhs = lhs;
  result.rhs = rhs;

  return result;
}
