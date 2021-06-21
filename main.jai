#import "Basic";

#load "vendor/jai-postgres/module.jai";

#load "repo.jai";
#load "repos/user_repo.jai";

main :: () {
  print("%\n", User);

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
}
