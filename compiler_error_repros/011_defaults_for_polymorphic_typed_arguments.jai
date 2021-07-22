some_procedure :: (value: $T = "hello") {
  print("%\n", value);
}

main :: () {
  some_procedure("fish");
  some_procedure(12);
}
