#run describe("strings.jai", #code {
  describe("has_prefix", #code {
    it("is true for a valid prefix", #code {
      expect(has_prefix("hello", "hell"), to_equal(true));
    });
    it("is false for an invalid prefix", #code {
      expect(has_prefix("hello", "hi"), to_equal(false));
    });
    it("is false for a prefix longer than the initial string", #code {
      expect(has_prefix("hello", "hellllllll"), to_equal(false));
    });
  });
});
