IdIn :: SqlWhere("id IN ?", 1);

HasManyPreloaded :: struct($Source: Type, $Destination: Type, $source_name: string, $destination_name: string) {
  #insert #run sprint("using %: *Source;\n", source_name);
  #insert #run sprint("%: []*Destination;\n", destination_name);
}

has_many :: (
  $source_repo: Type,
  $destination_repo: Type,
  $source_name: string,
  $destination_name: string,
  $foreign_key: string
) -> Type {
  HasMany :: struct {
    associate :: (
      source_records: []$S,
      destination_records: []$D
    ) -> []HasManyPreloaded(
      S,
      D,
      source_name,
      destination_name
    ) {
      associated_source_records := NewArray(
        source_records.count,
        HasManyPreloaded(
          S,
          D,
          source_name,
          destination_name
        )
      );
      for * source_record, source_record_index: source_records {
        #insert #run sprint(
          "associated_source_records[source_record_index].% = source_record;\n",
          source_name
        );
        related_destination_records: [..]*D;
        for * destination_record, destination_record_index: destination_records {
          #insert #run () -> string {
            string_builder: String_Builder;
            defer free_buffers(*string_builder);
            print_to_builder(*string_builder, "if destination_record.% == source_record.id {\n", foreign_key);
            print_to_builder(*string_builder, "  array_add(*related_destination_records, destination_record);\n");
            print_to_builder(*string_builder, "}\n");

            return builder_to_string(*string_builder);
          }();
        }
        #insert #run sprint(
          "associated_source_records[source_record_index].% = related_destination_records;\n",
          destination_name
        );
      }
      return associated_source_records;
    };
    preload :: (source_records: []$S) -> []HasManyPreloaded(
      S,
      destination_repo.Record,
      source_name,
      destination_name
    ) {
      source_ids: [..]Any;
      for * source_records {
        array_add(*source_ids, it.id);
      }

      foreign_key_in: SqlWhere(#run sprint("% IN (?)", foreign_key), 1);
      foreign_key_in.args[0] = source_ids;
      
      destination_records := destination_repo.all(*foreign_key_in);
      return HasMany.associate(source_records, destination_records);
    };
  };
  
  return HasMany;
}
