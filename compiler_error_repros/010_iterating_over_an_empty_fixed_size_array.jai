#import "Basic";

macro_on_an_array :: () #expand {
  if `array {
    print("% elements:\n", `array.count);
    for `array {
      print("  %\n", it);
    }
  } else {
    print("empty\n");
  }
}

main :: () {
  {
    array :: int.[1, 2, 3];
    macro_on_an_array();
  }
  {
    array :: int.[];
    macro_on_an_array();
  }
  {
    array: [..]int;
    defer array_free(array);
    array_add(*array, 1);
    array_add(*array, 2);
    array_add(*array, 3);
    macro_on_an_array();
  }
  {
    array: [..]int;
    macro_on_an_array();
  }
}
