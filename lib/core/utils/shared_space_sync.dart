import 'dart:async';

import '../background/document_sync_background_service.dart';
import '../services/services_exports.dart';

/// Call right after a local mutation (add/edit/move/delete) to a document
/// that lives in a shared category, so the change reaches the other
/// members without anyone having to manually hit "Sync now" first -- see
/// docs/space_sharing_ux_plan.txt's sync triggers. [spaceId] should be
/// `CategoryItem.spaceId` of whichever category the mutation affects (the
/// document's own, or -- for a move -- its destination); pass `null` for
/// a plain, unshared category and this is a no-op.
///
/// Fire-and-forget by design: the mutation itself must stay instant, the
/// same way the Share screen's own "Sync now" button runs in the
/// background rather than blocking its tap.
void triggerSharedSpaceSyncIfNeeded({
  required DocumentSyncBackgroundService syncBackgroundService,
  required String? spaceId,
}) {
  final token = SessionController.instance.userToken;
  if (spaceId == null || token == null) return;
  unawaited(
    syncBackgroundService.runSpaceSync(
      token: token,
      spaceId: spaceId,
      isPersonalSpace: false,
    ),
  );
}
