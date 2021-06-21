#import "Basic";

#load "vendor/jai-postgres/module.jai";

#load "repo.jai";
#load "repos/users_repo.jai";
#load "repos/todos_repo.jai";

main :: () {
  {
    user, success := find_user(1);
    if success {
      print("success: true, user: %\n", <<user);
      free(user);
    } else {
      print("success: false, user: %\n", user);
    }
  }
  {
    user, success := find_user(2);
    if success {
      print("success: true, user: %\n", <<user);
      free(user);
    } else {
      print("success: false, user: %\n", user);
    }
  }
  {
    user, success := find_user(3);
    if success {
      print("success: true, user: %\n", <<user);
      free(user);
    } else {
      print("success: false, user: %\n", user);
    }
  }
  {
    todo, success := find_todo(1);
    if success {
      print("success: true, todo: %\n", <<todo);
      free(todo);
    } else {
      print("success: false, todo: %\n", todo);
    }
  }
  {
    todo, success := find_todo(2);
    if success {
      print("success: true, todo: %\n", <<todo);
      free(todo);
    } else {
      print("success: false, todo: %\n", todo);
    }
  }
  {
    todo, success := find_todo(3);
    if success {
      print("success: true, todo: %\n", <<todo);
      free(todo);
    } else {
      print("success: false, todo: %\n", todo);
    }
  }
}
