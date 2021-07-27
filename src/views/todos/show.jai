todos_show_json_view :: (connection_fd: s32, todo: $T) {
  render_json(connection_fd, todo, #code{
    todo := it;
    json_object("todo", todo, #code{
      json_fields(todo, "id", "description", "completed_at");
      json_array("taggings", todo.taggings, #code{
        tagging := it;
        json_object("tag", tagging.tag, #code{
          json_fields(tag, "id", "description");
        });
      });
    });
  });
}
