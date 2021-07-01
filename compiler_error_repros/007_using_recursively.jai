#import "Basic";

Thing :: struct {
  id: int;
}

Decorator :: struct($Decorated: Type, $AddedField: Type, $added_field_name: string) {
  // proposed syntax:
  // using(except=.["decorated", "Decorated", "AddedField", "added_field_name"]) decorated: Decorated;
  using decorated: Decorated;
  #insert #run sprint("%: AddedField;\n", added_field_name);
}

decorate :: (
  thing_to_decorate: $ToDecorate,
  added_field: $AddedField,
  $added_field_name: string
) -> Decorator(
  ToDecorate,
  AddedField,
  added_field_name
) {
  result: Decorator(
    ToDecorate,
    AddedField,
    added_field_name
  );
  result.decorated = thing_to_decorate;
  #insert #run sprint("result.% = added_field;\n", added_field_name);

  return result;
}

main :: () {
  thing: Thing;
  thing.id = 12;

  print("thing: %\n", thing);

  once_decorated_thing := decorate(thing, 1999, "some_num");
  print(
    "once decorated thing: % thing: % some_num: %\n",
    once_decorated_thing,
    once_decorated_thing.decorated,
    once_decorated_thing.some_num
  );

  // I'd like to be able to do this, but it results in a compiler error
  // should the language be extended to support something like this?
  // probably need a more discerning `using`

  // twice_decorated_thing := decorate(once_decorated_thing, "hello", "some_string");
  // print(
  //   "twice decorated thing: % thing: % some_num: % some_string: %\n",
  //   twice_decorated_thing,
  //   twice_decorated_thing.decorated,
  //   twice_decorated_thing.some_num,
  //   twice_decorated_thing.some_string
  // );
}
