#import "Pool";

User :: struct {
  id: int;
  created_at: time_t;
  updated_at: time_t;
  email: string;
};

find_user :: (id: int) -> *User, success: bool {
  FIND_USER_FORMAT_STRING :: #string SQL
    SELECT
      id,
      created_at,
      updated_at,
      email
    FROM users
    WHERE id = $1;
  SQL

  pool: Pool;
  set_allocators(*pool);
  defer reset(*pool);

  pool_context := context;
  pool_context.allocator = pool_allocator;
  pool_context.allocator_data = *pool;

  connection, jai_record_pg_connection_success := jai_record_pg_connection();
  if !jai_record_pg_connection_success return null, false;
  
  result := New(User);

  push_context pool_context {
    users, execute_success := execute(connection, User, FIND_USER_FORMAT_STRING, id);
    if !execute_success return null, false;
    if !users return null, false;
    <<result = users[0];
  }
  return result, true;
}
