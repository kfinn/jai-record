String :: #import "String";
#import "Pool";

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

execute :: (conn: *PGconn, $T: Type, command: string, args: .. Any) -> []T, success: bool {
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

#scope_file

send_query :: (conn: *PGconn, command: string, args: []Any) -> *PGresult {
	pool: Pool;
	set_allocators(*pool);
	defer release(*pool);

	new_context := context;
	new_context.allocator = pool_allocator;
	new_context.allocator_data = *pool;

	push_context new_context {
		param_values := NewArray(args.count, *u8, initialized = false);

		for arg, arg_index: args {
      encoded_arg := sprint("%", arg);
      param_values[arg_index] = to_c_string(encoded_arg);
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
        print_to_builder(*string_builder, "      %(column_type, string_value, *results[row_index].%);\n", setter_name_for_member_type(member.type), member.name);
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
    case;
      return "set_unknown_result_value";
  }
}

set_string_result_value :: (pq_type: Pq_Types, value: string, destination: *string) {
  using Pq_Types;
  assert(pq_type == CHAR || pq_type == BPCHAR || pq_type == VARCHAR || pq_type == TEXT || pq_type == TIMESTAMP, "Expected string type, got: %::%", value, pq_type);
  <<destination = value;
}

set_integer_result_value :: (pq_type: Pq_Types, value: string, destination: *$T) {
  using Pq_Types;
  assert(pq_type == INT8 || pq_type == INT2 || pq_type == INT4, "Expected int type, got: %::%", value, pq_type);
  <<destination = String.parse_int(*value, T);
}

set_float_result_value :: (pq_type: Pq_Types, value: string, destination: *$T) {
  using Pq_Types;
  assert(pq_type == FLOAT4 || pq_type == FLOAT8, "Expected float type, got: %::%", value, pq_type);
  <<destination = String.parse_float(*value, T);
}

set_unknown_result_value :: (pq_type: Pq_Types, value: string, destination: *$T) {
  log_error("Unable to parse result type: %", pq_type);
}
