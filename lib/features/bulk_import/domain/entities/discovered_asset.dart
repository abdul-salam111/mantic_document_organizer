/// One photo-library asset found during gallery discovery, before it has
/// been staged into a [BulkImportCandidate]. [resolvePath] is lazy because
/// reading the actual file (as opposed to its metadata) is the expensive
/// step discovery's cheap filters exist to avoid doing for every asset.
class DiscoveredAsset {
  final String id;
  // Despite the name, this is the timestamp used for the recency filter and
  // watermark -- "when did this land on the device" -- not necessarily the
  // asset's original creation/capture date. See each discovery datasource's
  // own assignment of this field for why.
  final DateTime takenAt;
  final Future<String?> Function() resolvePath;

  const DiscoveredAsset({
    required this.id,
    required this.takenAt,
    required this.resolvePath,
  });
}
