todos_show_json_view :: (request: *HttpRequest, todo: $T) {
  render_json(request, todo, #code{
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
