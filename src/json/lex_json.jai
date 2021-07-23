JsonToken :: struct {
  Kind :: enum {
    UNINTIALIZED;

    BEGIN_OBJECT;
    END_OBJECT;

    BEGIN_ARRAY;
    END_ARRAY;

    COLON;
    COMMA;

    STRING;
    NUMBER;

    NULL;
    TRUE;
    FALSE;
  }

  kind: Kind = .UNINTIALIZED;
  start_index: int;
  count: int;
}

lex_json :: (json: string) -> []JsonToken {
  result: [..]JsonToken;

  for :lexed_json_tokens json {
    array_add(*result, it);
  }

  return result;
}

lexed_json_tokens :: (json: *string, body: Code, flags: For_Flags) #expand {
  `it_index := 0;
  `it: JsonToken;

  yield :: () #expand {
    #insert(remove=#assert(false)) body;
    `it_index += 1;
    `it.kind = .UNINTIALIZED;
  }

  is_escaping := false;

  json_character_index := 0;
  while json_character_index < json.count {
    json_characters_consumed := 1;
    defer json_character_index += json_characters_consumed;


    remainder := slice(<<json, json_character_index, json.count - json_character_index);
    if `it.kind == .STRING {
      if is_escaping {
        is_escaping = false;
      } else {
        if remainder[0] == #char "\"" {
          `it.count = json_character_index - `it.start_index + 1;

            yield();
        } else if remainder[0] == #char "\\" {
          is_escaping = true;
        }
      }
      continue;
    }

    if `it.kind == .NUMBER {
      if !is_json_digit(remainder[0]) {
        `it.count = json_character_index - `it.start_index;
        yield();
      }
    } else if is_json_digit(remainder[0]) {
      `it.kind = .NUMBER;
      `it.start_index = json_character_index;
    }
    
    if remainder[0] == #char "\"" {
      `it.kind = .STRING;
      `it.start_index = json_character_index;
    } else if remainder[0] == #char "{" {
      `it.kind = .BEGIN_OBJECT;
      `it.start_index = json_character_index;
      `it.count = 1;

      yield();
    } else if remainder[0] == #char "}" {
      `it.kind = .END_OBJECT;
      `it.start_index = json_character_index;
      `it.count = 1;

      yield();
    } else if remainder[0] == #char "[" {
      `it.kind = .BEGIN_ARRAY;
      `it.start_index = json_character_index;
      `it.count = 1;

      yield();
    } else if remainder[0] == #char "]" {
     `it.kind = .END_ARRAY;
      `it.start_index = json_character_index;
      `it.count = 1;

      yield();
    } else if remainder[0] == #char ":" {
      `it.kind = .COLON;
      `it.start_index = json_character_index;
      `it.count = 1;

      yield();
    } else if remainder[0] == #char "," {
      `it.kind = .COMMA;
      `it.start_index = json_character_index;
      `it.count = 1;

      yield();
    } else if begins_with(remainder, "null") {
      `it.kind = .NULL;
      `it.start_index = json_character_index;
      `it.count = 4;

      yield();
      json_characters_consumed = 4;
    } else if begins_with(remainder, "true") {
      `it.kind = .TRUE;
      `it.start_index = json_character_index;
      `it.count = 4;

      yield();
      json_characters_consumed = 4;
    } else if begins_with(remainder, "false") {
      `it.kind = .FALSE;
      `it.start_index = json_character_index;
      `it.count = 5;

      yield();
      json_characters_consumed = 5;
    }
  }

  if `it.kind == .NUMBER {
    `it.count = json.count - `it.start_index;
    yield();
  }
}

is_json_digit :: (character: u8) -> bool {
  return (
    (character >= #char "0" && character <= #char "9") ||
    character == #char "." ||
    character == #char "e" ||
    character == #char "E" ||
    character == #char "+" ||
    character == #char "-"
  );
}
