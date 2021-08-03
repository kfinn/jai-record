#import "Basic"()(MEMORY_DEBUGGER=true);
#import "Compiler";
#import "Hash_Table";
#import "Pool";
#import "POSIX";
#import "String";
#import "Thread";
#import "Base64_Encode";

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

#load "web/http_server.jai";
#load "web/draw_routes.jai";
#load "web/render.jai";

#load "controllers/todos_controller.jai";
#load "controllers/users_controller.jai";
#load "controllers/user_tags_controller.jai";

#load "views/todos/show.jai";

#load "notes.jai";
#load "routes.jai";
#load "type_infos.jai";

main :: () {
  http_server_run();
}
