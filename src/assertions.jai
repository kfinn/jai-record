assert_equals :: (expected: $T, actual: T) {
  assert(
    expected == actual,
    "expected %; got %",
    expected,
    actual
  );
}
