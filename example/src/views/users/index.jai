users_index_json_view :: (connection_fd: s32, users: []$T) {
  render_json(connection_fd, users, #code{
    users := it;
    json_array("users", users, #code {
      user := it;
      json_fields(user, "id", "email");
    });
  });
}
