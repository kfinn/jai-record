JsonValue :: struct {
  Kind :: enum {
    NULL;
    BOOLEAN;
    NUMBER;
    STRING;
    ARRAY;
    OBJECT;
  }

  kind: Kind;

  union {
    boolean_value: bool;
    number_value: string;
    string_value: string;
    array_value: []JsonValue;
    object_value: []JsonField;
  }
}

JsonField :: struct {
  key: string;
  value: JsonValue;
}

parse_json_value :: (json: string) -> JsonValue, success: bool {
  State :: struct {
    Kind :: enum {
      PARSING_ARRAY;
      PARSING_OBJECT;
    }

    kind: Kind;

    union {
      array_children_builder: [..]JsonValue;
      object_fields_builder: [..]JsonField;
    }

    ready_for_next_value: bool;

    ready_for_next_key: bool;
    current_key: string;
  }

  stack: [..]State;

  for :lexed_json_tokens json {
    if stack.count == 0 {
      if #complete it.kind == {
        case .NUMBER;
          result: JsonValue;
          result.kind = .NUMBER;
          result.number_value = slice(json, it.start_index, it.count);
          return result, true;

        case .STRING;
          result: JsonValue;
          result.kind = .STRING;
          parsed_json_string, parse_json_string_success := parse_json_string(slice(json, it.start_index, it.count));
          if !parse_json_string_success return .{}, false;
          result.string_value = parsed_json_string;
          return result, true;

        case .NULL;
          result: JsonValue;
          result.kind = .NULL;
          return result, true;

        case .TRUE;
          result: JsonValue;
          result.kind = .BOOLEAN;
          result.boolean_value = true;
          return result, true;

        case .FALSE;
          result: JsonValue;
          result.kind = .BOOLEAN;
          result.boolean_value = false;
          return result, true;

        case .BEGIN_ARRAY;
          next_state: State;
          next_state.kind = .PARSING_ARRAY;
          next_state.ready_for_next_value = true;
          array_add(*stack, next_state);

        case .BEGIN_OBJECT;
          next_state: State;
          next_state.kind = .PARSING_OBJECT;
          next_state.ready_for_next_key = true;
          array_add(*stack, next_state);

        case .END_ARRAY; #through;
        case .END_OBJECT; #through;
        case .COMMA; #through;
        case .COLON; #through;
        case .UNINTIALIZED;
          return .{}, false;
      }
    } else {
      current_state := peek_pointer(stack);
      if #complete current_state.kind == {
        case .PARSING_ARRAY;
          if #complete it.kind == {
            case .NUMBER;
              if !current_state.ready_for_next_value return .{}, false;
              result: JsonValue;
              result.kind = .NUMBER;
              result.number_value = slice(json, it.start_index, it.count);
              array_add(*current_state.array_children_builder, result);
              current_state.ready_for_next_value = false;

            case .STRING;
              if !current_state.ready_for_next_value return .{}, false;
              result: JsonValue;
              result.kind = .STRING;
              parsed_json_string, parse_json_string_success := parse_json_string(slice(json, it.start_index, it.count));
              if !parse_json_string_success return .{}, false;
              result.string_value = parsed_json_string;
              array_add(*current_state.array_children_builder, result);
              current_state.ready_for_next_value = false;

            case .NULL;
              if !current_state.ready_for_next_value return .{}, false;
              result: JsonValue;
              result.kind = .NULL;
              array_add(*current_state.array_children_builder, result);
              current_state.ready_for_next_value = false;

            case .TRUE;
              if !current_state.ready_for_next_value return .{}, false;
              result: JsonValue;
              result.kind = .BOOLEAN;
              result.boolean_value = true;
              array_add(*current_state.array_children_builder, result);
              current_state.ready_for_next_value = false;

            case .FALSE;
              if !current_state.ready_for_next_value return .{}, false;
              result: JsonValue;
              result.kind = .BOOLEAN;
              result.boolean_value = false;
              array_add(*current_state.array_children_builder, result);
              current_state.ready_for_next_value = false;

            case .BEGIN_ARRAY;
              if !current_state.ready_for_next_value return .{}, false;
              next_state: State;
              next_state.kind = .PARSING_ARRAY;
              next_state.ready_for_next_value = true;
              array_add(*stack, next_state);
            
            case .END_ARRAY;
              pop(*stack);
              result: JsonValue;
              result.kind = .ARRAY;
              result.array_value = current_state.array_children_builder;
              if stack.count == 0 {
                return result, true;
              }

              parent_state := peek_pointer(stack);
              if #complete parent_state.kind == {
                case .PARSING_ARRAY;
                  if !parent_state.ready_for_next_value return .{}, false;
                  array_add(*parent_state.array_children_builder, result);
                  parent_state.ready_for_next_value = false;
                case .PARSING_OBJECT;
                  if !parent_state.ready_for_next_value return .{}, false;

                  field: JsonField;
                  field.key = parent_state.current_key;
                  field.value = result;
                  array_add(*parent_state.object_fields_builder, field);
                  parent_state.ready_for_next_value = false;
              }
            
            case .COMMA;
              if current_state.ready_for_next_value return .{}, false;
              current_state.ready_for_next_value = true;

            case .BEGIN_OBJECT;
              if !current_state.ready_for_next_value return .{}, false;
              next_state: State;
              next_state.kind = .PARSING_OBJECT;
              next_state.ready_for_next_key = true;
              array_add(*stack, next_state);

            case .END_OBJECT; #through;
            case .COLON; #through;
            case .UNINTIALIZED;
              return .{}, false;
          }
        case .PARSING_OBJECT;
          if #complete it.kind == {
            case .NUMBER;
              if !current_state.ready_for_next_value return .{}, false;
              result: JsonValue;
              result.kind = .NUMBER;
              result.number_value = slice(json, it.start_index, it.count);

              field: JsonField;
              field.key = current_state.current_key;
              field.value = result;

              array_add(*current_state.object_fields_builder, field);
              current_state.ready_for_next_value = false;

            case .STRING;
              if current_state.ready_for_next_key {
                parsed_json_string, parse_json_string_success := parse_json_string(slice(json, it.start_index, it.count));
                if !parse_json_string_success return .{}, false;
                current_state.current_key = parsed_json_string;
                current_state.ready_for_next_key = false;
              } else if current_state.ready_for_next_value {
                result: JsonValue;
                result.kind = .STRING;
                parsed_json_string, parse_json_string_success := parse_json_string(slice(json, it.start_index, it.count));
                if !parse_json_string_success return .{}, false;
                result.string_value = parsed_json_string;

                field: JsonField;
                field.key = current_state.current_key;
                field.value = result;

                array_add(*current_state.object_fields_builder, field);
                current_state.ready_for_next_value = false;
              } else {
                return .{}, false;
              }

            case .NULL;
              if !current_state.ready_for_next_value return .{}, false;
              result: JsonValue;
              result.kind = .NULL;

              field: JsonField;
              field.key = current_state.current_key;
              field.value = result;

              array_add(*current_state.object_fields_builder, field);
              current_state.ready_for_next_value = false;

            case .TRUE;
              if !current_state.ready_for_next_value return .{}, false;
              result: JsonValue;
              result.kind = .BOOLEAN;
              result.boolean_value = true;

              field: JsonField;
              field.key = current_state.current_key;
              field.value = result;

              array_add(*current_state.object_fields_builder, field);
              current_state.ready_for_next_value = false;

            case .FALSE;
              if !current_state.ready_for_next_value return .{}, false;
              result: JsonValue;
              result.kind = .BOOLEAN;
              result.boolean_value = false;
              
              field: JsonField;
              field.key = current_state.current_key;
              field.value = result;

              array_add(*current_state.object_fields_builder, field);
              current_state.ready_for_next_value = false;

            case .BEGIN_ARRAY;
              if !current_state.ready_for_next_value return .{}, false;
              next_state: State;
              next_state.kind = .PARSING_ARRAY;
              next_state.ready_for_next_value = true;
              array_add(*stack, next_state);
                        
            case .COMMA;
              if current_state.ready_for_next_key return .{}, false;
              if current_state.ready_for_next_value return .{}, false;
              current_state.ready_for_next_key = true;

            case .BEGIN_OBJECT;
              if !current_state.ready_for_next_value return .{}, false;
              next_state: State;
              next_state.kind = .PARSING_OBJECT;
              next_state.ready_for_next_key = true;
              array_add(*stack, next_state);

            case .END_OBJECT;
              if current_state.ready_for_next_value return .{}, false;

              pop(*stack);
              result: JsonValue;
              result.kind = .OBJECT;
              result.object_value = current_state.object_fields_builder;
              if stack.count == 0 {
                return result, true;
              }

              parent_state := peek_pointer(stack);
              if #complete parent_state.kind == {
                case .PARSING_ARRAY;
                  if !parent_state.ready_for_next_value return .{}, false;
                  array_add(*parent_state.array_children_builder, result);
                  parent_state.ready_for_next_value = false;
                case .PARSING_OBJECT;
                  if !parent_state.ready_for_next_value return .{}, false;

                  field: JsonField;
                  field.key =parent_state.current_key;
                  field.value = result;

                  array_add(*parent_state.object_fields_builder, field);
                  parent_state.ready_for_next_value = false;
              }


            case .COLON;
              if current_state.ready_for_next_key return .{}, false;
              if current_state.ready_for_next_value return .{}, false;
              current_state.ready_for_next_value = true;

            case .END_ARRAY; #through;
            case .UNINTIALIZED;
              return .{}, false;
          }
      }
    }
  }

  return .{}, false;
}

parse_json_string :: (json_string: string) -> string, success: bool #must {
  if json_string.count < 2 return "", false;
  if json_string[0] != #char "\"" return "", false;
  if json_string[json_string.count - 1] != #char "\"" return "", false;

  remainder := slice(json_string, 1, json_string.count - 2);
  string_builder: String_Builder;
  defer free_buffers(*string_builder);

  while remainder {
    if remainder[0] == #char "\\" {
      if remainder[1] == #char "\"" {
        print_to_builder(*string_builder, "\"");
        advance(*remainder, 2);
      }
    } else {
      print_to_builder(*string_builder, "%", slice(remainder, 0, 1));
      advance(*remainder);
    }
  }

  return builder_to_string(*string_builder), true;
}
