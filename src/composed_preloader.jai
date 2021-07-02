  ComposedPreloader :: struct(
    $lhs: Type,
    $rhs: Type
  ) {
  Source :: lhs.Source;

  Destination :: struct {
    #insert #run sprint("using composed_%: lhs.Destination;\n", lhs.destination_name);
    #insert #run sprint("using composed_%: rhs.Destination;\n", rhs.destination_name);
  };
  destination_name :: #run sprint("%_and_%", lhs.destination_name, rhs.destination_name);
};

ComposedPreloadedResult :: struct($Source: Type, $Destination: Type, $source_name: string, $destination_name: string) {
  #insert #run sprint("using %: *Source;\n", source_name);
  #insert #run sprint("using %: Destination;\n", destination_name);
}

compose_preloader :: ($lhs: Type, $rhs: Type) -> Type {
  #assert lhs.Source == rhs.Source;
  #assert lhs.source_name == rhs.source_name;

  return ComposedPreloader(lhs, rhs);
}

preload_composed_preloader :: (
  $composed_preloader: Type,
  source_records: []composed_preloader.lhs.Source
) -> []ComposedPreloadedResult(
  composed_preloader.lhs.Source,
  composed_preloader.Destination,
  composed_preloader.lhs.source_name,
  composed_preloader.destination_name
) {
  lhs_preloaded := preload_has_many_without_inverse(
    composed_preloader.lhs,
    source_records
  );
  rhs_preloaded := preload_has_many_without_inverse(
    composed_preloader.rhs,
    source_records
  );

  composed_results := NewArray(
    source_records.count,
    ComposedPreloadedResult(
      composed_preloader.lhs.Source,
      composed_preloader.Destination,
      composed_preloader.lhs.source_name,
      composed_preloader.destination_name
    )
  );
  for * composed_results {
    source_record := *source_records[it_index];
    lhs_result := lhs_preloaded[it_index];
    rhs_result := rhs_preloaded[it_index];

    #insert #run sprint(
      "it.% = source_record;\n",
      composed_preloader.lhs.source_name
    );
    #insert #run sprint(
      "it.% = lhs_result.%;\n",
      composed_preloader.lhs.destination_name,
      composed_preloader.lhs.destination_name
    );
    #insert #run sprint(
      "it.% = rhs_result.%;\n",
      composed_preloader.rhs.destination_name,
      composed_preloader.rhs.destination_name
    );
  }

  return composed_results;
}
