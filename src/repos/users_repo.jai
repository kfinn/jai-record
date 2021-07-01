User :: struct {
  id: int;
  created_at: string;
  updated_at: string;
  email: string;
}

UsersRepo :: #run repo("users", User);

UserHasManyTodos :: #run has_many(
  UsersRepo,
  TodosRepo,
  "user",
  "todos",
  "user_id"
);
