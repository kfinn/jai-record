UserTagsController :: struct {
  index :: (request: HttpRequest, user_id: string) {
    response_builder: String_Builder;
    defer free_buffers(*response_builder);

    user := UsersRepo.find(user_id);

    print_to_builder(*response_builder, "user[%]: %\n\n", user.id, user.email);

    with_user: SqlWhere("user_id = :id", struct { id: int; });
    with_user.id = user.id;
    for tag: TagsRepo.where(with_user) {
      print_to_builder(*response_builder, "  tag: %\n", tag.description);
    }

    response_body := builder_to_string(*response_builder);
    response := sprint("HTTP/1.1 200 OK\r\nContent-Type: text/plain\r\n\r\n%", response_body);
    bytes_written := write(request.connection_fd, response);
    assert(bytes_written == response.count);
  }
};
