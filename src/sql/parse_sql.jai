SQL_PLACEHOLDER_PREFIX :: ":";

SqlComponent :: struct {
  Kind :: enum {
    SQL;
    PLACEHOLDER;
  }

  kind: Kind;
  start_index: int;
  count: int;
}

parse_sql :: (command: string) -> []SqlComponent, success: bool {
  command_components: [..]SqlComponent;

  escape_exit: string;

  current_component: SqlComponent;
  current_component.kind = .SQL;
  current_component.start_index = 0;

  for index: 0..command.count - 1 {
    remainder := slice(command, index, command.count - index);
    if current_component.kind == {
      case .SQL;
        if escape_exit {
          if begins_with(remainder, escape_exit) {
            escape_exit = "";
          }
        } else {
          if begins_with(remainder, SQL_PLACEHOLDER_PREFIX) {
            current_component.count = index - current_component.start_index;
            array_add(*command_components, current_component);

            current_component.kind = .PLACEHOLDER;
            current_component.start_index = index + 1;
          } else if begins_with(remainder, "\"") {
            escape_exit = "\"";
          } else if begins_with(remainder, "'") {
            escape_exit = "'";
          } else if begins_with(remainder, "--") {
            escape_exit = "\n";
          } else if begins_with(remainder, "/*") {
            escape_exit = "*/";
          }
        }
      case .PLACEHOLDER;
        if !is_placeholder_character(remainder[0]) {
          current_component.count = index - current_component.start_index;
          array_add(*command_components, current_component);

          current_component.kind = .SQL;
          current_component.start_index = index;
        }
    }
  }
  current_component.count = command.count - current_component.start_index;
  array_add(*command_components, current_component);
  return command_components, true;
}

is_placeholder_character :: (character: u8) -> bool {
  return (
    (character >= #char "a" && character <= #char "z") ||
    (character >= #char "A" && character <= #char "Z") ||
    (character >= #char "0" && character <= #char "9") ||
    character == #char "_" ||
    character == #char "."
  );
}
