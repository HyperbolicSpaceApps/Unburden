class StorageLocation {
  final String name;
  final double? widthCm;
  final double? depthCm;
  final double? heightCm;
  final List<String> contents;
  final String accessNote;

  StorageLocation({
    required this.name,
    this.widthCm,
    this.depthCm,
    this.heightCm,
    required this.contents,
    required this.accessNote,
  });
}
