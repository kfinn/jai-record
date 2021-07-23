#import "Basic";

modified :: ($arg: int) -> $T #modify {
  T = type_info([arg]int);
} {
  result: [arg]int;
  for * result {
    <<it = it_index;
  }
  return result;
}

main :: () {
  print("%\n", modified(3));
}
