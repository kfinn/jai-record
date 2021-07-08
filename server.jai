#import "Basic"()(MEMORY_DEBUGGER=true);
#import "Compiler";

#run {
  server_workspace := compiler_create_workspace("server");
  if !server_workspace {
    print("Workspace creation failed.\n");
    return;
  }

  // TODO: some copypasta here from build.jai
  server_workspace_options := get_build_options();
  server_workspace_options.output_type = .NO_OUTPUT;
  import_path: [..] string;
  array_add(*import_path, ..server_workspace_options.import_path);
  array_add(*import_path, "./vendor");
  server_workspace_options.import_path = import_path;
  set_build_options(server_workspace_options, server_workspace);

  compiler_begin_intercept(server_workspace);
  add_build_file("src/main.jai", server_workspace);
  add_build_file("src/scgi/development_scgi_server.jai", server_workspace);
  add_build_string("#run development_scgi_server_run();\n", server_workspace);
  
  while true {
    message := compiler_wait_for_message();
    if !message break;
    if message.kind == .COMPLETE break;
  }

  compiler_end_intercept(server_workspace);

  build_workspace_options := get_build_options();
  build_workspace_options.output_type = .NO_OUTPUT;
  set_build_options(build_workspace_options);
};
