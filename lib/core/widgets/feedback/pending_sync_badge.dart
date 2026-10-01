import 'package:flutter/material.dart';

import '../../database/app_database.dart';
import '../../di/injection_container.dart';

/// A restrained status marker for a document whose local change is safely
/// queued but has not reached the backup yet. It intentionally has no tap
/// action: backup controls remain in the Backup screen.
class PendingSyncBadge extends StatelessWidget {
  const PendingSyncBadge({super.key, required this.documentId, this.size = 24});

  final String documentId;
  final double size;

  @override
  Widget build(BuildContext context) => ValueListenableBuilder<Set<String>>(
    valueListenable: sl<AppDatabase>().pendingDocumentIds,
    builder: (context, pendingIds, _) {
      if (!pendingIds.contains(documentId)) return const SizedBox.shrink();
      return Tooltip(
        message: 'Waiting to back up',
        child: Container(
          width: size,
          height: size,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: .58),
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white.withValues(alpha: .45)),
          ),
          child: Icon(
            Icons.cloud_upload_outlined,
            size: size * .58,
            color: const Color(0xFFFFC857),
          ),
        ),
      );
    },
  );
}
