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
  $preloader: $PreloaderType, // TypeDotHack
  source_records: []preloader.Source
) -> []PreloadedResult(preloader) {
  destination_records := preloader_fetch(preloader, source_records);
  return preloader_associate(preloader, source_records, destination_records);
}

preloader_fetch :: (
  $preloader: $PreloaderType, // TypeDotHack
  source_records: []preloader.Source
) -> preloader.Fetched {
  return preloader.fetch(preloader, source_records);
}

preloader_associate :: (
  $preloader: $PreloaderType, // TypeDotHack
  source_records: []preloader.Source,
  destination_records: preloader.Fetched
) -> []PreloadedResult(preloader) {
  return preloader.associate(preloader, source_records, destination_records);
}
