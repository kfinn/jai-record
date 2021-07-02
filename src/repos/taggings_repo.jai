Tagging :: struct {
  id: int;
  tag_id: int;
  todo_id: int;
}

TaggingsRepo :: #run repo("taggings", Tagging);

TaggingBelongsToTag :: #run belongs_to(
  TaggingsRepo,
  TagsRepo,
  "tagging",
  "tag",
  "tag_id"
);

TaggingBelongsToTodo :: #run belongs_to(
  TaggingsRepo,
  TodosRepo,
  "tagging",
  "todo",
  "todo_id"
);
