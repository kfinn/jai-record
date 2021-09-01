#run describe("nested_preloader.jai", #code{
  describe(
    "preload_nested_preloader",
    before_each=#code {
      connection := postgres_connection();
      execute(connection, "BEGIN");
    },
    after_each=#code {
      connection := postgres_connection();
      execute(connection, "ROLLBACK");
    },
    body=#code{
      it("preloads nested has many relationships", #code{
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

        connection := postgres_connection();
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
        user := users_insert_results[0];

        toods_insert_results := execute(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO todos (user_id, description)
            VALUES
              (:id, 'todo with taggings'),
              (:id, 'todo with no taggings')
            RETURNING id
          SQL,
          user
        );
        todo_with_taggings_id := toods_insert_results[0].id;
        todo_with_no_taggings_id := toods_insert_results[1].id;

        tags_insert_results := execute(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO tags (user_id, description)
            VALUES
              (:id, 'first tag'),
              (:id, 'second tag')
            RETURNING id
          SQL,
          user
        );
        first_tag_id := tags_insert_results[0].id;
        second_tag_id := tags_insert_results[1].id;

        insert_taggings_args: struct {
          todo_with_taggings_id: int;
          first_tag_id: int;
          second_tag_id: int;
        }
        insert_taggings_args.todo_with_taggings_id = todo_with_taggings_id;
        insert_taggings_args.first_tag_id = first_tag_id;
        insert_taggings_args.second_tag_id = second_tag_id;

        execute(
          connection,
          #string SQL
            INSERT INTO taggings (todo_id, tag_id)
            VALUES
              (:todo_with_taggings_id, :first_tag_id),
              (:todo_with_taggings_id, :second_tag_id)
          SQL,
          insert_taggings_args
        );

        is_test_todo: SqlWhere("id IN (:ids)", struct { ids: []int; });
        test_ids: [..]int;
        array_add(*test_ids, todo_with_taggings_id);
        array_add(*test_ids, todo_with_no_taggings_id);
        is_test_todo.ids = test_ids;

        todos_with_taggings_and_tags := preload(
          #run nested_preloader(
            TodoHasManyTaggings,
            TaggingBelongsToTag,
          ),
          TodosRepo.where(is_test_todo)
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
      });
      it("preloads nested belongs to relationships", #code {
        Tag :: struct {
          id: int;
          description: string;
          user_id: int;
        }
        TagsRepo :: #run repo("tags", Tag);
        TagBelongsToUser :: BelongsTo(
          TagsRepo,
          UsersRepo,
          "tag",
          "user",
          "user_id"
        );

        User :: struct {
          id: int;
          email: string;
        }
        UsersRepo :: #run repo("users", User);
        UserHasManyTodods :: HasMany(
          UsersRepo,
          TodosRepo,
          "user",
          "todos",
          "user_id"
        );

        Todo :: struct {
          id: int;
          description: string;
          user_id: int;
        }
        TodosRepo :: #run repo("todos", Todo);

        connection := postgres_connection();
        InsertResult :: struct { id: int; }
        insert_user_results := execute(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO users (email)
            VALUES
              ('first_user@email.gov')
            RETURNING id
          SQL
        );
        user := insert_user_results[0];

        insert_tags_results := execute(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO tags (user_id, description)
            VALUES
              (:id, 'first tag'),
              (:id, 'second tag')
            RETURNING id
          SQL,
          user
        );
        first_tag_id := insert_tags_results[0].id;
        second_tag_id := insert_tags_results[1].id;

        execute(
          connection,
          #string SQL
            INSERT INTO todos (user_id, description)
            VALUES
              (:id, 'first todo'),
              (:id, 'second todo'),
              (:id, 'third todo')
          SQL,
          user
        );

        is_test_tag: SqlWhere("id IN (:ids)", struct { ids: []int; });
        test_tag_ids: [..]int;
        array_add(*test_tag_ids, first_tag_id);
        array_add(*test_tag_ids, second_tag_id);
        is_test_tag.ids = test_tag_ids;

        tags_with_users_and_todos := preload(
          #run nested_preloader(
            TagBelongsToUser,
            UserHasManyTodods
          ),
          TagsRepo.where(is_test_tag)
        );

        expect(tags_with_users_and_todos.count, to_equal(2));
        for tag: tags_with_users_and_todos {
          expect(tag.user.email, to_equal("first_user@email.gov"));
          expect(tag.user.todos.count, to_equal(3));
          todo_descriptions: [3]string;
          todo_descriptions[0] = tag.user.todos[0].description;
          todo_descriptions[1] = tag.user.todos[1].description;
          todo_descriptions[2] = tag.user.todos[2].description;
          expect(
            todo_descriptions,
            to_contain_exactly(
              "first todo",
              "second todo",
              "third todo"
            )
          );
        }
      });
    }
  );
});
