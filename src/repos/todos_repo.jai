Todo :: struct {
  id: int;
  user_id: int;
  description: string;
  completed_at: time_t;
  created_at: time_t;
  updated_at: time_t;
}

TodosRepo :: #run repo("todos", Todo);

TodosCreatedAfter :: SqlWhere(
  SQL_EXPRESSION="created_at > CAST(? AS TIMESTAMP)",
  ARGS_COUNT=1
);
