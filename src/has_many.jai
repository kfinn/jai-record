IdIn :: SqlWhere("id IN ?", 1);

HasMany :: struct(
  $source_repo: Type,
  $destination_repo: Type,
  $source_name: string,
  $destination_inner_name: string,
  $foreign_key: string,
  $inverse_of: Type = EmptyInverse
) {
  #if inverse_of == EmptyInverse {
    Destination :: struct {
      #insert #run sprint("%: []*destination_repo.Record;\n", destination_inner_name);
    }
    preload :: preload_has_many_without_inverse;
  } else {
    Destination :: struct {
      #insert #run sprint("%: []*PreloadedResult(inverse_of);\n", destination_inner_name);
    }
    preload :: preload_has_many_with_inverse;
  }
  Source :: source_repo.Record;
  destination_name :: #run sprint("preloaded_%", destination_inner_name);
}

associate_has_many :: (
  $has_many: Type,
  source_records: []has_many.source_repo.Record,
  destination_records: []$D
) -> []PreloadedResult(has_many) {
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

preload_has_many_without_inverse :: (
  $has_many: Type,
  source_records: []has_many.source_repo.Record
) -> []PreloadedResult(has_many) {
  source_ids: [..]Any;
  for * source_records {
    array_add(*source_ids, it.id);
  }

  foreign_key_in: SqlWhere(#run sprint("% IN (?)", has_many.foreign_key), 1);
  foreign_key_in.args[0] = source_ids;

  destination_records := has_many.destination_repo.all(*foreign_key_in);

  return associate_has_many(
    has_many,
    source_records,
    destination_records
  );
}

preload_has_many_with_inverse :: (
  $has_many: Type,
  source_records: []has_many.source_repo.Record
) -> []PreloadedResult(has_many) {
  source_ids: [..]Any;
  for * source_records {
    array_add(*source_ids, it.id);
  }

  foreign_key_in: SqlWhere(#run sprint("% IN (?)", has_many.foreign_key), 1);
  foreign_key_in.args[0] = source_ids;

  destination_records := has_many.destination_repo.all(*foreign_key_in);

  destination_records_with_inverses := associate_belongs_to(
    has_many.inverse_of,
    destination_records,
    source_records
  );

  return associate_has_many(
    has_many,
    source_records,
    destination_records_with_inverses
  );
}
