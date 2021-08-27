NestedPreloader :: struct(
  $parent: Type,
  $child: Type
) {
  fetch :: fetch_nested_preloader;
  associate :: associate_nested_preloader;
  Fetched :: struct {
    parent: parent.Fetched;
    child: child.Fetched;
  };

  Source :: parent.Source;
  source_name :: parent.source_name;

  Destination :: struct {
    #insert #run () -> string {
      string_builder: String_Builder;
      defer free_buffers(*string_builder);

      #insert #run () -> string {
        #insert #run sprint("parent_destination_type := type_info(type_of(parent.Destination.%));\n", parent.destination_inner_name);
        parent_destination_type_is_array := parent_destination_type.type == .ARRAY;
        return sprint("parent_destination_type_is_array :: %;\n", parent_destination_type_is_array);
      }();
      #if parent_destination_type_is_array {
        print_to_builder(*string_builder, "%: []*PreloadedResult(child);\n", parent.destination_inner_name);
      } else {
        print_to_builder(*string_builder, "%: *PreloadedResult(child);\n", parent.destination_inner_name);
      }

      return builder_to_string(*string_builder);
    }();
  }
  destination_name :: #run sprint("nested_%_and_%", parent.destination_name, child.destination_name);
}

nested_preloader :: ($parent: Type, $child: Type) -> Type {
  return NestedPreloader(parent, child);
}

fetch_nested_preloader :: (
  $nested_preloader: $NestedPreloaderType, // TypeDotHack
  source_records: []nested_preloader.Source
) -> nested_preloader.Fetched {
  result: nested_preloader.Fetched;
  result.parent = preloader_fetch(
    nested_preloader.parent,
    source_records
  );
  result.child = preloader_fetch(
    nested_preloader.child,
    result.parent
  );
  return result;
}

associate_nested_preloader :: (
  $nested_preloader: $NestedPreloaderType, // TypeDotHack
  source_records: []nested_preloader.Source,
  fetched_records: nested_preloader.Fetched
) -> []PreloadedResult(nested_preloader) {
  nested_results := NewArray(
    source_records.count,
    PreloadedResult(nested_preloader)
  );

  parent_associated_results := preloader_associate(
    nested_preloader.parent,
    source_records,
    fetched_records.parent
  );

  child_associated_results := preloader_associate(
    nested_preloader.child,
    fetched_records.parent,
    fetched_records.child
  );

  find_child_associated_result :: (results: []$T, p: $P) -> T {
    for results {
      #insert #run sprint("it_parent := it.%;\n", child.source_name);
      if it_parent == p return it;
    }
  }

  for * nested_results {
    source_record := *source_records[it_index];
    parent_record := *parent_associated_results[it_index];

    // if parent_associated_result.#{nested_preloader.parent.destination_inner_name} is an array, this is a little harder

    #insert #run sprint(
      "it.% = source_record;\n",
      nested_preloader.source_name
    );

    #insert #run () -> string {
      #insert #run sprint("parent_destination_type := type_info(type_of(nested_preloader.parent.Destination.%));\n", nested_preloader.parent.destination_inner_name);
      parent_destination_type_is_array := parent_destination_type.type == .ARRAY;
      return sprint("parent_destination_type_is_array :: %;\n", parent_destination_type_is_array);
    }();

    #if parent_destination_type_is_array {
      #insert #run sprint("unnested_records := parent_record.%;\n", nested_preloader.parent.destination_inner_name);
      nested_records := NewArray(unnested_records.count, *PreloadedResult(nested_preloader.child));
      for unnested_record, unnested_record_index: unnested_records {
        for * child_associated_result: child_associated_results {
          #insert #run sprint("child_associated_result_source := child_associated_result.%;\n", nested_preloader.child.source_name);
          if child_associated_result_source == unnested_record {
            nested_records[unnested_record_index] = child_associated_result;
            break;
          }
        }
      }
      #insert #run sprint(
        "it.% = nested_records;\n",
        nested_preloader.parent.destination_inner_name
      );
    } else {
      #insert #run sprint("unnested_record := parent_record.%;\n", nested_preloader.parent.destination_inner_name);
      nested_record: *PreloadedResult(nested_preloader.child);
      for * child_associated_result: child_associated_results {
        #insert #run sprint("child_associated_result_source := child_associated_result.%;\n", nested_preloader.child.source_name);
        if child_associated_result_source == unnested_record {
          nested_record = child_associated_result;
          break;
        }
      }
      #insert #run sprint(
        "it.% = nested_record;\n",
        nested_preloader.parent.destination_inner_name
      );
    }
  }

  return nested_results;
}
