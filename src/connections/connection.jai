base_handle_message :: (websocket_message: WebsocketMessage) {
  TodosChannelMessage :: struct {
    channel: string;
    action: string;
    todo_id: int;
  }

  json_parse_success, todos_channel_message, todos_channel_message_meta := parse_json_params(
    TodosChannelMessage,
    cast(string)websocket_message.payload
  );

  if todos_channel_message.channel == "TodosChannel" {
    if todos_channel_message.action == {
      case "completed";
        TodosChannel.completed(websocket_message.websocket_connection, todos_channel_message.todo_id);
      case "uncompleted";
        TodosChannel.uncompleted(websocket_message.websocket_connection, todos_channel_message.todo_id);
      case;
        print("unexpected action: %\n", todos_channel_message.action);
    }
  }
}
