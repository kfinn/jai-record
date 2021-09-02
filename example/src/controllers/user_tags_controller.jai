UserTagsController :: struct {
  index :: (request: HttpRequest, user_id: string) {
    with_user: SqlWhere("user_id = :id", struct { id: string; });
    with_user.id = user_id;
    tags := TagsRepo.where(with_user);

    write(
      request.connection_fd,
      "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nAccess-Control-Allow-Origin: http://localhost:3000\r\n\r\n"
    );
    user_tags_index_json_view(request.connection_fd, tags);
  }
};
