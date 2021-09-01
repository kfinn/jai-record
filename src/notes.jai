#import "String";
#import "Compiler";

match_note :: (note_prefix: string, note_suffix: string, member: *Type_Info_Struct_Member) -> string, matches: bool {
  result_note: string;
  for note: member.notes {
    if !begins_with(note, note_prefix) continue;
    if !ends_with(note, note_suffix) continue;

    result_note = note;
    break;
  }
  if !result_note return "", false;

  slice_start_index := note_prefix.count;
  slice_count := result_note.count - (note_suffix.count + note_prefix.count);

  return slice(
    result_note,
    slice_start_index,
    slice_count
  ), true;
}

match_note :: (note_prefix: string, note_suffix: string, declaration: *Code_Declaration) -> string, matches: bool {
  result_note: string;
  for note: declaration.notes {
    if !begins_with(note.text, note_prefix) continue;
    if !ends_with(note.text, note_suffix) continue;

    result_note = note.text;
    break;
  }
  if !result_note return "", false;

  slice_start_index := note_prefix.count;
  slice_count := result_note.count - (note_suffix.count + note_prefix.count);

  return slice(
    result_note,
    slice_start_index,
    slice_count
  ), true;
}
