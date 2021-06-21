Todo :: struct {
  id: int;
  user_id: int;
  description: string;
  completed_at: time_t;
  created_at: time_t;
  updated_at: time_t;
}

find_todo :: #run define_finder("todos", Todo);
