#load "libpq.jai";

connect :: (conn_str: string) -> *PGconn, success: bool {
	conn_c_str := to_c_string(conn_str);
	defer free(conn_c_str);

	conn := PQconnectStart(conn_c_str);
	if PQstatus(conn) == ConnStatusType.CONNECTION_BAD {
		log_error("Couldn’t start connecting\n");
		return conn, false;
	}

	result := PQconnectPoll(conn);
	while result != PostgresPollingStatusType.PGRES_POLLING_OK && result != PostgresPollingStatusType.PGRES_POLLING_FAILED {
		newResult := PQconnectPoll(conn);
		result = newResult;
	}

	if result == PostgresPollingStatusType.PGRES_POLLING_FAILED {
		log_error("Couldn’t connect: %\n", PQstatus(conn));
		return conn, false;
	}
	return conn, true;
}

disconnect :: (conn: *PGconn) {
	if conn {
		PQfinish(conn);
	}
};

execute :: (conn: *PGconn, command: string, args: .. Any) -> success: bool {
  query_result := send_query(conn, command, args);
	defer PQclear(query_result);

  has_results, success := check_query_result(query_result);
  if !success return false;
  return true;
}

execute :: (conn: *PGconn, $T: Type, command: string, args: ..Any) -> []T, success: bool {
	query_result := send_query(conn, command, args);
	defer PQclear(query_result);

  {
    has_results, success := check_query_result(query_result);
    if !success	return .[], false;
    if !has_results return .[], false;
  }

  results, success := get_results(query_result, T);
  return results, success;
}

execute_with_struct_args :: (conn: *PGconn, $ResultType: Type, $command: string) -> []ResultType, success: bool {
  EmptyArgs :: struct {};
  EMPTY_ARGS :: EmptyArgs.{};

  results, success := execute_with_struct_args(conn, ResultType, command, EMPTY_ARGS);
  return results, success;
}

execute_with_struct_args :: (conn: *PGconn, $ResultType: Type, $command: string, args: $ArgsType) -> []ResultType, success: bool #modify {
  if ArgsType.type != .STRUCT {
    ArgsType = null;
  }
}{
  pool: Pool;
  set_allocators(*pool);

  exec_result: *PGresult;

  {
    push_allocator(pool_allocator, *pool);

    query_builder: String_Builder;
    defer free_buffers(*query_builder);

    next_placeholder_index := 1;
    placeholder_values: [..]*u8;

    #insert #run () -> string {
      assert(type_info(ArgsType).type == .STRUCT);

      string_builder: String_Builder;
      defer free_buffers(*string_builder);

      for component: parse_command(command) {
        if component.kind == {
          case .SQL;
            print_to_builder(
              *string_builder,
              "print_to_builder(*query_builder, \"%%\", slice(command, %, %));\n",
              component.start_index,
              component.count
            );
          case .PLACEHOLDER;
            placeholder_path := slice(command, component.start_index, component.count);
            placeholder_type_info: *Type_Info = type_info(ArgsType);
            for placeholder_path_component: split(placeholder_path, ".") {
              if placeholder_type_info.type == .POINTER {
                placeholder_type_info = (cast(*Type_Info_Pointer)placeholder_type_info).pointer_to;
              }
              assert(
                placeholder_type_info.type == .STRUCT,
                "attempted to find member \"%\" in type \"%\" which is not a struct",
                placeholder_path_component,
                <<placeholder_type_info
              );
              type_info_struct := cast(*Type_Info_Struct)placeholder_type_info;
              member := find_member(placeholder_path_component, type_info_struct);
              assert(
                member != null,
                "unable to find member \"%\" in type \"%\"",
                placeholder_path_component,
                <<cast(*Type_Info_Struct)placeholder_type_info
              );
              placeholder_type_info = member.type;
            }

            if placeholder_type_info.type == .ARRAY {
              print_to_builder(*string_builder, "for arg: args.% {\n", placeholder_path);
              placeholder_array_type_info := cast(*Type_Info_Array)placeholder_type_info;
              placeholder_type_info = placeholder_array_type_info.element_type;
            } else {
              print_to_builder(*string_builder, "{\n");
              print_to_builder(*string_builder, "  arg := args.%;\n", placeholder_path);
            }

            if (placeholder_type_info.type == .POINTER) {
              print_to_builder(*string_builder, "  if arg != null {\n");
              print_to_builder(*string_builder, "    arg_value := to_c_string(sprint(\"%%\", <<arg));\n");
              print_to_builder(*string_builder, "    array_add(*placeholder_values, arg_value);\n");
              print_to_builder(*string_builder, "  } else {\n");
              print_to_builder(*string_builder, "    array_add(*placeholder_values, null);\n");
              print_to_builder(*string_builder, "  }\n");
            } else {
              print_to_builder(*string_builder, "  arg_value := to_c_string(sprint(\"%%\", arg));\n");
              print_to_builder(*string_builder, "  array_add(*placeholder_values, arg_value);\n");
            }
            print_to_builder(*string_builder, "  print_to_builder(*query_builder, \"$%% \", next_placeholder_index);\n");
            print_to_builder(*string_builder, "  next_placeholder_index += 1;\n");

            print_to_builder(*string_builder, "}\n");
        }
      }

      return builder_to_string(*string_builder);
    }();

    c_command := to_c_string(builder_to_string(*query_builder));

    exec_result = PQexecParams(
      conn,
      c_command,
      xx placeholder_values.count,
      null,
      placeholder_values.data,
      null,
      null,
      0
    );
  }

  results, success := get_results(exec_result, ResultType);
  return results, success;
}

CommandComponent :: struct {
  Kind :: enum {
    SQL;
    PLACEHOLDER;
  }

  kind: Kind;
  start_index: int;
  count: int;
}

parse_command :: (command: string) -> []CommandComponent, success: bool {
  command_components: [..]CommandComponent;

  escape_exit: string;

  current_component: CommandComponent;
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
          if remainder[0] == #char ":" {
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

#scope_file

send_query :: (conn: *PGconn, command: string, args: []Any) -> *PGresult {
	pool: Pool;
	set_allocators(*pool);

	new_context := context;
	new_context.allocator = pool_allocator;
	new_context.allocator_data = *pool;

	push_context new_context {
		param_values := NewArray(args.count, *u8, initialized = false);

		for arg, arg_index: args {
      if (
        arg.type == type_info(string) &&
        (<<cast(*string)arg.value_pointer) == "NULL"
      ) {
        param_values[arg_index] = null;
      } else {
        param_values[arg_index] = to_c_string(sprint("%", arg));
      }
		}

		c_command := to_c_string(command);

    return PQexecParams(
      conn,
      c_command,
      xx args.count,
      null,
      param_values.data,
      null,
      null,
      0
    );
	}

  return null;
}

check_query_result :: (query_result: *PGresult) -> has_results: bool, success: bool {
	res_status := PQresultStatus(query_result);
	if res_status == {
		case ExecStatusType.PGRES_EMPTY_QUERY; #through;
		case ExecStatusType.PGRES_COMMAND_OK;
			return false, true;
		case ExecStatusType.PGRES_TUPLES_OK;
			return true, true;
		case ExecStatusType.PGRES_FATAL_ERROR;
			error_message: string;
			error_message.data = PQresultErrorMessage(query_result);
			error_message.count = c_style_strlen(error_message.data);
			log_error("Fatal error: %", error_message);
			return false, false;
		case;
			log_error("Query result status: %", res_status);
			return false, false;
	}
}

get_results :: (query_result: *PGresult, $T: Type) -> []T, success: bool {
  results_count := PQntuples(query_result);
  results := NewArray(results_count, T);
  
  columns_count := PQnfields(query_result);
  for column_index: 0..columns_count - 1 {
    column_type := cast(Pq_Types)PQftype(query_result, column_index);

		column_name: string;
		column_name.data = PQfname(query_result, column_index);
		column_name.count = c_style_strlen(column_name.data);

    #insert #run () -> string {
      string_builder: String_Builder;
      defer free_buffers(*string_builder);
      
      print_to_builder(*string_builder, "if column_name == {\n");

      for member: type_info(T).members {
        print_to_builder(*string_builder, "  case \"%\";\n", member.name);
        print_to_builder(*string_builder, "    for row_index : 0..results_count - 1 {\n");
        print_to_builder(*string_builder, "      string_value := get_string_value(query_result, row_index, column_index);\n");
        print_to_builder(*string_builder, "      is_null := PQgetisnull(query_result, row_index, column_index);\n");
        print_to_builder(*string_builder, "      %(column_type, string_value, xx is_null, *results[row_index].%);\n", setter_name_for_member_type(member.type), member.name);
        print_to_builder(*string_builder, "    }\n");
      }

      print_to_builder(*string_builder, "  case;\n");
      print_to_builder(*string_builder, "    log_error(\"Unknown column name in query result: %\", column_name);\n", "%");
      print_to_builder(*string_builder, "}\n");

      return builder_to_string(*string_builder);
    }();
  }

  return results, true;
}

get_string_value :: (query_result: *PGresult, row_index: s32, column_index: s32) -> string {
  string_value: string;
  string_value.data = PQgetvalue(query_result, row_index, column_index);
  string_value.count = PQgetlength(query_result, row_index, column_index);
  return copy_string(string_value);
}

setter_name_for_member_type :: (member_type_info: *Type_Info) -> string {
  if member_type_info.type == {
    case .INTEGER;
      return "set_integer_result_value";
    case .FLOAT;
      return "set_float_result_value";
    case .STRING;
      return "set_string_result_value";
    case .POINTER;
      pointer_to := (cast(*Type_Info_Pointer)member_type_info).pointer_to;
      if pointer_to.type == {
        case .INTEGER;
          return "set_integer_pointer_result_value";
        case .FLOAT;
          return "set_float_pointer_result_value";
        case .STRING;
          return "set_string_pointer_result_value";
      }
    case;
      return "set_unknown_result_value";
  }
}

set_string_result_value :: (pq_type: Pq_Types, value: string, is_null: bool, destination: *string) {
  using Pq_Types;
  assert(pq_type == CHAR || pq_type == BPCHAR || pq_type == VARCHAR || pq_type == TEXT || pq_type == TIMESTAMP, "Expected string type, got: %::%", value, pq_type);
  assert(!is_null, "expected non-null value, got null");
  <<destination = value;
}

set_integer_result_value :: (pq_type: Pq_Types, value: string, is_null: bool, destination: *$T) {
  using Pq_Types;
  assert(pq_type == INT8 || pq_type == INT2 || pq_type == INT4, "Expected int type, got: %::%", value, pq_type);
  assert(!is_null, "expected non-null value, got null");
  <<destination = parse_int(*value, T);
}

set_float_result_value :: (pq_type: Pq_Types, value: string, is_null: bool, destination: *$T) {
  using Pq_Types;
  assert(pq_type == FLOAT4 || pq_type == FLOAT8, "Expected float type, got: %::%", value, pq_type);
  assert(!is_null, "expected non-null value, got null");
  <<destination = parse_float(*value, T);
}

set_string_pointer_result_value :: (pq_type: Pq_Types, value: string, is_null: bool, destination: **string) {
  using Pq_Types;
  assert(pq_type == CHAR || pq_type == BPCHAR || pq_type == VARCHAR || pq_type == TEXT || pq_type == TIMESTAMP, "Expected string type, got: %::%", value, pq_type);
  if is_null {
    <<destination = null;
  } else {
    <<destination = New(string);
    << <<destination = value;
  }
}

set_integer_pointer_result_value :: (pq_type: Pq_Types, value: string, is_null: bool, destination: **$T) {
  using Pq_Types;
  assert(pq_type == INT8 || pq_type == INT2 || pq_type == INT4, "Expected int type, got: %::%", value, pq_type);
  if (is_null) {
    <<destination = null;
  } else {
    <<destination = New(T);
    << <<destination = parse_int(*value, T);
  }
}

set_float_pointer_result_value :: (pq_type: Pq_Types, value: string, is_null: bool, destination: **$T) {
  using Pq_Types;
  assert(pq_type == FLOAT4 || pq_type == FLOAT8, "Expected float type, got: %::%", value, pq_type);
  if (is_null) {
    <<destination = null;
  } else {
    <<destination = New(T);
    << <<destination = parse_float(*value, T);
  }
}

set_unknown_result_value :: (pq_type: Pq_Types, value: string, destination: *$T) {
  log_error("Unable to parse result type: %", pq_type);
}
