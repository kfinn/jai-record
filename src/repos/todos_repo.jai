Todo :: struct {
  id: int;
  user_id: int;
  description: string;
  completed_at: *string;
  created_at: string;
  updated_at: string;
}

MutableTodoFields :: struct {
  user_id: int;
  description: string;
  completed_at: *string;
  created_at: string;
  updated_at: string;
}

TodosRepo :: #run repo("todos", Todo, MutableTodoFields);

TodoBelongsToUser :: BelongsTo(
  TodosRepo,
  UsersRepo,
  "todo",
  "user",
  "user_id",
  inverse_of=HasMany(
    UsersRepo,
    TodosRepo,
    "user",
    "todos",
    "user_id"
  )
);

TodoHasManyTaggings :: HasMany(
  TodosRepo,
  TaggingsRepo,
  "todo",
  "taggings",
  "todo_id",
  inverse_of=BelongsTo(
    TaggingsRepo,
    TodosRepo,
    "tagging",
    "todo",
    "todo_id"
  )
);
