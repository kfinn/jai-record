#import "Basic";
#import "Compiler";

#load "jai-spec/run.jai";

#run {
  target_workspace := compiler_create_workspace("jai-record");
  if !target_workspace {
    print("Workspace creation failed.\n");
    return;
  }

  target_workspace_options := get_build_options();
  target_workspace_options.output_type = .EXECUTABLE;
  target_workspace_options.output_executable_name = "jai-record";
  import_path: [..] string;
  array_add(*import_path, ..target_workspace_options.import_path);
  target_workspace_options.import_path = import_path;
  set_build_options(target_workspace_options, target_workspace);

  specs_run(target_workspace);

  compiler_begin_intercept(target_workspace);
  add_build_file("src/main.jai", target_workspace);
  
  while true {
    message := compiler_wait_for_message();
    if !message break;
    if message.kind == .COMPLETE break;
  }

  compiler_end_intercept(target_workspace);

  // None of the code in this file is intended to end up in an executable
  // of any kind. So, we tell the compiler not to make an executable for us:
  build_workspace_options := get_build_options();
  build_workspace_options.output_type = .NO_OUTPUT;  // No executable for the primary workspace.
  set_build_options(build_workspace_options);
};
