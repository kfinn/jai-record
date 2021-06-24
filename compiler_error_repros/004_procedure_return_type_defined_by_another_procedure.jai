Wrapped :: struct() {}

derive_wrapped :: ($ToWrap: Type) -> Type {
  return struct {
    wrapped: ToWrap;
  };
}

wrap :: (value: $ToWrap) -> derive_wrapped(ToWrap) {
  result: derive_wrapped(ToWrap);
  return result;
}

main :: () {
  SomeValue :: struct {
    number: int;
  }
  some_value: SomeValue;
  wrapped_value := wrap(some_value);
  print("%\n", wrapped_value);
}
