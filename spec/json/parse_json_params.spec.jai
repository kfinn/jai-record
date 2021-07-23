#run describe("parse_json_params", #code {
  it("parses json into a struct and sets is_set for fields present in the json", #code{
    Params :: struct {
      blog_post: struct {
        id: int;
        title: string;
        body: string;
        tag_ids: []int;
        commenter_names: []string;
        another_array: []u8;
      };
    }

    success, result, meta := parse_json_params(
      Params,
      #string JSON
        {
          "blog_post": {
              "id":123,
              "title": "Really Cool Blog Post",
              "tag_ids":[12, 23, 34],
              "commenter_names": ["Charlie", "Zoe", "Willow"]
            }
        }
      JSON
    );
    expect(success, to_equal(true));
    expect(result.blog_post.id, to_equal(123));
    expect(meta.blog_post.id.is_set, to_equal(true));
    expect(result.blog_post.title, to_equal("Really Cool Blog Post"));
    expect(meta.blog_post.title.is_set, to_equal(true));
    expect(meta.blog_post.body.is_set, to_equal(false));
    expect(result.blog_post.tag_ids, to_contain_exactly(12, 23, 34));
    expect(meta.blog_post.tag_ids.is_set, to_equal(true));
    expect(result.blog_post.commenter_names, to_contain_exactly("Charlie", "Zoe", "Willow"));
    expect(meta.blog_post.commenter_names.is_set, to_equal(true));
    expect(meta.blog_post.another_array.is_set, to_equal(false));
  });
  it("parses json into an array of structs and sets is_set for fields present in the json", #code{
    Params :: struct {
      array_of_structs: []struct {
        id: int;
        unused: string;
      };
      unset_array_of_structs: []struct {
        name: string;
      };
    }

    success, result, meta := parse_json_params(
      Params,
      #string JSON
        {
          "array_of_structs": [
            {
              "id":123,
            },
            {
            }
          ]
        }
      JSON
    );
    expect(success, to_equal(true));
    expect(result.array_of_structs.count, to_equal(2));
    expect(meta.array_of_structs.is_set, to_equal(true));
    expect(result.array_of_structs[0].id, to_equal(123));
    expect(meta.array_of_structs[0].id.is_set, to_equal(true));
    expect(meta.array_of_structs[0].unused.is_set, to_equal(false));
    expect(meta.array_of_structs[1].id.is_set, to_equal(false));
    expect(meta.array_of_structs[1].unused.is_set, to_equal(false));
    expect(meta.unset_array_of_structs.is_set, to_equal(false));
  });
});
