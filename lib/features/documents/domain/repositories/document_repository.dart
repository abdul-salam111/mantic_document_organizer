import '../entities/document_item.dart';

abstract interface class IDocumentRepository {
  void addListener(void Function() listener);
  void removeListener(void Function() listener);
  List<DocumentItem> get documents;
  List<DocumentItem> get trashedDocuments;
  Future<void> init();
  Future<void> addDocument(DocumentItem document);
  Future<void> toggleFavorite(DocumentItem document);
  Future<void> updateDocument(DocumentItem updated);
  Future<void> trashDocument(String id);
  Future<void> trashDocuments(Iterable<String> ids);
  Future<void> restoreDocument(String id);
  Future<void> permanentlyDeleteDocument(String id);
  Future<void> emptyTrash();
  int countForCategory(String categoryId);

  /// Reschedules every active document's expiry reminder against the
  /// current reminder lead-time preference — called after the user changes
  /// that preference, since reminders already scheduled were computed with
  /// whatever the lead time was at the time.
  Future<void> rescheduleExpiryReminders();

  /// Snoozes [documentId]'s expiry reminder to fire again [by] from now.
  /// A no-op if [documentId] isn't an active document (e.g. it was
  /// trashed between the snooze button being shown and tapped).
  Future<void> snoozeExpiryReminder(String documentId, Duration by);

  /// The document that already has an attachment with the exact same
  /// bytes as the file at [path] -- a candidate page/photo not yet saved
  /// -- or null if nothing matches. Checks both active and trashed
  /// documents (callers distinguish via [DocumentItem.isTrashed] and
  /// label a trashed match differently, never restoring it implicitly).
  /// [excludeDocumentId] leaves out the document currently being edited,
  /// so re-saving its own unchanged pages never flags itself.
  Future<DocumentItem?> findDuplicateOf(
    String path, {
    String? excludeDocumentId,
  });
}
