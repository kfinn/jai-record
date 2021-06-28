describe :: (name: string, body: Code) #expand {
  #insert_internal body;
}

it :: (name: string, body: Code) #expand {
  #insert_internal body;
}

to_equal :: (value: $T) -> ToEqualMatcher(T) {
  result: ToEqualMatcher(T);
  result.value = value;

  return result;
}

ToEqualMatcher :: struct($T: Type) {
  value: T;
}

expect :: (value: $Value, matcher: ToEqualMatcher(Value)) {
  assert(value == matcher.value);
}
