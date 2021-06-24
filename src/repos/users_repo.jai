User :: struct {
  id: int;
  created_at: time_t;
  updated_at: time_t;
  email: string;
}

UsersRepo :: #run repo("users", User);
