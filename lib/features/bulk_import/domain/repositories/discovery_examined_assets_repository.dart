/// The exact, per-asset "have I already examined this" record for one
/// discovery source -- the authoritative dedup check, independent of any
/// asset date field. See [DiscoveryWatermarkRepository] for the companion,
/// coarse date-based window this works alongside: the watermark bounds how
/// far back a scan bothers walking at all; this decides, precisely, which
/// of the assets found within that window have already been looked at.
abstract interface class DiscoveryExaminedAssetsRepository {
  /// Returns the subset of [assetIds] not already marked examined.
  Future<List<String>> filterUnexamined(List<String> assetIds);

  /// Marks every one of [assetIds] as examined. Idempotent -- marking an
  /// already-marked id again is a no-op.
  Future<void> markExamined(List<String> assetIds);
}
