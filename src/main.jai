#import "Compiler";
#import "Basic";
#import "Pool";
#import "String";

#load "repo.jai";
#load "preloaders.jai";
#load "composed_preloader.jai";
#load "has_many.jai";
#load "belongs_to.jai";
#load "repos/users_repo.jai";
#load "repos/todos_repo.jai";
#load "repos/tags_repo.jai";
#load "repos/taggings_repo.jai";

#load "sql.jai";
#load "sql/sql_delete.jai";
#load "sql/sql_execute.jai";
#load "sql/sql_insert.jai";
#load "sql/sql_select.jai";
#load "sql/sql_update.jai";
#load "sql/sql_where.jai";

#load "postgres/module.jai";

main :: () {
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
    users_with_todos := preload_has_many_without_inverse(UserHasManyTodos, UsersRepo.all());

    for result, result_index: users_with_todos {
      print("users_with_todos[%] = %@%\n", result_index, <<result.user, result.user);
      for todo, todo_index: result.todos {
        print("  todos[%] = %\n", todo_index, <<todo);
        // print("  todos[%].user = %@%\n", todo_index, <<todo.user, todo.user);
      }
    }
  }
  {
    ComposedPreloader :: #run compose_preloader(
      UserHasManyTodos,
      UserHasManyTags
    );

    users_with_todos_and_tags := preload_composed_preloader(
      ComposedPreloader,
      UsersRepo.all()
    );

    for result, result_index: users_with_todos_and_tags {
      print("users_with_todos_and_tags[%] = %@%\n", result_index, <<result.user, result.user);
      for todo, todo_index: result.todos {
        print("  todos[%] = %\n", todo_index, <<todo);
        // print("  todos[%].user = %@%\n", todo_index, <<todo.user, todo.user);
      }
      for tag, tag_index: result.tags {
        print("  tags[%] = %\n", tag_index, <<tag);
        // print("  todos[%].user = %@%\n", todo_index, <<todo.user, todo.user);
      }
    }
  }
  {
    todos_with_users := preload(TodoBelongsToUser, TodosRepo.all());
    for result, result_index: todos_with_users {
      print("todos_with_users[%] = %\n", result_index, <<result.todo);
      if result.user != null {
        print("  user = %\n", <<result.user);
      } else {
        print("  user = null\n");
      }
    }
  }
}
