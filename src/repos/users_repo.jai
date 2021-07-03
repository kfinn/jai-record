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
  inverse_of=BelongsTo(
    TodosRepo,
    UsersRepo,
    "todo",
    "user",
    "user_id"
  )
);

UserHasManyTags :: HasMany(
  UsersRepo,
  TagsRepo,
  "user",
  "tags",
  "user_id",
  inverse_of=BelongsTo(
    TagsRepo,
    UsersRepo,
    "tag",
    "user",
    "user_id",
  )
);
