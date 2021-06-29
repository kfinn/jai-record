SomeType :: struct(STRINGS_COUNT: int) {
  strings: [STRINGS_COUNT]string;
}

extend_some_type :: (some_instance: $T/SomeType, code: string) -> SomeType(T.STRINGS_COUNT + 1) {
  result: SomeType(T.STRINGS_COUNT + 1);
  for some_instance.strings result.strings[it_index] = it;
  result.strings[T.STRINGS_COUNT] = code;
  return result;
}

STATIC_SOME_TYPE_INSTANCE :: SomeType(STRINGS_COUNT=1).{.["hello"]};
EXTENDED_SOME_TYPE_INSTANCE :: #run extend_some_type(STATIC_SOME_TYPE_INSTANCE, "world");
