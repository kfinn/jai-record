#import "Basic"()(MEMORY_DEBUGGER=true);
#import "Compiler";

#load "../src/jai-spec/run.jai";

#run {
  target_workspace := compiler_create_workspace("todos");
  if !target_workspace {
    print("Workspace creation failed.\n");
    return;
  }

  target_workspace_options := get_build_options();
  target_workspace_options.output_type = .EXECUTABLE;
  target_workspace_options.output_executable_name = "todos";
  import_path: [..] string;
  array_add(*import_path, ..target_workspace_options.import_path);
  array_add(*import_path, "../vendor", "../src");
  target_workspace_options.import_path = import_path;
  set_build_options(target_workspace_options, target_workspace);

  specs_run(target_workspace, "../src/jai-spec/base.jai");

  compiler_begin_intercept(target_workspace);
  add_build_file("src/main.jai", target_workspace);

  while true {
    message := compiler_wait_for_message();
    if !message break;

    if message.kind == .COMPLETE break;
  }

  compiler_end_intercept(target_workspace);

  build_workspace_options := get_build_options();
  build_workspace_options.output_type = .NO_OUTPUT;
  set_build_options(build_workspace_options);
};
