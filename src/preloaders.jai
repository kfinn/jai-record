EmptyInverse :: struct {};

PreloadedResult :: struct($preloader: Type) {
  #insert #run sprint(
    #string BODY
      using %: *preloader.Source;
      using %: preloader.Destination;
    BODY,
    preloader.source_name,
    preloader.destination_name
  );
}

preload :: (
  $preloader: Type,
  source_records: []preloader.Source
) -> []PreloadedResult(preloader) {
  return preloader.preload(preloader, source_records);
}
