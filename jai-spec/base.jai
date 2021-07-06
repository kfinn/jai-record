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
  describe :: nested_describe;

  if before_all != EMPTY_CODE #insert before_all;
  #insert_internal body;
  if after_all != EMPTY_CODE #insert after_all;
}

it :: (description_suffix: string, body: Code) #expand {
  description := sprint("% %", `description, description_suffix);

  #insert_internal body;
}

to_equal :: (value: $T) -> ToEqual(T) {
  matcher: ToEqual(T);
  matcher.value = value;

  return matcher;
}

ToEqual :: struct($T: Type) {
  value: T;
}

to_be_present :: () -> ToBePresent {
  return TO_BE_PRESENT_SINGLETON;
}

TO_BE_PRESENT_SINGLETON: ToBePresent;
ToBePresent :: struct {}

to_be_empty :: () -> ToBeEmpty {
  return TO_BE_EMPTY_SINGLETON;
}

TO_BE_NULL_SINGLETON: ToBeNull;
ToBeNull :: struct {}

to_be_null :: () -> ToBeNull {
  return TO_BE_NULL_SINGLETON;
}

TO_BE_EMPTY_SINGLETON: ToBeEmpty;
ToBeEmpty :: struct {}

to_contain_exactly :: (values: ..$T) -> ToContainExactly(T) {
  matcher: ToContainExactly(T);
  matcher.values = values;
  return matcher;
}

ToContainExactly :: struct($T: Type) {
  values: []T;
}

expect :: (value: $Value, matcher: $MatcherType, loc := #caller_location) #expand {
  if matches(value, matcher) return;

  ANY_FAILURES = true;
  print("Failed expectation: %\n  Expected it % %, got: %\n%\n", `description, MatcherType, matcher, value, loc);
}

matches :: (value: $Value, matcher: ToEqual(Value)) -> bool {
  return value == matcher.value;
}

matches :: (values: []$Value, matcher: ToContainExactly(Value)) -> bool {
  for expected_value: matcher.values {
    matched := false;
    for actual_value: values {
      matched ||= (expected_value == actual_value);
    }
    if !matched return false;
  }
  return true;
}

matches :: (value: *$Value, matcher: ToBePresent) -> bool {
  return value != null;
}

matches :: (value: []$Value, matcher: ToBeEmpty) -> bool {
  return value.count == 0;
}

matches :: (value: *$Value, matcher: ToBeNull) -> bool {
  return value == null;
}

specs_verify :: () {
  assert(!ANY_FAILURES);
}

NotMatcher :: struct($T: Type) {
  matcher: T;
}

not :: (matcher: $T) -> NotMatcher(T) {
  not_matcher: NotMatcher(T);
  not_matcher.matcher = matcher;
  return not_matcher;
}

matches :: (value: $V, not_matcher: NotMatcher($T)) -> bool {
  return !matches(value, not_matcher.matcher);
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
