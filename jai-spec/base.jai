ANY_FAILURES := false;

#add_context did_assert_during_expect: bool = false;

EMPTY_CODE :: #code {};

describe :: (
  name: string,
  body: Code,
  before_all: Code = EMPTY_CODE,
  after_all: Code = EMPTY_CODE
) #expand {
  description := name;
  describe :: nested_describe;

  if before_all != EMPTY_CODE #insert before_all;
  #insert_internal body;
  if after_all != EMPTY_CODE #insert after_all;
}

nested_describe :: (
  description_suffix: string,
  body: Code,
  before_all: Code = EMPTY_CODE,
  after_all: Code = EMPTY_CODE
) #expand {
  description := sprint("% %", `description, description_suffix);

  if before_all != EMPTY_CODE #insert before_all;
  #insert_internal body;
  if after_all != EMPTY_CODE #insert after_all;
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

expect :: (value: $Value, matcher: $MatcherType, loc := #caller_location) #expand {
  if matches(value, matcher) return;

  ANY_FAILURES = true;
  print("% failed.\n  Expected it % %, got: %\n%\n", `description, MatcherType, matcher, value, loc);
}

matches :: (value: $Value, matcher: ToEqual(Value)) -> bool {
  return value == matcher.value;
}

specs_verify :: () {
  assert(!ANY_FAILURES);
}

ToAssert :: struct {}

to_assert :: () -> ToAssert {
  return ToAssert.{};
}

expected_assertion_failed :: (loc: Source_Code_Location, message: string) {
  context.did_assert_during_expect = true;
}

expect :: (body: Code, matcher: ToAssert, loc := #caller_location) #expand {
  new_context := context;
  new_context.assertion_failed = expected_assertion_failed;
  push_context new_context {
    #insert_internal body;
  }

  if new_context.did_assert_during_expect return;

  ANY_FAILURES = true;
  print("% failed.\n  Expected it to assert, got none.\n%\n", `description, loc);
}
