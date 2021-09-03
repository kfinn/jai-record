user_tags_index_json_view :: (request: *HttpRequest, tags: []$T) {
  render_json(request, tags, #code{
    tags := it;
    json_array("tags", tags, #code{
      tag := it;
      json_fields(tag, "id", "description");
    });
  });
}
