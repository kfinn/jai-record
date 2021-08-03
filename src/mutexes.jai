push_lock :: (mutex: *Mutex) #expand {
  lock(mutex);
  `defer unlock(mutex);
}
