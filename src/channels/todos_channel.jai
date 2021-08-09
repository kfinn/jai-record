TodosChannel :: struct {
  completed :: (websocket_connection: *WebsocketConnection, todo_id: int) {
    todo := TodosRepo.find(todo_id);
    if !todo {
      print("todo not found. id: %\n", todo_id);
      return;
    }

    now := "2021-08-09 18:37:00";
    todo.completed_at = *now;
    if TodosRepo.save(todo) {
      push_lock(*websocket_connection.write_mutex);

      websocket_message: WebsocketMessage;
      websocket_message.websocket_connection = websocket_connection;
      websocket_message.kind = .TEXT;
      string_payload := "ack";
      websocket_message.payload = cast([]u8)string_payload;
      write_websocket_message(websocket_message);
    } else {
      print("unable to save todo\n");
    }
  }

  uncompleted :: (websocket_connection: *WebsocketConnection, todo_id: int) {
    todo := TodosRepo.find(todo_id);
    if !todo {
      print("todo not found. id: %\n", todo_id);
      return;
    }

    todo.completed_at = null;
    if TodosRepo.save(todo) {
      push_lock(*websocket_connection.write_mutex);

      websocket_message: WebsocketMessage;
      websocket_message.websocket_connection = websocket_connection;
      websocket_message.kind = .TEXT;
      string_payload := "ack";
      websocket_message.payload = cast([]u8)string_payload;
      write_websocket_message(websocket_message);
    } else {
      print("unable to save todo\n");
    }
  }
}
