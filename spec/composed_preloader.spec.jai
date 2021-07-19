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

        insert_todos_results := execute(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO todos (user_id, description)
            VALUES
              ($1, 'first selected todo'),
              ($2, 'recommended todo')
            RETURNING id
          SQL,
          user_to_select_id,
          user_not_to_select_id
        );
        todo_to_select_id := insert_todos_results[0].id;
        todo_to_recommend_id := insert_todos_results[1].id;

        execute(
          connection,
          #string SQL
            INSERT INTO tags (user_id, description)
            VALUES
              ($1, 'selected tag'),
              ($2, 'tag not to select')
          SQL,
          user_to_select_id,
          user_not_to_select_id
        );
        execute(
          connection,
          #string SQL
            INSERT INTO recommended_todos (user_id, todo_id)
            VALUES
              ($1, $2),
              ($3, $4)
          SQL,
          user_to_select_id, todo_to_recommend_id,
          user_not_to_select_id, todo_to_select_id
        );

        is_test_user: SqlWhere("email LIKE 'user_to_select_%'", 0);

        preloaded_users := preload(
          #run composed_preloader(
            UserHasManyTodos,
            #run composed_preloader(
              UserHasManyTags,
              UserHasManyRecommendedTodos
            )
          ),
          UsersRepo.where(*is_test_user)
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
        user_id := insert_users_results[0].id;

        insert_todos_results := execute(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO todos (user_id, description)
            VALUES
              ($1, 'todo with taggings'),
              ($1, 'todo without taggings')
            RETURNING id
          SQL,
          user_id,
        );
        todo_with_taggings_id := insert_todos_results[0].id;
        todo_without_taggings_id := insert_todos_results[1].id;

        insert_tags_result := execute(
          connection,
          InsertResult,
          #string SQL
            INSERT INTO tags (user_id, description)
            VALUES
              ($1, 'tag 1'),
              ($1, 'tag 2')
            RETURNING id
          SQL,
          user_id
        );
        tag_1_id := insert_tags_result[0].id;
        tag_2_id := insert_tags_result[1].id;

        execute(
          connection,
          #string SQL
            INSERT INTO taggings (todo_id, tag_id)
            VALUES
              ($1, $2),
              ($1, $3)
          SQL,
          todo_with_taggings_id,
          tag_1_id,
          tag_2_id
        );

        is_test_todo: SqlWhere("id IN (?)", 1);
        test_todo_ids: [..]Any;
        array_add(*test_todo_ids, todo_with_taggings_id);
        array_add(*test_todo_ids, todo_without_taggings_id);
        is_test_todo.args[0] = test_todo_ids;

        preloaded_todos := preload(
          #run composed_preloader(
            TodoBelongsToUser,
            TodoHasManyTaggings
          ),
          TodosRepo.where(*is_test_todo)
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
