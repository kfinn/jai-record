#import "Basic";

Factory :: struct ($Built: Type) {}

build :: (_f: $Factory) -> Factory.Built {
  result: Factory.Built;
  return result;
}

main :: () {
  Thing1 :: struct {
    num: int = 12;
  }
  Thing1Factory :: Factory(Thing1);
  thing_1_factory: Thing1Factory;

  Thing2 :: struct {
    name: string = "friend";
  }
  Thing2Factory :: Factory(Thing2);
  thing_2_factory: Thing2Factory;

  print("Thing1: % Thing2: %\n", build(thing_1_factory), build(thing_2_factory));
}
