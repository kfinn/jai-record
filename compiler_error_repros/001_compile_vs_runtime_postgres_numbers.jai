#import "Basic";

#load "/vendor/jai-postgres/module.jai";

get_connection :: () -> *PGconn, success: bool {
  connection, success := connect("postgres://postgres:password@db:5432/postgres");
  if success {
    return connection, true;
  } else {
    return null, false;
  }
}

Result :: struct {
  id: int;
};

look_up_some_number :: (query: string, args: ..Any) -> int {
  connection := get_connection();
  defer disconnect(connection);

  values: string;
  if args.count > 0 {
    values_builder: String_Builder;
    defer free_buffers(*values_builder);

    print_to_builder(*values_builder, "[");
    for args {
      print_to_builder(*values_builder, "%", it);
      if it_index < args.count - 1 print_to_builder(*values_builder, ", ");
    }
    print_to_builder(*values_builder, "]");
    values = builder_to_string(*values_builder);
  } else {
    values = "[]";
  }
  print("query: %, %\n", query, values);

  // note: this no longer works.
  results, success := execute(connection, Result, query, ..args);

  if !success {
    print("!success\n");
    return 0;
  }
  if results.count != 1 {
    print("results.count != 1\n");
    return 0;
  }

  print("result: %\n", results[0].id);

  return results[0].id;
}

main :: () {
  look_up_some_number("select 0::smallint as id where 2 = $1", 2);
  look_up_some_number("select 1::smallint as id where 2 = $1", 2);
  look_up_some_number("select 2::smallint as id where 2 = $1", 2);
  look_up_some_number("select 3::smallint as id where 2 = $1", 2);
  look_up_some_number("select 4::smallint as id where 2 = $1", 2);
  look_up_some_number("select $1 as id where 2 = $2", 0, 2);
  look_up_some_number("select $1 as id where 2 = $2", 1, 2);
  look_up_some_number("select $1 as id where 2 = $2", 2, 2);
  look_up_some_number("select $1 as id where 2 = $2", 3, 2);
  look_up_some_number("select $1 as id where 2 = $2", 4, 2);

  look_up_some_number("select id from users where id = $1", 1);
  look_up_some_number("select id from users where id = 1");
  look_up_some_number("select id from users where id = 321321321");
}

#run main();
