users_index_json_view :: (request: *HttpRequest, users: []$T) {
  render_json(request, users, #code{
    users := it;
    json_array("users", users, #code {
      user := it;
      json_fields(user, "id", "email");
    });
  });
}
