#run describe("composed_preloader.jai", #code{
  describe(
    "preload_composed_preloader",
    before_all=#code {
      connection := jai_record_pg_connection();
      execute(connection, "BEGIN");
    },
    after_all=#code {
      connection := jai_record_pg_connection();
      execute(connection, "ROLLBACK");
    },
    body=#code{
      it("preloads multiple has many relationships", #code{
        User :: struct {
          id: int;
          email: string;
        }
        UsersRepo :: #run repo("users", User);

        Todo :: struct {
          id: int;
          user_id: int;
          description: string;
        }
        TodosRepo :: #run repo("todos", Todo);

        Tag :: struct {
          id: int;
          user_id: int;
          description: string;
        }
        TagsRepo :: #run repo("tags", Tag);

        RecommendedTodo :: struct {
          id: int;
          user_id: int;
          todo_id: int;
        }
        RecommendedTodosRepo :: #run repo("recommended_todos", RecommendedTodo);

        UserHasManyTodos :: HasMany(
          UsersRepo,
          TodosRepo,
          "user",
          "todos",
          "user_id",
        );

        UserHasManyTags :: HasMany(
          UsersRepo,
          TagsRepo,
          "user",
          "tags",
          "user_id",
        );

        UserHasManyRecommendedTodos :: HasMany(
          UsersRepo,
          RecommendedTodosRepo,
          "user",
          "recommended_todos",
          "user_id",
        );

        connection := jai_record_pg_connection();

        InsertResult :: struct { id: int; }

        insert_users_results := execute(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO users (email)
            VALUES
              ('user_to_select@email.com'),
              ('user_to_select_with_no_data@email.com'),
              ('user_to_not_select@email.com')
            RETURNING id
          SQL
        );
        user_to_select_id := insert_users_results[0].id;
        user_to_select_with_no_data_id := insert_users_results[1].id;
        user_not_to_select_id := insert_users_results[2].id;

        insert_todos_args: struct {
          user_to_select_id: int;
          user_not_to_select_id: int;
        };
        insert_todos_args.user_to_select_id = user_to_select_id;
        insert_todos_args.user_not_to_select_id = user_not_to_select_id;

        insert_todos_results := execute(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO todos (user_id, description)
            VALUES
              (:user_to_select_id, 'first selected todo'),
              (:user_not_to_select_id, 'recommended todo')
            RETURNING id
          SQL,
          insert_todos_args
        );
        todo_to_select_id := insert_todos_results[0].id;
        todo_to_recommend_id := insert_todos_results[1].id;

        execute(
          connection,
          #string SQL
            INSERT INTO tags (user_id, description)
            VALUES
              (:user_to_select_id, 'selected tag'),
              (:user_not_to_select_id, 'tag not to select')
          SQL,
          insert_todos_args
        );

        insert_recommended_todos_args: struct {
          user_to_select_id: int;
          todo_to_recommend_id: int;
          user_not_to_select_id: int;
          todo_to_select_id: int;
        }
        insert_recommended_todos_args.user_to_select_id = user_to_select_id;
        insert_recommended_todos_args.todo_to_recommend_id = todo_to_recommend_id;
        insert_recommended_todos_args.user_not_to_select_id = user_not_to_select_id;
        insert_recommended_todos_args.todo_to_select_id = todo_to_select_id;

        execute(
          connection,
          #string SQL
            INSERT INTO recommended_todos (user_id, todo_id)
            VALUES
              (:user_to_select_id, :todo_to_recommend_id),
              (:user_not_to_select_id, :todo_to_select_id)
          SQL,
          insert_recommended_todos_args
        );

        is_test_user: SqlWhere("email LIKE 'user_to_select_%'");

        preloaded_users := preload(
          #run composed_preloader(
            UserHasManyTodos,
            #run composed_preloader(
              UserHasManyTags,
              UserHasManyRecommendedTodos
            )
          ),
          UsersRepo.where(is_test_user)
        );

        expect(preloaded_users.count, to_equal(2));

        find_actual_user_by_id :: (id: int, users: []$T) -> *T {
          for * users if it.id == id return it;
          return null;
        }

        user_to_select := find_actual_user_by_id(user_to_select_id, preloaded_users);
        expect(user_to_select.email, to_equal("user_to_select@email.com"));
        expect(user_to_select.todos.count, to_equal(1));
        expect(user_to_select.todos[0].description, to_equal("first selected todo"));
        expect(user_to_select.tags.count, to_equal(1));
        expect(user_to_select.tags[0].description, to_equal("selected tag"));
        expect(user_to_select.recommended_todos.count, to_equal(1));
        expect(user_to_select.recommended_todos[0].todo_id, to_equal(todo_to_recommend_id));

        user_to_select_with_no_data := find_actual_user_by_id(user_to_select_with_no_data_id, preloaded_users);
        expect(user_to_select_with_no_data.email, to_equal("user_to_select_with_no_data@email.com"));
        expect(user_to_select_with_no_data.todos.count, to_equal(0));
        expect(user_to_select_with_no_data.tags.count, to_equal(0));
        expect(user_to_select_with_no_data.recommended_todos.count, to_equal(0));
      });
      it("preloads both has many and belongs to relationships", #code{
        User :: struct {
          id: int;
          email: string;
        }
        UsersRepo :: #run repo("users", User);

        Todo :: struct {
          id: int;
          user_id: int;
          description: string;
        }
        TodosRepo :: #run repo("todos", Todo);

        Tagging :: struct {
          id: int;
          todo_id: int;
          tag_id: int;
        }

        TodoBelongsToUser :: BelongsTo(
          TodosRepo,
          UsersRepo,
          "todo",
          "user",
          "user_id"
        );

        TodoHasManyTaggings :: HasMany(
          TodosRepo,
          TaggingsRepo,
          "todo",
          "taggings",
          "todo_id"
        );

        connection := jai_record_pg_connection();

        InsertResult :: struct { id: int; }

        insert_users_results := execute(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO users (email)
            VALUES
              ('user_1@email.com')
            RETURNING id
          SQL
        );
        user := insert_users_results[0];

        insert_todos_results := execute(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO todos (user_id, description)
            VALUES
              (:id, 'todo with taggings'),
              (:id, 'todo without taggings')
            RETURNING id
          SQL,
          user
        );
        todo_with_taggings_id := insert_todos_results[0].id;
        todo_without_taggings_id := insert_todos_results[1].id;

        insert_tags_result := execute(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO tags (user_id, description)
            VALUES
              (:id, 'tag 1'),
              (:id, 'tag 2')
            RETURNING id
          SQL,
          user
        );
        tag_1_id := insert_tags_result[0].id;
        tag_2_id := insert_tags_result[1].id;

        insert_taggings_args: struct {
          todo_with_taggings_id: int;
          tag_1_id: int;
          tag_2_id: int;
        }
        insert_taggings_args.todo_with_taggings_id = todo_with_taggings_id;
        insert_taggings_args.tag_1_id = tag_1_id;
        insert_taggings_args.tag_2_id = tag_2_id;

        execute(
          connection,
          #string SQL
            INSERT INTO taggings (todo_id, tag_id)
            VALUES
              (:todo_with_taggings_id, :tag_1_id),
              (:todo_with_taggings_id, :tag_2_id)
          SQL,
          insert_taggings_args
        );

        is_test_todo: SqlWhere("id IN (:ids)", struct { ids: []int; });
        test_todo_ids: [..]int;
        array_add(*test_todo_ids, todo_with_taggings_id);
        array_add(*test_todo_ids, todo_without_taggings_id);
        is_test_todo.ids = test_todo_ids;

        preloaded_todos := preload(
          #run composed_preloader(
            TodoBelongsToUser,
            TodoHasManyTaggings
          ),
          TodosRepo.where(is_test_todo)
        );

        expect(preloaded_todos.count, to_equal(2));

        find_actual_todo_by_id :: (id: int, todos: []$T) -> *T {
          for * todos if it.id == id return it;
          return null;
        }

        todo_with_taggings := find_actual_todo_by_id(todo_with_taggings_id, preloaded_todos);
        expect(todo_with_taggings.description, to_equal("todo with taggings"));
        expect(todo_with_taggings.user.email, to_equal("user_1@email.com"));
        expect(todo_with_taggings.taggings.count, to_equal(2));
        todo_with_taggings_tag_ids: [2]int;
        todo_with_taggings_tag_ids[0] = todo_with_taggings.taggings[0].tag_id;
        todo_with_taggings_tag_ids[1] = todo_with_taggings.taggings[1].tag_id;
        expect(todo_with_taggings_tag_ids, to_contain_exactly(tag_1_id, tag_2_id));

        todo_without_taggings := find_actual_todo_by_id(todo_without_taggings_id, preloaded_todos);
        expect(todo_without_taggings.description, to_equal("todo without taggings"));
        expect(todo_without_taggings.user.email, to_equal("user_1@email.com"));
        expect(todo_without_taggings.taggings.count, to_equal(0));
      });
    }
  );
});
