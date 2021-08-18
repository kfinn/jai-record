#import "Basic"()(MEMORY_DEBUGGER=true);
#import "Pool";

main :: () {
  pool: Pool;
  set_allocators(*pool);
  defer release(*pool);
  push_allocator(pool_allocator, *pool);
  New(u64);
}
