#import "Basic";

Template :: struct($FORMAT: string, $ARGS_COUNT: int) {
  args: [ARGS_COUNT]Any;
}

join_templates :: (lhs: $LhsTemplate, rhs: $RhsTemplate) -> Template(
  FORMAT=#run sprint("% %", LhsTemplate.FORMAT, RhsTemplate.FORMAT),
  // I also attempted this variant:
  // FORMAT=sprint("% %", LhsTemplate.FORMAT, RhsTemplate.FORMAT),
  // which compiled but immediately caused a segfault.
  ARGS_COUNT=LhsTemplate.ARGS_COUNT + RhsTemplate.ARGS_COUNT
) {
  result: Template(
    FORMAT=#run sprint("% %", LhsTemplate.FORMAT, RhsTemplate.FORMAT),
    ARGS_COUNT=LhsTemplate.ARGS_COUNT + RhsTemplate.ARGS_COUNT
  );
  for lhs.args result.args[it_index] = it;
  for rhs.args result.args[it_index + LhsTemplate.ARGS_COUNT] = it;

  return result;
}

main :: () {
  lhs: Template("hello, ?!", 1);
  lhs.args[0] = "world";

  rhs: Template("this ? repros a ?", 2);
  rhs.args[0] = "program";
  rhs.args[1] = "bug";

  joined := join_templates(lhs, rhs);

  print("%", joined);
}
