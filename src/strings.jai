has_prefix :: (source: string, prefix: string) -> bool {
  if source.count < prefix.count return false;

  for 0..(prefix.count - 1) {
    if prefix[it] != source.data[it] return false;
  }
  return true;
}

has_suffix :: (source: string, suffix: string) -> bool {
  if source.count < suffix.count return false;

  suffix_start_index := source.count - suffix.count;
  for 0..(suffix.count - 1) {
    if suffix[it] != source.data[suffix_start_index + it] return false;
  }
  return true;
}

has_suffix_test :: () {
  assert(has_suffix("SqlExpression(blah)", ")"));
  assert(has_suffix("ghostly", "stly"));
  assert(!has_suffix("ghostly", "sssssssssstly"));
  assert(!has_suffix("ghostly", "tlea"));
} @Test

slice :: (source: string, start_index: int, end_index: int) -> string {
  assert(start_index >= 0 && start_index < source.count, "out of bounds: attempting to slice a string of length % starting from index %", source.count, start_index);
  assert(end_index >= start_index && end_index < source.count, "end_index out of bounds: attempting to slice a string of length %, starting with index % and ending with index %", source.count, start_index, end_index);

  result: string = ---;
  result.count = end_index - start_index + 1;
  result.data = source.data + start_index;

  return result;
}

slice_test :: () {
  assert(slice("hi", 0, 0) == "h");
  assert(slice("booooooo", 0, 2) == "boo");
} @Test;

join :: (components: []string, joiner: string = ", ") -> string {
  result_builder: String_Builder;
  defer free_buffers(*result_builder);

  for components {
    print_to_builder(*result_builder, it);
    if it_index < components.count - 1 print_to_builder(*result_builder, joiner);
  }

  return builder_to_string(*result_builder);
}

join_test :: () {
  components :: string.["hello", "to", "all", "my", "viewers"];
  assert_equals("hello, to, all, my, viewers", join(components));
  assert_equals("hello banana to banana all banana my banana viewers", join(components, " banana "));
} @Test;
