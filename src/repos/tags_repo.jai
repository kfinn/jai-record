Tag :: struct {
  id: int;
  description: string;
  user_id: int;
}

TagsRepo :: #run repo("tags", Tag);

TagHasManyTaggings :: HasMany(
  TagsRepo,
  TaggingsRepo,
  "tag",
  "taggings",
  "tag_id",
  inverse_of=BelongsTo(
    TaggingsRepo,
    TagsRepo,
    "tagging",
    "tag",
    "tag_id"
  )
);
