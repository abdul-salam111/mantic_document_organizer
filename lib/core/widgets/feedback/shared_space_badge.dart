import 'package:flutter/material.dart';
import 'package:iconsax/iconsax.dart';

import '../../theme/theme_exports.dart';

/// The "this category is shared" indicator reused on Home's category
/// tiles and Manage Categories' rows (see
/// docs/space_sharing_ux_plan.txt §1 -- "sharing status should be visible
/// at a glance"). Shows a plain people icon until [memberCount] arrives
/// (see MemberCountCache), then the count beside it. Tapping it jumps
/// straight to that category's existing Share screen -- never creates a
/// new one.
class SharedSpaceBadge extends StatelessWidget {
  final int? memberCount;
  final VoidCallback onTap;

  const SharedSpaceBadge({super.key, required this.memberCount, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = memberCount;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(99),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        decoration: BoxDecoration(
          color: context.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(99),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Iconsax.profile_2user, size: 14, color: context.primary),
            if (count != null) ...[
              const SizedBox(width: 4),
              Text(
                '$count',
                style: context.labelSmall.copyWith(
                  color: context.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
