#import "Basic";

Factory :: struct ($Built: Type) {}

build :: ($Factory: Type) -> Factory.Built {
  result: Factory.Built;
  return result;
}

main :: () {
  Thing1 :: struct {
    num: int = 12;
  }
  Thing1Factory :: Factory(Thing1);

  Thing2 :: struct {
    name: string = "friend";
  }
  Thing2Factory :: Factory(Thing2);

  print("Thing1: % Thing2: %\n", build(Thing1Factory), build(Thing2Factory));
}
