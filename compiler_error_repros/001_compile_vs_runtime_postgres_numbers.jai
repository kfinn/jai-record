#load "../vendor/jai-postgres/module.jai";

get_connection :: () -> *PGconn, success: bool {
  connection, success := connect("postgres://postgres:password@db:5432/postgres");
  if success {
    return connection, true;
  } else {
    return null, false;
  }
}

User :: struct {
  id: int;
};

look_up_some_id :: () -> int {
  connection := get_connection();
  defer disconnect(connection);

  results, success := execute(
    connection,
    User,
    "SELECT 1::INT8 AS id;"
  );

  if !success return 0;
  if results.count != 1 return 0;

  print("%\n", results[0]);

  return results[0].id;
}

COMPILETIME_ID :: #run look_up_some_id();

main :: () {
  nums: [1000]int;

  runtime_id_1 := look_up_some_id();
  runtime_id_2 := look_up_some_id();
  runtime_id_3 := look_up_some_id();
  runtime_id_4 := look_up_some_id();
  runtime_id_5 := look_up_some_id();

  print("compiletime ID: %, runtime ID: %\n", COMPILETIME_ID, runtime_id_1);

  print("runtime ID 1: %\n", runtime_id_1);
  print("runtime ID 2: %\n", runtime_id_2);
  print("runtime ID 3: %\n", runtime_id_3);
  print("runtime ID 4: %\n", runtime_id_4);
  print("runtime ID 5: %\n", runtime_id_5);
}
