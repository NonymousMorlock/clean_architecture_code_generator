extension MapExt on Map {
  void addEntry(MapEntry entry) {
    this[entry.key] = entry.value;
  }
}
