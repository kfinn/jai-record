#run describe("render.jai", #code{
  it("renders artirary objects and arrays, escaping strings as necessary", #code{
    ToRender :: struct {
      children: []struct {
        id: int;
        value: string;
        deeper_child: struct {
          id: int;
        };
      };
    }

    to_render :: ToRender.{.[.{12,"\"poo\"\\",.{17}},.{23,"second",.{674}}]};

    pipefds: [2]s32;
    expect(pipe(*pipefds), to_equal(cast(s32)0));

    read_end := pipefds[0];
    write_end := pipefds[1];

    render_json(write_end, to_render, #code{
      to_render := it;
      json_object("to_render", to_render, #code{
        json_array("children", to_render.children, #code{
          child := it;
          json_fields(child, "id", "value");
          json_object("deeper_child", child.deeper_child, #code{
            json_fields(deeper_child, "id");
          });
        });
      });
    });
    close(write_end);

    next_byte: u8;
    result_bytes: [..]u8;
    while read(read_end, *next_byte, size_of(u8)) {
      array_add(*result_bytes, next_byte);
    }
    close(read_end);

    result: string;
    result.count = result_bytes.count;
    result.data = result_bytes.data;

    expected_with_newline := #string JSON
{"to_render":{"children":[{"id":12,"value":"\"poo\"\\","deeper_child":{"id":17}},{"id":23,"value":"second","deeper_child":{"id":674}}]}}
    JSON
    expected := expected_with_newline;
    expected.count -= 1;
    expect(result, to_equal(expected));
  });

  it("renders nullable types", #code{
    RenderedValue :: struct {
      string_value: *string;
      int_value: *int;
    }

    ToRender :: struct {
      values: []RenderedValue;
    }

    result_with_null_values: RenderedValue;

    present_string_value := "hello";
    present_int_value := 574;
    result_with_present_values: RenderedValue;
    result_with_present_values.string_value = *present_string_value;
    result_with_present_values.int_value = *present_int_value;

    values: [..]RenderedValue;
    array_add(*values, result_with_null_values);
    array_add(*values, result_with_present_values);

    to_render: ToRender;
    to_render.values = values;

    pipefds: [2]s32;
    expect(pipe(*pipefds), to_equal(cast(s32)0));

    read_end := pipefds[0];
    write_end := pipefds[1];

    render_json(write_end, to_render, #code{
      to_render := it;
      json_array("values", to_render.values, #code{
        value := it;
        json_fields(value, "string_value", "int_value");
      });
    });
    close(write_end);

    next_byte: u8;
    result_bytes: [..]u8;
    while read(read_end, *next_byte, size_of(u8)) {
      array_add(*result_bytes, next_byte);
    }
    close(read_end);

    result: string;
    result.count = result_bytes.count;
    result.data = result_bytes.data;

    expected_with_newline := #string JSON
{"values":[{"string_value":null,"int_value":null},{"string_value":"hello","int_value":574}]}
    JSON;
    expected := expected_with_newline;
    expected.count -= 1;
    expect(result, to_equal(expected));
  });
});
