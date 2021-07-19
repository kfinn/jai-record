#import "File_Utilities";

SPEC_FILE_SUFFIX :: ".spec.jai";

specs_run :: (workspace_under_test: Workspace) {
  specs_workspace_name := sprint("%_specs", get_name(workspace_under_test));

  specs_workspace := compiler_create_workspace(specs_workspace_name);
  specs_workspace_options := get_build_options(workspace_under_test);
  specs_workspace_options.output_type = .NO_OUTPUT;
  set_build_options(specs_workspace_options, specs_workspace);
  
  compiler_begin_intercept(specs_workspace);

  add_build_file("src/main.jai", specs_workspace);
  add_build_file("jai-spec/base.jai", specs_workspace);

  files := file_list(
    "./spec",
    recursive=true,
    follow_symlinks=false
  );

  for file: files {
    if file.count <= SPEC_FILE_SUFFIX.count continue;
    pre_suffix_filename_length := file.count - SPEC_FILE_SUFFIX.count;
    for suffix_character_index: 0..SPEC_FILE_SUFFIX.count - 1 {
      suffix_character := SPEC_FILE_SUFFIX[suffix_character_index];
      actual_file_suffix_character := file[
        suffix_character_index + pre_suffix_filename_length
      ];
      if suffix_character != actual_file_suffix_character continue file;
    }
    add_build_file(file, specs_workspace);
  }

  specs_verified := false;

  while true {
    message := compiler_wait_for_message();
    if !message break;

    if message.kind == {
      case .ERROR;
        compiler_report("Tests failed");
      case .COMPLETE;
        break;
      case .PHASE;
        phase_message := cast(*Message_Phase)message;
        if phase_message.phase == .TYPECHECKED_ALL_WE_CAN && !specs_verified {
          specs_verified = true;
          add_build_string("#run specs_verify();", specs_workspace);
        }
    }
  }
  compiler_end_intercept(specs_workspace);
};
