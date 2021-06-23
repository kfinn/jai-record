User :: #run sql_select(
  SqlSelection.{
    name="id",
    type=int,
    expression="id"
  },
  SqlSelection.{
    name="created_at",
    type=time_t,
    expression="created_at"
  },
  SqlSelection.{
    name="updated_at",
    type=time_t,
    expression="updated_at"
  },
  SqlSelection.{
    name="email",
    type=string,
    expression="email"
  },
);

UsersRepo :: struct {
  find :: (id: int) -> *User, success: bool {
    users, sql_execute_success := sql_execute(User, "users WHERE id = $1", id);
    if !sql_execute_success return null, false;
    if users.count == 0 return null, false;

    return *users[0], true;
  }
};
