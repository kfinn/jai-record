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

  describe("has_suffix", #code {
    it("is true for a valid suffix", #code {
      expect(has_suffix("ghostly", "stly"), to_equal(true));
    });
    it("is false for an invalid suffix", #code {
      expect(has_suffix("ghostly", "tlea"), to_equal(false));
    });
    it("is false for a suffix longer than the initial string", #code {
      expect(has_suffix("ghostly", "sssssssssstly"), to_equal(false));
    });
  });

  describe("slice", #code {
    it("returns a single character string for a range with equal start and ends", #code {
      expect(slice("hi", 0, 0), to_equal("h"));
    });
    it("returns a multi-character string for a range with different start and ends", #code {
      expect(slice("booooooo", 0, 2), to_equal("boo"));
    });
    it("asserts when the range start is less than 0", #code {
      expect(#code { slice("hi", -1, 1); }, to_assert());
    });
  });
});
