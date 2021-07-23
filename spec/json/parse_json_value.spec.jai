#run describe("parse_json_value", #code {
  it("parses a number", #code{
    using JsonValue.Kind;

    json_value, success := parse_json_value("123");
    expect(success, to_equal(true));
    expect(json_value.kind, to_equal(NUMBER));
    expect(json_value.number_value, to_equal("123"));
  });
  it("parses a string", #code{
    using JsonValue.Kind;

    json_value, success := parse_json_value("\"some\\\"string\\\"\"");
    expect(success, to_equal(true));
    expect(json_value.kind, to_equal(STRING));
    expect(json_value.number_value, to_equal("some\"string\""));
  });
  it("parses null", #code{
    using JsonValue.Kind;

    json_value, success := parse_json_value("null");
    expect(success, to_equal(true));
    expect(json_value.kind, to_equal(NULL));
  });
  it("parses booleans", #code{
    using JsonValue.Kind;

    true_json_value, true_success := parse_json_value("true");
    expect(true_success, to_equal(true));
    expect(true_json_value.kind, to_equal(BOOLEAN));
    expect(true_json_value.boolean_value, to_equal(true));

    false_json_value, false_success := parse_json_value("false");
    expect(false_success, to_equal(true));
    expect(false_json_value.kind, to_equal(BOOLEAN));
    expect(false_json_value.boolean_value, to_equal(false));
  });
  it("parses an array", #code{
    using JsonValue.Kind;
    json_value, success := parse_json_value("[15, [67]]");
    expect(success, to_equal(true));
    expect(json_value.kind, to_equal(ARRAY));
    root_array_value := json_value.array_value;
    expect(root_array_value.count, to_equal(2));

    first_root_array_value := root_array_value[0];
    expect(first_root_array_value.kind, to_equal(NUMBER));
    expect(first_root_array_value.number_value, to_equal("15"));

    second_root_array_value := root_array_value[1];
    expect(second_root_array_value.kind, to_equal(ARRAY));
    nested_array_value := root_array_value[1].array_value;
    expect(nested_array_value.count, to_equal(1));

    first_nested_array_value := nested_array_value[0];
    expect(first_nested_array_value.kind, to_equal(NUMBER));
    expect(first_nested_array_value.number_value, to_equal("67"));
  });
  it("parses an object", #code{
    using JsonValue.Kind;
    json_value, success := parse_json_value("{\"num\": 12}");
    expect(success, to_equal(true));
    expect(json_value.kind, to_equal(OBJECT));
    root_object_value := json_value.object_value;
    expect(root_object_value.count, to_equal(1));
    root_object_field := root_object_value[0];
    expect(root_object_field.key, to_equal("num"));
    root_object_field_value := root_object_field.value;
    expect(root_object_field_value.kind, to_equal(NUMBER));
    expect(root_object_field_value.number_value, to_equal("12"));
  });
  it("parses some nested objects and arrays", #code{
    using JsonValue.Kind;
    json := #string JSON
      {
        "array": [
          { "num": 12 }
        ],
        "scalar": "banana"
      }
    JSON
    root, success := parse_json_value(json);
    expect(success, to_equal(true));
    expect(root.kind, to_equal(OBJECT));
    root_object_value := root.object_value;
    expect(root_object_value.count, to_equal(2));
    
    first_field := root_object_value[0];
    expect(first_field.key, to_equal("array"));
    nested_array := first_field.value;
    expect(nested_array.kind, to_equal(ARRAY));
    nested_array_value := nested_array.array_value;
    expect(nested_array_value.count, to_equal(1));
    nested_object := nested_array_value[0];
    expect(nested_object.kind, to_equal(OBJECT));
    nested_object_value := nested_object.object_value;
    expect(nested_object_value.count, to_equal(1));
    nested_object_field := nested_object_value[0];
    expect(nested_object_field.key, to_equal("num"));
    expect(nested_object_field.value.kind, to_equal(NUMBER));
    expect(nested_object_field.value.number_value, to_equal("12"));

    second_field := root_object_value[1];
    expect(second_field.key, to_equal("scalar"));
    expect(second_field.value.kind, to_equal(STRING));
    expect(second_field.value.string_value, to_equal("banana"));
  });
});
