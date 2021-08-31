#import "Basic";

has_member :: (type_info_struct: *Type_Info_Struct, name: string) -> bool {
  _, found := find_member(type_info_struct, name);
  return found;
}

find_member :: (type_info_struct: *Type_Info_Struct, name: string) -> Type_Info_Struct_Member, found: bool #must {
  for member: type_info_struct.members {
    if member.name == name return member, true;
    if member.flags & .USING {
      member_type_info_struct: *Type_Info_Struct;
      if member.type.type == .STRUCT {
        member_type_info_struct = cast(*Type_Info_Struct)member.type;
      } else if member.type.type == .POINTER {
        pointer_to := cast(*Type_Info_Pointer)member.type;
        assert(pointer_to.type == .STRUCT);
        member_type_info_struct = cast(*Type_Info_Struct)pointer_to;
      }
      member_found_through_using, member_found_through_using_found := find_member(member_type_info_struct, name);
      if member_found_through_using_found return member_found_through_using, true;
    }
  }
  return .{}, false;
}

get_constant_member_type_info_struct_value :: (type_info_struct: *Type_Info_Struct, member: Type_Info_Struct_Member) -> *Type_Info_Struct {
  member_value_address := cast(**Type_Info)(type_info_struct.constant_storage_buffer + member.offset_into_constant_storage);
  member_value: *Type_Info = << member_value_address;
  route_type_info := member_value;
  assert(route_type_info.type == .STRUCT);
  return cast(*Type_Info_Struct)route_type_info;
}
