#import "Basic";

#run {
  ints :: int.[0, 1, 2];
  anys: [3]Any;
  for ints {
    anys[it_index] = it;
  }
  for ints print("int: %\n", it);
  for anys print("any: %\n", it);
};

main :: () {}

//  is this something to report?
