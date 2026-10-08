import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../../../routes/routes_exports.dart';
import '../../../domain/entities/space_entity.dart';
import '../../../domain/entities/space_role.dart';

/// The shared "you're in" moment every join path converges on (see
/// docs/space_sharing_ux_plan.txt §3) -- a tapped invite link, a scanned
/// QR, or re-joining a space the person is already a member of (the
/// backend's accept is idempotent, so this looks identical either way).
class JoinResultView extends StatelessWidget {
  final SpaceEntity space;
  final SpaceRole role;

  const JoinResultView({super.key, required this.space, required this.role});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: context.success.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Iconsax.tick_circle,
                  size: 44,
                  color: context.success,
                ),
              ),
              heightBox(24),
              Text(
                "You've joined",
                style: context.bodyMedium.copyWith(
                  color: context.textSecondary,
                ),
              ),
              heightBox(4),
              Text(
                space.name,
                textAlign: TextAlign.center,
                style: context.headlineSmall.copyWith(fontWeight: .bold),
              ),
              heightBox(10),
              _RoleBadge(role: role),
              heightBox(32),
              CustomButton(
                text: 'Open ${space.name}',
                onPressed: () => AppNavigator.goNamed(RouteNames.home),
              ),
              heightBox(10),
              TextButton(
                onPressed: () => AppNavigator.goNamed(RouteNames.home),
                child: const Text('Done'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RoleBadge extends StatelessWidget {
  final SpaceRole role;

  const _RoleBadge({required this.role});

  @override
  Widget build(BuildContext context) {
    final isEditor = role == SpaceRole.editor || role == SpaceRole.owner;
    final color = isEditor ? context.primary : context.textSecondary;
    final label = switch (role) {
      SpaceRole.owner => 'Owner',
      SpaceRole.editor => 'Editor — you can add documents',
      SpaceRole.viewer => 'Viewer — you can see documents',
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: context.labelMedium.copyWith(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
