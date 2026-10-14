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
}
