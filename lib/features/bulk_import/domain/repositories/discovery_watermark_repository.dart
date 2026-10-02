abstract interface class DiscoveryWatermarkRepository {
  Future<DateTime?> read();
  Future<void> write(DateTime value);
}
