#import "Basic";
#import "Compiler";

#run {
  loop();

  {
    workspace_options := get_build_options();
    workspace_options.output_type = .NO_OUTPUT;
    set_build_options(workspace_options);
  }
}

loop :: () {
  while true {
    workspace := compiler_create_workspace();

    workspace_options := get_build_options();
    workspace_options.output_type = .NO_OUTPUT;
    set_build_options(workspace_options, workspace);
    
    print("created workspace: %\n", workspace);

    compiler_begin_intercept(workspace);
    add_build_string("#import \"Basic\";\n", workspace);
    add_build_string("#run print(\"handled!\\n\");\n", workspace);
    
    while true {
      message := compiler_wait_for_message();
      if message == null break;
      if message.kind == .COMPLETE break;
    }
    compiler_end_intercept(workspace);

    compiler_destroy_workspace(workspace);
    print("destroyed workspace: %\n", workspace);
  }
}
