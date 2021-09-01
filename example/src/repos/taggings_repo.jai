Tagging :: struct {
  id: int;
  tag_id: int;
  todo_id: int;
}

TaggingsRepo :: #run repo("taggings", Tagging);

TaggingBelongsToTag :: BelongsTo(
  TaggingsRepo,
  TagsRepo,
  "tagging",
  "tag",
  "tag_id",
  inverse_of=HasMany(
    TagsRepo,
    TaggingsRepo,
    "tag",
    "taggings",
    "tag_id"
  )
);

TaggingBelongsToTodo :: BelongsTo(
  TaggingsRepo,
  TodosRepo,
  "tagging",
  "todo",
  "todo_id",
  inverse_of=HasMany(
    TodosRepo,
    TaggingsRepo,
    "todo",
    "taggings",
    "todo_id"
  )
);
