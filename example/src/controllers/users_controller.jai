UsersController :: struct {
  index :: (request: *HttpRequest) {
    users := UsersRepo.all();
    users_index_json_view(request, users);
  }
}
