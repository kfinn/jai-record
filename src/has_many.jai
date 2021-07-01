IdIn :: SqlWhere("id IN ?", 1);

HasManyPreloaded :: struct($Source: Type, $Destination: Type, $name: string) {
  using record: *Source;
  #insert #run sprint("%: []*Destination;\n", name);
}

has_many :: (
  $source_repo: Type,
  $destination_repo: Type,
  $name: string,
  $foreign_key: string
) -> Type {
  Preloaded :: HasManyPreloaded(
    source_repo.Record,
    destination_repo.Record,
    name
  );

  return struct {
    Record :: Preloaded;
    preload :: (records: []source_repo.Record) -> []Preloaded {
      source_ids: [..]Any;
      for * records {
        array_add(*source_ids, it.id);
      }

      foreign_key_in: SqlWhere(#run sprint("% IN (?)", foreign_key), 1);
      foreign_key_in.args[0] = source_ids;
      
      destination_records := destination_repo.all(*foreign_key_in);

      results := NewArray(records.count, Preloaded);
      for * record, record_index: records {
        results[record_index].record = record;
        related_destination_records: [..]*destination_repo.Record;
        for * destination_record, destination_record_index: destination_records {
          #insert #run () -> string {
            string_builder: String_Builder;
            defer free_buffers(*string_builder);
            print_to_builder(*string_builder, "if destination_record.% == record.id {\n", foreign_key);
            print_to_builder(*string_builder, "  array_add(*related_destination_records, destination_record);\n");
            print_to_builder(*string_builder, "}\n");

            return builder_to_string(*string_builder);
          }();
        }
        #insert #run sprint(
          "results[record_index].% = related_destination_records;\n",
          name
        );
      }
      return results;
    };
  };
}
