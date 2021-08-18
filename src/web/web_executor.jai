WebExecutor :: struct {
  thread_group: Thread_Group;

  mutex: Mutex;

  allocator: Allocator;
  allocator_data: *void;
}

WebExecutorWorkBase :: struct {
  type: Type;

  perform: (web_executor_work: *WebExecutorWorkBase) -> Thread_Continue_Status;
  cleanup: (web_executor_work: *WebExecutorWorkBase) -> ();
}

init :: (using web_executor: *WebExecutor) {
  thread_group.logging = false;
  init(*thread_group, 5, web_executor_work);

  remember_allocators(web_executor);

  init(*mutex);
}

start :: (using web_executor: *WebExecutor) {
  start(*web_executor.thread_group);
}

web_executor_add_work :: (using web_executor: *WebExecutor, work: $Work) {
  push_allocator(allocator, allocator_data);
  push_lock(*mutex);

  copied_work := copy(work);
  add_work(*thread_group, copied_work);

  for get_completed_work(*thread_group) {
    completed_work := cast(*WebExecutorWorkBase)it;
    completed_work.cleanup(completed_work);
  }
}

#scope_file

web_executor_work :: (group: *Thread_Group, thread: *Thread, work: *void) -> Thread_Continue_Status {
  web_executor_work_base := cast(*WebExecutorWorkBase)work;
  web_executor_work_base.perform(web_executor_work_base);
  return .CONTINUE;
}
