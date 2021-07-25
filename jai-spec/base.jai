ANY_FAILURES := false;

EMPTY_CODE :: #code {};

describe :: (
  name: string,
  body: Code,
  before_all: Code = EMPTY_CODE,
  before_each: Code = EMPTY_CODE,
  after_all: Code = EMPTY_CODE,
  after_each: Code = EMPTY_CODE
) #expand {
  description := name;
  describe :: nested_describe;

  inherited_before_each :: () #expand {
    #insert before_each;
  }

  inherited_after_each :: () #expand {
    #insert after_each;
  }

  if before_all != EMPTY_CODE #insert before_all;
  #insert_internal body;
  if after_all != EMPTY_CODE #insert after_all;
}

nested_describe :: (
  description_suffix: string,
  body: Code,
  before_all: Code = EMPTY_CODE,
  before_each: Code = EMPTY_CODE,
  after_all: Code = EMPTY_CODE,
  after_each: Code = EMPTY_CODE
) #expand {
  description := sprint("% %", `description, description_suffix);
  describe :: nested_describe;

  local_inherited_before_each :: `inherited_before_each;

  inherited_before_each :: () #expand {
    local_inherited_before_each();
    #insert before_each;
  };

  local_inherited_after_each :: `inherited_after_each;

  inherited_after_each :: () #expand {
    #insert after_each;
    local_inherited_after_each();
  };

  if before_all != EMPTY_CODE #insert before_all;
  #insert_internal body;
  if after_all != EMPTY_CODE #insert after_all;
}

evaluate_it :: (
  description: string,
  $body: Code
) {
  #insert_internal body;
}

it :: (description_suffix: string, body: Code) #expand {
  description := sprint("% %", `description, description_suffix);

  `inherited_before_each();
  evaluate_it(description, body);
  `inherited_after_each();
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

to_begin_with :: (prefix: string) -> ToBeginWith {
  matcher: ToBeginWith;
  matcher.prefix = prefix;
  return matcher;
}

ToBeginWith :: struct {
  prefix: string;
}

expect :: (value: $Value, matcher: $MatcherType, loc := #caller_location) #expand {
  if matches(value, matcher) return;

  ANY_FAILURES = true;
  print("Failed expectation: %\n  Expected it % %, got: %\n%\n\n", `description, MatcherType, matcher, value, loc);

  `return;
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

matches :: (value: $Value, matcher: ToBeginWith) -> bool {
  return begins_with(value, matcher.prefix);
}

specs_verify :: () {
  assert(!ANY_FAILURES, "Tests failed");
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
