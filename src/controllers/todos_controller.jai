TodosController :: struct {
  index :: () -> string {
    return "this is rendered from todos";
  }
}; @Resource(/todos)

UsersController :: struct {
  index :: () -> string {
    return "this is a new route";
  }
}; @Resource(/users)
