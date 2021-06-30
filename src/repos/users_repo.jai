User :: struct {
  id: int;
  created_at: string;
  updated_at: string;
  email: string;
}

UsersRepo :: #run repo("users", User);
