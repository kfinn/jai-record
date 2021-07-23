#import "Compiler";
#import "Basic";
#import "Pool";
#import "String";
#import "POSIX";
#import "Hash_Table";

#import "jai-socket";
#import "uniform";

#load "jai-record-lib/repo.jai";
#load "jai-record-lib/preloaders.jai";
#load "jai-record-lib/composed_preloader.jai";
#load "jai-record-lib/nested_preloader.jai";
#load "jai-record-lib/has_many.jai";
#load "jai-record-lib/belongs_to.jai";

#load "repos/users_repo.jai";
#load "repos/todos_repo.jai";
#load "repos/tags_repo.jai";
#load "repos/taggings_repo.jai";

#load "sql/sql_delete.jai";
#load "sql/sql_insert.jai";
#load "sql/sql_select.jai";
#load "sql/sql_update.jai";
#load "sql/sql_where.jai";
#load "sql/parse_sql.jai";

#load "json/lex_json.jai";
#load "json/parse_json_value.jai";
#load "json/parse_json_params.jai";

#load "postgres/module.jai";

#load "scgi/scgi_server.jai";
#load "scgi/draw_routes.jai";

#load "controllers/todos_controller.jai";
#load "controllers/users_controller.jai";
#load "controllers/user_tags_controller.jai";

#load "notes.jai";
#load "routes.jai";
#load "type_infos.jai";

main :: () {
  scgi_server_run();
}

jai_record_demo :: () {
  {
    all_users, success := UsersRepo.all();
    if success {
      print("success: true, users: %\n", all_users);
    } else {
      print("success: false, users: %\n", all_users);
    }
  }
  {
    user, success := UsersRepo.find(1);
    if success {
      print("success: true, user: %\n", <<user);
    } else {
      print("success: false, user: %\n", user);
    }
  }
  {
    user, success := UsersRepo.find(2);
    if success {
      print("success: true, user: %\n", <<user);
    } else {
      print("success: false, user: %\n", user);
    }
  }
  {
    user, success := UsersRepo.find(3);
    if success {
      print("success: true, user: %\n", <<user);
    } else {
      print("success: false, user: %\n", user);
    }
  }
  {
    todo, success := TodosRepo.find(1);
    if success {
      print("success: true, todo: %\n", <<todo);
    } else {
      print("success: false, todo: %\n", todo);
    }
  }
  {
    todo, success := TodosRepo.find(2);
    if success {
      print("success: true, todo: %\n", <<todo);
    } else {
      print("success: false, todo: %\n", todo);
    }
  }
  {
    todo, success := TodosRepo.find(3);
    if success {
      print("success: true, todo: %\n", <<todo);
    } else {
      print("success: false, todo: %\n", todo);
    }
  }
  {
    users_with_todos := preload(UserHasManyTodos, UsersRepo.all());

    for result, result_index: users_with_todos {
      print("users_with_todos[%] = %@%\n", result_index, <<result.user, result.user);
      for todo, todo_index: result.todos {
        print("  todos[%] = %\n", todo_index, <<todo);
        print("  todos[%].user = %@%\n", todo_index, <<todo.user, todo.user);
      }
    }
  }
  {
    ComposedPreloader :: #run composed_preloader(
      UserHasManyTodos,
      UserHasManyTags
    );

    users_with_todos_and_tags := preload(
      ComposedPreloader,
      UsersRepo.all()
    );

    for result, result_index: users_with_todos_and_tags {
      print("users_with_todos_and_tags[%] = %@%\n", result_index, <<result.user, result.user);
      for todo, todo_index: result.todos {
        print("  todos[%] = %\n", todo_index, <<todo.todo);
        print("  todos[%].user = %@%\n", todo_index, <<todo.user, todo.user);
      }
      for tag, tag_index: result.tags {
        print("  tags[%] = %\n", tag_index, <<tag.tag);
        print("  tags[%].user = %@%\n", tag_index, <<tag.user, tag.user);
      }
    }
  }
  {
    todos_with_users := preload(TodoBelongsToUser, TodosRepo.all());
    for result, result_index: todos_with_users {
      print("todos_with_users[%] = %\n", result_index, <<result.todo);
      if result.user != null {
        print("  user = %\n", <<result.user.user);
      } else {
        print("  user = null\n");
      }
    }
  }
  {
    users_with_the_works := preload(
      #run composed_preloader(
        #run nested_preloader(
          UserHasManyTodos,
          #run nested_preloader(
            TodoHasManyTaggings,
            #run nested_preloader(
              TaggingBelongsToTag,
              TagBelongsToUser
            )
          )
        ),
        UserHasManyTags
      ),
      UsersRepo.all()
    );
    for user: users_with_the_works {
      print("user@%: %\n", user, user.email);
      print("  todos:\n");
      for todo: user.todos {
        // print("  todo@%: %, user: %\n", todo, todo.description, todo.user);
        print("    todo@%: %, %\n", todo, todo.description, <<todo);
        for tagging: todo.taggings {
          // print("    tagging@%: %, todo: %\n", tagging.tag, tagging.tag.description, tagging.todo);
          print("      tagging@%: %, %\n", tagging.tag, tagging.tag.description, <<tagging);
          print("        user@%: %\n", tagging.tag.user, tagging.tag.user.email);
        }
      }
      print("  tags:\n");
      for tag: user.tags {
        // print("  tag@%: %, user: %\n", tag, tag.description, tag.user);
        print("    tag@%: %, %, (user: %)\n", tag, tag.description, <<tag, tag.user);
      }
    }
  }
}
