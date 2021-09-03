UserTagsController :: struct {
  index :: (request: *HttpRequest, user_id: string) {
    with_user: SqlWhere("id = :id", struct { id: string; });
    with_user.id = user_id;

    users_with_tags := preload(
      UserHasManyTags,
      UsersRepo.where(with_user)
    );
    if users_with_tags.count != 1 {
      print("rendering not found error for users_with_tags: %\n", users_with_tags);
      render_error(request, .NOT_FOUND);
      return;
    }
    
    user_tags_index_json_view(request, users_with_tags[0].tags);
  }
};
