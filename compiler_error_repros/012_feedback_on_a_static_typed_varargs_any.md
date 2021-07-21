in implementing support for nullable types in my postgres client, I found myself wanting strongly typed pointers to represent nulls in a way that seems hard using `Any`.

I wished I would have had a generic, arbitrary, static-at-compile-time tuple concept, where each element in the tuple could have arbitrary, static type

then I could happily embed them into postgres queries

```jai
some_procedure :: (name: string, other_args: $..Any) -> bool {
  #insert #run () -> string {
    body: String_Builder;

    for arg in other_args {
      do_something_with_arg(arg);
    }
  }
}


main :: () {
  some_procedure("static list", ..int.[1, 2, 3]) // spreadable at compile time, works fine
  some_procedure("static args", 1, "hello", 24.5) // no spread operation, works fine

  dynamic_args: [..]Any;
  array_add(dynamic_args, 123);
  array_add(dynamic_args, "hello");
  some_procedure("dynamic args", ..dynamic_args) // unknown at compile time, fails
}
```
