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

    expect(result, to_equal(replace(#string JSON
{"to_render":{"children":[{"id":12,"value":"\"poo\"\\","deeper_child":{"id":17}},{"id":23,"value":"second","deeper_child":{"id":674}}]}}
    JSON, "\n", "")));
  });
});
