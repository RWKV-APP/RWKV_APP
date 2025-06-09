String gbDisplay(int size) {
  final sizeGB = size / 1024.0 / 1024.0 / 1024.0;
  if (sizeGB > .1) return "${sizeGB.toStringAsFixed(1)} GB";
  if (sizeGB > .01) return "${sizeGB.toStringAsFixed(2)} GB";
  return "0.01 GB";
}
