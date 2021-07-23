#run describe("lex_json", #code{
  it("lexes list and object control characters", #code{
    using JsonToken.Kind;

    json := "{}[]   ,:";
    json_tokens := lex_json(json);
    expect(json_tokens.count, to_equal(6));
    
    expect(json_tokens[0].kind, to_equal(BEGIN_OBJECT));
    expect(slice(json, json_tokens[0].start_index, json_tokens[0].count), to_equal("{"));

    expect(json_tokens[1].kind, to_equal(END_OBJECT));
    expect(slice(json, json_tokens[1].start_index, json_tokens[1].count), to_equal("}"));

    expect(json_tokens[2].kind, to_equal(BEGIN_ARRAY));
    expect(slice(json, json_tokens[2].start_index, json_tokens[2].count), to_equal("["));

    expect(json_tokens[3].kind, to_equal(END_ARRAY));
    expect(slice(json, json_tokens[3].start_index, json_tokens[3].count), to_equal("]"));

    expect(json_tokens[4].kind, to_equal(COMMA));
    expect(slice(json, json_tokens[4].start_index, json_tokens[4].count), to_equal(","));

    expect(json_tokens[5].kind, to_equal(COLON));
    expect(slice(json, json_tokens[5].start_index, json_tokens[5].count), to_equal(":"));
  });
  it("lexes strings", #code {
    using JsonToken.Kind;

    json := "[\n\"some string\",\n\"another string\"\n]";
    json_tokens := lex_json(json);
    expect(json_tokens.count, to_equal(5));
    
    expect(json_tokens[0].kind, to_equal(BEGIN_ARRAY));
    expect(slice(json, json_tokens[0].start_index, json_tokens[0].count), to_equal("["));

    expect(json_tokens[1].kind, to_equal(STRING));
    expect(slice(json, json_tokens[1].start_index, json_tokens[1].count), to_equal("\"some string\""));

    expect(json_tokens[2].kind, to_equal(COMMA));
    expect(slice(json, json_tokens[2].start_index, json_tokens[2].count), to_equal(","));

    expect(json_tokens[3].kind, to_equal(STRING));
    expect(slice(json, json_tokens[3].start_index, json_tokens[3].count), to_equal("\"another string\""));

    expect(json_tokens[4].kind, to_equal(END_ARRAY));
    expect(slice(json, json_tokens[4].start_index, json_tokens[4].count), to_equal("]"));
  });
  it("lexes strings including escaped quotes", #code {
    using JsonToken.Kind;

    json := "\"\\\"\"";
    json_tokens := lex_json(json);
    expect(json_tokens.count, to_equal(1));
    
    expect(json_tokens[0].kind, to_equal(STRING));
    expect(slice(json, json_tokens[0].start_index, json_tokens[0].count), to_equal("\"\\\"\""));
  });
  it("lexes numbers", #code {
    using JsonToken.Kind;

    json := "123,12.6e-78";
    json_tokens := lex_json(json);
    expect(json_tokens.count, to_equal(3));
    
    expect(json_tokens[0].kind, to_equal(NUMBER));
    expect(slice(json, json_tokens[0].start_index, json_tokens[0].count), to_equal("123"));

    expect(json_tokens[1].kind, to_equal(COMMA));
    expect(slice(json, json_tokens[1].start_index, json_tokens[1].count), to_equal(","));

    expect(json_tokens[2].kind, to_equal(NUMBER));
    expect(slice(json, json_tokens[2].start_index, json_tokens[2].count), to_equal("12.6e-78"));
  });
  it("lexes null, true, and false", #code {
    using JsonToken.Kind;

    json := "null true false";
    json_tokens := lex_json(json);
    expect(json_tokens.count, to_equal(3));
    
    expect(json_tokens[0].kind, to_equal(NULL));
    expect(slice(json, json_tokens[0].start_index, json_tokens[0].count), to_equal("null"));

    expect(json_tokens[1].kind, to_equal(TRUE));
    expect(slice(json, json_tokens[1].start_index, json_tokens[1].count), to_equal("true"));

    expect(json_tokens[2].kind, to_equal(FALSE));
    expect(slice(json, json_tokens[2].start_index, json_tokens[2].count), to_equal("false"));
  });
});
