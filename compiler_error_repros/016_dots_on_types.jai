StringTyped :: struct {
  ResultType :: string;
  some_value :: "boo";
}

get_some_value :: ($some_value_source: Type) -> some_value_source.ResultType {
  return some_value_source.some_value;
}

main :: () {
  get_some_value(StringTyped);
}
