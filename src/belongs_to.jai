BelongsToPreloaded :: struct ($Source: Type, $Destination: Type, $source_name: string, $destination_name: string) {
  #insert #run sprint("using %: *Source;\n", source_name);
  #insert #run sprint("%: *Destination;\n", destination_name);
}

belongs_to :: (
  $source_repo: Type,
  $destination_repo: Type,
  $source_name: string,
  $destination_name: string,
  $foreign_key: string
) -> Type {
  BelongsTo :: struct {
    source_name :: source_name;
    destination_name :: destination_name;
    associate :: (
      source_records: []$S,
      destination_records: []$D
    ) -> []BelongsToPreloaded(S, D, source_name, destination_name) {
      associated_source_records := NewArray(
        source_records.count,
        BelongsToPreloaded(S, D, source_name, destination_name)
      );
      for * source_record, source_record_index: source_records {
        #insert #run sprint(
          "associated_source_records[source_record_index].% = source_record;\n",
          source_name
        );
        related_destination_record: *destination_repo.Record;
        for * destination_record, destination_record_index: destination_records {
          #insert #run () -> string {
            string_builder: String_Builder;
            defer free_buffers(*string_builder);
            print_to_builder(*string_builder, "if destination_record.id == source_record.% {\n", foreign_key);
            print_to_builder(*string_builder, "  related_destination_record = destination_record;\n");
            print_to_builder(*string_builder, "  break;\n");
            print_to_builder(*string_builder, "}\n");

            return builder_to_string(*string_builder);
          }();
        }
        #insert #run sprint(
          "associated_source_records[source_record_index].% = related_destination_record;\n",
          destination_name
        );
      }
      return associated_source_records;
    };
    preload :: (source_records: []$S) -> []BelongsToPreloaded(
      S,
      destination_repo.Record,
      source_name,
      destination_name
    ) {
      destination_ids: [..]Any;
      for * source_records {
        #insert #run sprint(
          "array_add(*destination_ids, it.%);\n",
          foreign_key
        );
      }

      id_in: SqlWhere("id IN (?)", 1);
      id_in.args[0] = destination_ids;

      destination_records := destination_repo.all(*id_in);
      return BelongsTo.associate(source_records, destination_records);
    }
  };

  return BelongsTo;
}
