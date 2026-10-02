/// One photo-library asset found during gallery discovery, before it has
/// been staged into a [BulkImportCandidate]. [resolvePath] is lazy because
/// reading the actual file (as opposed to its metadata) is the expensive
/// step discovery's cheap filters exist to avoid doing for every asset.
class DiscoveredAsset {
  final String id;
  final DateTime takenAt;
  final Future<String?> Function() resolvePath;

  const DiscoveredAsset({
    required this.id,
    required this.takenAt,
    required this.resolvePath,
  });
}
