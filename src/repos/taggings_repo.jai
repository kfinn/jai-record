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
  "tag_id"
);

TaggingBelongsToTodo :: BelongsTo(
  TaggingsRepo,
  TodosRepo,
  "tagging",
  "todo",
  "todo_id"
);
