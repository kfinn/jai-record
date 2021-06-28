ANY_FAILURES := false;

describe :: (name: string, body: Code) #expand {
  description := name;
  describe :: nested_describe;

  #insert_internal body;
}

nested_describe :: (description_suffix: string, body: Code) #expand {
  description := sprint("% %", `description, description_suffix);

  #insert_internal body;
}

it :: (description_suffix: string, body: Code) #expand {
  description := sprint("% %", `description, description_suffix);

  #insert_internal body;
}

to_equal :: (value: $T) -> ToEqual(T) {
  result: ToEqual(T);
  result.value = value;

  return result;
}

ToEqual :: struct($T: Type) {
  value: T;
}

expect :: (value: $Value, matcher: $MatcherType) #expand {
  if matches(value, matcher) return;

  ANY_FAILURES = true;
  print("% failed.\n  Expected it % %, got: %\n", `description, MatcherType, matcher, value);
}

matches :: (value: $Value, matcher: ToEqual(Value)) -> bool {
  return value == matcher.value;
}

specs_verify :: () {
  assert(!ANY_FAILURES);
}
