Todo :: struct {
  id: int;
  user_id: int;
  description: string;
  completed_at: string;
  created_at: string;
  updated_at: string;
}

TodosRepo :: #run repo("todos", Todo);

TodosCreatedAfter :: SqlWhere(
  SQL_EXPRESSION="created_at > CAST(? AS TIMESTAMP)",
  ARGS_COUNT=1
);
