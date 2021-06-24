#import "Basic";

#load "../vendor/jai-postgres/module.jai";

#load "repo.jai";
#load "repos/users_repo.jai";
#load "repos/todos_repo.jai";
#load "sql.jai";
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

  // {
  //   todos_created_after: TodosCreatedAfter;
  //   todos_created_after.args[0] = "2021-04-01";

  //   todos_with_id_2: WithId;
  //   todos_with_id_2.args[0] = 2;

  //   todos, success := sql_execute(
  //     TodosRepo.Select,
  //     TodosRepo.table_name,
  //     todos_created_after
  //   );
  //   if success {
  //     print("success: true, todos: %\n", todos);
  //   } else {
  //     print("success: false, todos: %\n", todos);
  //   }

  //   str :: "hello";
  //   for 0..(str.count - 1) print("character: %", str[it]);
  // }
}
