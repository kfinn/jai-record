Todo :: #run sql_select(
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

TodosRepo :: struct {
  find :: (id: int) -> *Todo, success: bool {
    todos, sql_execute_success := sql_execute(Todo, "todos WHERE id = $1", id);
    if !sql_execute_success return null, false;
    if todos.count == 0 return null, false;

    return *todos[0], true;
  }
};
