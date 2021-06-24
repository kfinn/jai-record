#import "Basic";

#load "../vendor/jai-postgres/module.jai";

#load "repo.jai";
#load "repos/users_repo.jai";
#load "repos/todos_repo.jai";

#load "sql.jai";
#load "sql/sql_select.jai";
#load "sql/sql_execute.jai";
#load "sql/sql_where.jai";

#load "strings.jai";
#load "assertions.jai";

main :: () {
  {
    user, success := UsersRepo.find(1);
    if success {
      print("success: true, user: %\n", <<user);
      free(user);
    } else {
      print("success: false, user: %\n", user);
    }
  }
  {
    user, success := UsersRepo.find(2);
    if success {
      print("success: true, user: %\n", <<user);
      free(user);
    } else {
      print("success: false, user: %\n", user);
    }
  }
  {
    user, success := UsersRepo.find(3);
    if success {
      print("success: true, user: %\n", <<user);
      free(user);
    } else {
      print("success: false, user: %\n", user);
    }
  }
  {
    todo, success := TodosRepo.find(1);
    if success {
      print("success: true, todo: %\n", <<todo);
      free(todo);
    } else {
      print("success: false, todo: %\n", todo);
    }
  }
  {
    todo, success := TodosRepo.find(2);
    if success {
      print("success: true, todo: %\n", <<todo);
      free(todo);
    } else {
      print("success: false, todo: %\n", todo);
    }
  }
  {
    todo, success := TodosRepo.find(3);
    if success {
      print("success: true, todo: %\n", <<todo);
      free(todo);
    } else {
      print("success: false, todo: %\n", todo);
    }
  }
}
