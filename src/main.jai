#import "Compiler";
#import "Basic";

#load "repo.jai";
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

  {
    id_not_included_in_fixtures: SqlWhere(
      SQL_EXPRESSION="id NOT IN (?, ?)",
      ARGS_COUNT=2
    );
    id_not_included_in_fixtures.args[0] = 1;
    id_not_included_in_fixtures.args[1] = 2;

    sql_delete_execute("users", *id_not_included_in_fixtures);
  }
}
