#run describe("strings.jai", #code {
  describe("has_prefix", #code {
    describe("with a valid prefix", #code {
      it("is true", #code {
        expect(has_prefix("hello", "hell"), to_equal(true));
      });
    });
    describe("with an invalid prefix", #code {
      it("is false", #code {
        expect(has_prefix("hello", "hi"), to_equal(false));
      });
    });
    describe("with a prefix longer than the initial string", #code {
      it("is false", #code {
        expect(has_prefix("hello", "hellllllll"), to_equal(false));
      });
    });
  });
});
