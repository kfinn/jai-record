ComposedPreloader :: struct(
  $lhs: Type,
  $rhs: Type,
  $Source: Type,
  $source_name: string
) {
  preload :: preload_composed_preloader;
  lhs_destination_name :: #run sprint("composed_lhs_%", lhs.destination_name);
  rhs_destination_name :: #run sprint("composed_rhs_%", rhs.destination_name);
  Destination :: struct {
    #insert #run sprint("using %: lhs.Destination;\n", lhs_destination_name);
    #insert #run sprint("using %: rhs.Destination;\n", rhs_destination_name);
  };
  destination_name :: #run sprint("%_and_%", lhs.destination_name, rhs.destination_name);
};

compose_preloader :: ($lhs: Type, $rhs: Type) -> Type {
  #assert lhs.Source == rhs.Source;
  #assert lhs.source_name == rhs.source_name;

  return ComposedPreloader(lhs, rhs, lhs.Source, lhs.source_name);
}

preload_composed_preloader :: (
  $composed_preloader: Type,
  source_records: []composed_preloader.lhs.Source
) -> []PreloadedResult(composed_preloader) {
  lhs_preloaded := preload(
    composed_preloader.lhs,
    source_records
  );
  rhs_preloaded := preload(
    composed_preloader.rhs,
    source_records
  );

  composed_results := NewArray(
    source_records.count,
    PreloadedResult(composed_preloader)
  );
  for * composed_results {
    source_record := *source_records[it_index];
    lhs_result := lhs_preloaded[it_index];
    rhs_result := rhs_preloaded[it_index];

    #insert #run sprint(
      "it.% = source_record;\n",
      composed_preloader.source_name
    );
    #insert #run sprint(
      "it.% = lhs_result.%;\n",
      composed_preloader.lhs_destination_name,
      composed_preloader.lhs.destination_name
    );
    #insert #run sprint(
      "it.% = rhs_result.%;\n",
      composed_preloader.rhs_destination_name,
      composed_preloader.rhs.destination_name
    );
  }

  return composed_results;
}
