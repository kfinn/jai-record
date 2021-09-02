user_tags_index_json_view :: (connection_fd: s32, tags: []$T) {
  render_json(connection_fd, tags, #code{
    tags := it;
    json_array("tags", tags, #code{
      tag := it;
      json_fields(tag, "id", "description");
    });
  });
}
