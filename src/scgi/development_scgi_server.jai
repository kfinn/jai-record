#import "Compiler";
#import "Pool";

development_scgi_server_run :: () {
  scgi_server_run(development_handle);
}

development_handle :: (connection_fd: s32) {
  pool: Pool;
  set_allocators(*pool);
  defer reset(*pool);

  {
    push_allocator(pool_allocator, *pool);
    handle_workspace := compiler_create_workspace();
    print("created handle_workspace %\n", handle_workspace);

    // TODO: clean up this copypasta from build.jai and server.jai
    handle_workspace_options := get_build_options();
    handle_workspace_options.output_type = .NO_OUTPUT;

    set_build_options(handle_workspace_options, handle_workspace);

    compiler_begin_intercept(handle_workspace);
    add_build_file("src/main.jai", handle_workspace);

    handle_build_string := sprint("#run default_handle(%);\n", connection_fd);
    add_build_string(handle_build_string, handle_workspace);

    while true {
      message := compiler_wait_for_message();
      if !message break;

      if message.kind == .COMPLETE break;
      if message.kind == .ERROR {
        print("compiler error: %\n", message);
        close(connection_fd);
        compiler_set_workspace_status(.OK, handle_workspace);
        break;
      }
    }
    compiler_end_intercept(handle_workspace);

    compiler_destroy_workspace(handle_workspace);
  }
}
