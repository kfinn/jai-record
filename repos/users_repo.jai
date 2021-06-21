User :: struct {
  id: int;
  created_at: time_t;
  updated_at: time_t;
  email: string;
};

find_user :: #run define_finder("users", User);
