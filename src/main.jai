#import "Compiler";
#import "Basic";

#load "repo.jai";
#load "has_many.jai";
#load "repos/users_repo.jai";
#load "repos/todos_repo.jai";

#load "sql.jai";
#load "sql/sql_delete.jai";
#load "sql/sql_execute.jai";
#load "sql/sql_insert.jai";
#load "sql/sql_select.jai";
#load "sql/sql_update.jai";
#load "sql/sql_where.jai";

#load "strings.jai";
#load "assertions.jai";

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
    users_with_todos := UserHasManyTodos.preload(UsersRepo.all());
    for result, result_index: users_with_todos {
      print("users_with_todos[%] = %\n", result_index, <<result.record);
      for todo, todo_index: result.todos {
        print("  todos[%] = %\n", todo_index, <<todo);
      }
    }
  }
}
