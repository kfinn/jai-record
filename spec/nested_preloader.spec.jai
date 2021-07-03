#run describe("nested_preloader.jai", #code{
  describe(
    "preload_nested_preloader",
    before_all=#code {
      connection := jai_record_pg_connection();
      execute(connection, "BEGIN");
    },
    after_all=#code {
      connection := jai_record_pg_connection();
      execute(connection, "ROLLBACK");
    },
    body=#code{
      Todo :: struct { 
        id: int;
        description: string;
      };
      TodosRepo :: #run repo("todos", Todo);
      TodoHasManyTaggings :: HasMany(
        TodosRepo,
        TaggingsRepo,
        "todo",
        "taggings",
        "todo_id"
      );

      Tagging :: struct {
        id: int;
        todo_id: int;
        tag_id: int;
      };
      TaggingsRepo :: #run repo("taggings", Tagging);
      TaggingBelongsToTag :: BelongsTo(
        TaggingsRepo,
        TagsRepo,
        "tagging",
        "tag",
        "tag_id"
      );

      Tag :: struct {
        id: int;
        description: string;
      };
      TagsRepo :: #run repo("tags", Tag);

      connection := jai_record_pg_connection();
      InsertResult :: struct { id: int; }
      users_insert_results := execute(
        connection,
        InsertResult,
        #string SQL
          INSERT INTO users (email)
          VALUES ('test_user@email.gov')
          RETURNING id
        SQL
      );
      user_id := users_insert_results[0].id;

      toods_insert_results := execute(
        connection,
        InsertResult,
        #string SQL
          INSERT INTO todos (user_id, description)
          VALUES
            ($1, 'todo with taggings'),
            ($1, 'todo with no taggings')
          RETURNING id
        SQL,
        user_id
      );
      todo_with_taggings_id := toods_insert_results[0].id;
      todo_with_no_taggings_id := toods_insert_results[1].id;

      tags_insert_results := execute(
        connection,
        InsertResult,
        #string SQL
          INSERT INTO tags (user_id, description)
          VALUES
            ($1, 'first tag'),
            ($1, 'second tag')
          RETURNING id
        SQL,
        user_id
      );
      first_tag_id := tags_insert_results[0].id;
      second_tag_id := tags_insert_results[1].id;

      execute(
        connection,
        #string SQL
          INSERT INTO taggings (todo_id, tag_id)
          VALUES
            ($1, $2),
            ($1, $3)
        SQL,
        todo_with_taggings_id,
        first_tag_id,
        second_tag_id
      );

      is_test_todo: SqlWhere("id IN (?)", 1);
      test_ids: [..]Any;
      array_add(*test_ids, todo_with_taggings_id);
      array_add(*test_ids, todo_with_no_taggings_id);
      is_test_todo.args[0] = test_ids;

      todos_with_taggings_and_tags := preload(
        #run nested_preloader(
          TodoHasManyTaggings,
          TaggingBelongsToTag,
        ),
        TodosRepo.all(*is_test_todo)
      );

      expect(todos_with_taggings_and_tags.count, to_equal(2));

      find_todo_by_id :: (id: int, todos: []$T) -> *T {
        for * todos if it.id == id return it;
        return null;
      }

      todo_with_taggings := find_todo_by_id(
        todo_with_taggings_id,
        todos_with_taggings_and_tags
      );
      expect(todo_with_taggings.description, to_equal("todo with taggings"));
      expect(todo_with_taggings.taggings.count, to_equal(2));
      tag_descriptions: [2]string;
      tag_descriptions[0] = todo_with_taggings.taggings[0].tag.description;
      tag_descriptions[1] = todo_with_taggings.taggings[1].tag.description;
      expect(
        tag_descriptions,
        to_contain_exactly(
          "first tag",
          "second tag"
        )
      );
    }
  );
});
