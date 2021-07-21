find_member :: (name: string, type_info_struct: *Type_Info_Struct) -> *Type_Info_Struct_Member {
  for * member: type_info_struct.members {
    if member.name == name return member;
    if member.flags & .USING {
      member_type_info_struct: *Type_Info_Struct;
      if member.type.type == .STRUCT {
        member_type_info_struct = cast(*Type_Info_Struct)member.type;
      } else if member.type.type == .POINTER {
        pointer_to := cast(*Type_Info_Pointer)member.type;
        assert(pointer_to.type == .STRUCT);
        member_type_info_struct = cast(*Type_Info_Struct)pointer_to;
      }
      member_found_through_using := find_member(name, member_type_info_struct);
      if member_found_through_using return member_found_through_using;
    }
  }
  return null;
}
