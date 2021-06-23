TodosRepo :: #run repo(
  "todos",
  SqlSelection.{
    name="id",
    type=int,
    expression="id",
  },
  SqlSelection.{
    name="user_id",
    type=int,
    expression="user_id",
  },
  SqlSelection.{
    name="description",
    type=string,
    expression="description",
  },
  SqlSelection.{
    name="completed_at",
    type=time_t,
    expression="completed_at",
  },
  SqlSelection.{
    name="created_at",
    type=time_t,
    expression="created_at",
  },
  SqlSelection.{
    name="updated_at",
    type=time_t,
    expression="updated_at",
  }
);

TodosCreatedAfter :: SqlWhere(
  SQL_EXPRESSION="created_at > CAST(? AS TIMESTAMP)",
  ARGS_COUNT=1
);
