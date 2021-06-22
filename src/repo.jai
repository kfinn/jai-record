#import "Pool";

time_t :: s64;
UUID :: string;

_CONNECTION : *PGconn;

jai_record_pg_connection :: () -> *PGconn, success: bool {
  if _CONNECTION != null return _CONNECTION, true;

  connection, success := connect("postgres://postgres:password@db:5432/postgres");

  if success {
    _CONNECTION = connection;
    return _CONNECTION, true;
  } else {
    return null, false;
  }
}

find :: ($Record: Type, $table_name: string, id: type_of(Record.id)) -> *Record, success: bool {
    query_string_builder: String_Builder;
    defer free_buffers(*query_string_builder);

    info := type_info(Record);

    print_to_builder(*query_string_builder, "SELECT\n");
    for info.members {
      print_to_builder(*query_string_builder, "  %", it.name);
      if it_index < info.members.count - 1 print_to_builder(*query_string_builder, ",");
      print_to_builder(*query_string_builder, "\n");
    }
    print_to_builder(*query_string_builder, "FROM %\n", table_name);
    print_to_builder(*query_string_builder, "WHERE id = $1\n");

    query_string := builder_to_string(*query_string_builder);

    pool: Pool;
    set_allocators(*pool);
    defer reset(*pool);

    pool_context := context;
    pool_context.allocator = pool_allocator;
    pool_context.allocator_data = *pool;

    connection, jai_record_pg_connection_success := jai_record_pg_connection();
    if !jai_record_pg_connection_success return null, false;

    result := New(Record);
    push_context pool_context {
      results, execute_success := execute(connection, Record, query_string, id);
      if !execute_success return null, false;
      if !results return null, false;
      <<result = results[0];
    }

    return result, true;
}

define_repo :: ($table_name: string, $Record: Type) -> Type {
  result :: struct {
    find :: #bake_arguments find(Record=Record, table_name=table_name);
  };
  return result;
};
