#import "Basic";
#import "String";

main :: () {
  s := "aaaab";
  replaced, replaced_count := replace(s, "b", "c");
  print("replaced % bs in \"%\" with cs to get \"%\"\n", replaced_count, s, replaced);
}
