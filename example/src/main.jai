#import "Basic"()(MEMORY_DEBUGGER=true);
#import "Compiler";
#import "Hash_Table";
#import "Pool";
#import "POSIX";
#import "String";
#import "Thread";
#import "Base64_Encode";
#import "Bit_Operations";

#import "jai-socket";
#import "uniform";

#import "jai-record-lib";
#import "sql";
#import "json";
#import "postgres";
#import "web";
#import "mutexes";
#import "notes";
#import "type_infos";
#import "byte_order";

#load "repos/users_repo.jai";
#load "repos/todos_repo.jai";
#load "repos/tags_repo.jai";
#load "repos/taggings_repo.jai";

#load "channels/todos_channel.jai";

#load "controllers/todos_controller.jai";
#load "controllers/users_controller.jai";
#load "controllers/user_tags_controller.jai";

#load "handle_websocket_message.jai";

#load "views/todos/show.jai";
#load "views/users/index.jai";
#load "views/user_tags/index.jai";

#load "routes.jai";

main :: () {
  http_server_run(handle_http_request);
}
