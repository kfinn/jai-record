BelongsTo :: struct(
  $source_repo: Type,
  $destination_repo: Type,
  $source_name: string,
  $destination_inner_name: string,
  $foreign_key: string,
  $inverse_of: Type = EmptyInverse
) {
  Fetched :: []destination_repo.Record;
  fetch :: fetch_belongs_to;
  associate :: associate_belongs_to;

  #if inverse_of == EmptyInverse {
    Destination :: struct {
      #insert #run sprint("%: *destination_repo.Record;\n", destination_inner_name);
    }
  } else {
    Destination :: struct {
      #insert #run sprint("%: *PreloadedResult(inverse_of);\n", destination_inner_name);
    }
  }
  Source :: source_repo.Record;
  destination_name :: #run sprint("preloaded_%", destination_inner_name);
}

fetch_belongs_to :: (
  $belongs_to: Type,
  source_records: []belongs_to.Source
) -> belongs_to.Fetched {
  destination_ids: [..]Any;
  for * source_records {
    #insert #run sprint(
      "array_add(*destination_ids, it.%);\n",
      belongs_to.foreign_key
    );
  }

  id_in: SqlWhere("id IN (?)", 1);
  id_in.args[0] = destination_ids;

  return belongs_to.destination_repo.all(*id_in);
}

associate_belongs_to :: (
  $belongs_to: Type,
  source_records: []belongs_to.Source,
  fetched_records: belongs_to.Fetched
) -> []PreloadedResult(belongs_to) {
  #if belongs_to.inverse_of == EmptyInverse {
    destination_records := fetched_records;
    D :: belongs_to.destination_repo.Record;
  } else {
    destination_records := associate_has_many(
      belongs_to.inverse_of,
      fetched_records,
      source_records
    );
    D :: PreloadedResult(belongs_to.inverse_of);
  }

  associated_source_records := NewArray(
    source_records.count,
    PreloadedResult(belongs_to)
  );
  for * source_record, source_record_index: source_records {
    #insert #run sprint(
      "associated_source_records[source_record_index].% = source_record;\n",
      belongs_to.source_name
    );
    related_destination_record: *D;
    for * destination_record, destination_record_index: destination_records {
      #insert #run () -> string {
        string_builder: String_Builder;
        defer free_buffers(*string_builder);
        print_to_builder(*string_builder, "if destination_record.id == source_record.% {\n", belongs_to.foreign_key);
        print_to_builder(*string_builder, "  related_destination_record = destination_record;\n");
        print_to_builder(*string_builder, "  break;\n");
        print_to_builder(*string_builder, "}\n");

        return builder_to_string(*string_builder);
      }();
    }
    #insert #run sprint(
      "associated_source_records[source_record_index].% = related_destination_record;\n",
      belongs_to.destination_inner_name
    );
  }
  return associated_source_records;
}
