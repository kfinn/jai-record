User :: struct {
  id: int;
  created_at: string;
  updated_at: string;
  email: string;
}

UsersRepo :: #run repo("users", User);

UserHasManyTodos :: HasMany(
  UsersRepo,
  TodosRepo,
  "user",
  "todos",
  "user_id",
  inverse_of=TodoBelongsToUser
);

UserHasManyTags :: HasMany(
  UsersRepo,
  TagsRepo,
  "user",
  "tags",
  "user_id"
);
