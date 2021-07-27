HasMany :: struct(
  $source_repo: Type,
  $destination_repo: Type,
  $source_name: string,
  $destination_inner_name: string,
  $foreign_key: string,
  $inverse_of: Type = EmptyInverse
) {
  Fetched :: []destination_repo.Record;
  fetch :: fetch_has_many;
  associate :: associate_has_many;

  #if inverse_of == EmptyInverse {
    Destination :: struct {
      #insert #run sprint("%: []*destination_repo.Record;\n", destination_inner_name);
    }
  } else {
    Destination :: struct {
      #insert #run sprint("%: []*PreloadedResult(inverse_of);\n", destination_inner_name);
    }
  }
  Source :: source_repo.Record;
  destination_name :: #run sprint("preloaded_%", destination_inner_name);
}

fetch_has_many :: (
  $has_many: Type,
  source_records: []has_many.Source
) -> has_many.Fetched {
  if !source_records {
    return has_many.destination_repo.Record.[];
  }

  source_ids: [..]has_many.source_repo.IdType;
  for * source_records {
    array_add(*source_ids, it.id);
  }

  foreign_key_in: SqlWhere(#run sprint("% IN (:ids)", has_many.foreign_key), struct { ids: []has_many.source_repo.IdType; });
  foreign_key_in.ids = source_ids;

  return has_many.destination_repo.where(foreign_key_in);
}

associate_has_many :: (
  $has_many: Type,
  source_records: []has_many.Source,
  fetched_records: has_many.Fetched
) -> []PreloadedResult(has_many) {
  #if has_many.inverse_of == EmptyInverse {
    destination_records := fetched_records;
    D :: has_many.destination_repo.Record;
  } else {
    destination_records := associate_belongs_to(
      has_many.inverse_of,
      fetched_records,
      source_records
    );
    D :: PreloadedResult(has_many.inverse_of);
  }

  associated_source_records := NewArray(
    source_records.count,
    PreloadedResult(has_many)
  );
  for * source_record, source_record_index: source_records {
    #insert #run sprint(
      "associated_source_records[source_record_index].% = source_record;\n",
      has_many.source_name
    );
    related_destination_records: [..]*D;
    for * destination_record, destination_record_index: destination_records {
      #insert #run () -> string {
        string_builder: String_Builder;
        defer free_buffers(*string_builder);
        print_to_builder(*string_builder, "if destination_record.% == source_record.id {\n", has_many.foreign_key);
        print_to_builder(*string_builder, "  array_add(*related_destination_records, destination_record);\n");
        print_to_builder(*string_builder, "}\n");

        return builder_to_string(*string_builder);
      }();
    }
    #insert #run sprint(
      "associated_source_records[source_record_index].% = related_destination_records;\n",
      has_many.destination_inner_name
    );
  }
  return associated_source_records;
}
