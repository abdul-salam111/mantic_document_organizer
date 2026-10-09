import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/constants/constants_exports.dart';
import '../../../../../core/di/di_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../../../routes/routes_exports.dart';
import '../../../../categories/domain/entities/category_item.dart';
import '../../../../home/home_exports.dart' show categoryIconColor;
import '../../../domain/entities/member_entity.dart';
import '../../../domain/entities/pending_invitation_entity.dart';
import '../../../domain/entities/space_role.dart';
import '../viewmodel/share_category_viewmodel.dart';
import '../widgets/invite_by_email_sheet.dart';
import '../widgets/share_confirmation_sheet.dart';

/// The Share screen (see docs/space_sharing_ux_plan.txt §2) -- reached
/// from Manage Categories' Share action or a shared category's own
/// people-badge. Never creates a second space for an already-shared
/// category: [ShareCategoryViewModel.isAlreadyShared] gates whether the
/// one-time confirmation + creation step below runs at all.
class ShareCategoryView extends StatefulWidget {
  final CategoryItem category;

  const ShareCategoryView({super.key, required this.category});

  @override
  State<ShareCategoryView> createState() => _ShareCategoryViewState();
}

class _ShareCategoryViewState extends State<ShareCategoryView> {
  late final ShareCategoryViewModel _vm;

  @override
  void initState() {
    super.initState();
    _vm = sl<ShareCategoryViewModel>()..initWith(widget.category);
    if (_vm.isAlreadyShared) {
      unawaited(_vm.loadAll());
    } else {
      WidgetsBinding.instance.addPostFrameCallback((_) => _confirmAndShare());
    }
  }

  Future<void> _confirmAndShare() async {
    final confirmed = await ShareConfirmationSheet.show(
      context,
      categoryName: widget.category.name,
    );
    if (!mounted) return;
    if (!confirmed) {
      AppNavigator.pop();
      return;
    }
    final ok = await _vm.shareNow();
    if (!ok && mounted) AppNavigator.pop();
  }

  Future<void> _inviteByEmail() async {
    final invite = await InviteByEmailSheet.show(context);
    if (invite == null) return;
    await _vm.inviteByEmail(email: invite.$1, role: invite.$2);
  }

  Future<void> _confirmRemoveMember(MemberEntity member) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: context.surfaceElevated,
        title: const Text('Remove member?'),
        content: Text(
          'Remove ${member.displayName} from ${_vm.category.name}? '
          "They'll lose access to its documents immediately.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: Text('Remove', style: TextStyle(color: context.error)),
          ),
        ],
      ),
    );
    if (confirmed == true) await _vm.removeMember(member.userId);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider<ShareCategoryViewModel>.value(
      value: _vm,
      child: Consumer<ShareCategoryViewModel>(
        builder: (context, vm, _) => Scaffold(
          appBar: CustomAppBar(
            title: vm.category.name,
            onBackPressed: () => Navigator.of(context).pop(),
            backgroundColor: context.background,
            foregroundColor: context.textPrimary,
          ),
          body: SafeArea(
            child: vm.isPreparing
                ? const Center(child: LoadingIndicator())
                : !vm.isAlreadyShared
                ? const SizedBox.shrink()
                : RefreshIndicator(
                    onRefresh: vm.refreshAll,
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                      children: [
                        _Header(vm: vm),
                        heightBox(20),
                        if (vm.isOwner) ...[
                          _QrAndLinkCard(vm: vm),
                          heightBox(16),
                          _InviteByEmailRow(onTap: _inviteByEmail),
                          heightBox(24),
                        ],
                        _MembersSection(vm: vm, onRemove: _confirmRemoveMember),
                        if (vm.isOwner && vm.pendingInvitations.isNotEmpty) ...[
                          heightBox(20),
                          _PendingInvitationsSection(vm: vm),
                        ],
                        heightBox(24),
                        _SyncNowRow(vm: vm),
                      ],
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final ShareCategoryViewModel vm;

  const _Header({required this.vm});

  @override
  Widget build(BuildContext context) {
    final category = vm.category;
    final color =
        (category.colorValue == null ? null : Color(category.colorValue!)) ??
        categoryIconColor(context, category.name);
    final memberCount = vm.members.length;
    return Row(
      children: [
        Container(
          width: 52,
          height: 52,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: FaIcon(iconForKey(category.iconKey), size: 22, color: context.white),
        ),
        widthBox(14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                category.name,
                style: context.titleMedium.copyWith(fontWeight: FontWeight.w700),
              ),
              heightBox(2),
              Text(
                memberCount <= 1
                    ? 'Not shared with anyone yet'
                    : 'Shared with ${memberCount - 1} ${memberCount - 1 == 1 ? 'person' : 'people'}',
                style: context.labelSmall.copyWith(color: context.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _QrAndLinkCard extends StatelessWidget {
  final ShareCategoryViewModel vm;

  const _QrAndLinkCard({required this.vm});

  @override
  Widget build(BuildContext context) {
    final url = vm.joinLinkUrl;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: context.shadow, blurRadius: 5, offset: const Offset(0, 2)),
        ],
      ),
      child: Column(
        children: [
          if (url == null)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: LoadingIndicator()),
            )
          else ...[
            // Always a plain white card with real padding (the quiet zone),
            // regardless of app theme -- a QR code needs strong
            // black-on-white contrast to scan reliably. Never tint this to
            // match dark mode.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: QrImageView(
                data: url,
                size: 220,
                backgroundColor: Colors.white,
                eyeStyle: const QrEyeStyle(eyeShape: QrEyeShape.square, color: Colors.black),
                dataModuleStyle: const QrDataModuleStyle(
                  dataModuleShape: QrDataModuleShape.square,
                  color: Colors.black,
                ),
              ),
            ),
            heightBox(12),
            Text(
              'Anyone who scans this joins as an Editor and can add documents.',
              textAlign: TextAlign.center,
              style: context.labelSmall.copyWith(color: context.textSecondary),
            ),
            heightBox(16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: context.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: context.border),
              ),
              child: Text(
                url,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: context.labelSmall.copyWith(color: context.textSecondary),
              ),
            ),
            heightBox(12),
            Row(
              children: [
                Expanded(
                  child: CustomButton(
                    text: 'Copy link',
                    icon: Iconsax.copy,
                    iconSize: 18,
                    backgroundColor: context.surface,
                    textColor: context.textPrimary,
                    iconColor: context.textSecondary,
                    borderColor: context.border,
                    elevation: 0,
                    size: const Size(0, 46),
                    onPressed: () async {
                      await Clipboard.setData(ClipboardData(text: url));
                      AppToastsUtils.success('Copied.');
                    },
                  ),
                ),
                widthBox(10),
                Expanded(
                  child: CustomButton(
                    text: 'Share link',
                    icon: Iconsax.share,
                    iconSize: 18,
                    size: const Size(0, 46),
                    onPressed: () => SharePlus.instance.share(
                      ShareParams(
                        text:
                            'Join "${vm.category.name}" on Mantic Document Organizer: $url',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            heightBox(10),
            Text(
              'They’ll need Mantic Document Organizer installed to open this link.',
              textAlign: TextAlign.center,
              style: context.labelSmall.copyWith(color: context.textSecondary),
            ),
          ],
        ],
      ),
    );
  }
}

class _InviteByEmailRow extends StatelessWidget {
  final VoidCallback onTap;

  const _InviteByEmailRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Iconsax.sms, size: 16, color: context.primary),
            widthBox(6),
            Text(
              'Prefer to invite by email instead?',
              style: context.labelMedium.copyWith(
                color: context.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MembersSection extends StatelessWidget {
  final ShareCategoryViewModel vm;
  final void Function(MemberEntity member) onRemove;

  const _MembersSection({required this.vm, required this.onRemove});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Members', style: context.titleSmall.copyWith(fontWeight: FontWeight.w700)),
        heightBox(10),
        if (vm.isLoading && vm.members.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(16), child: LoadingIndicator()))
        else
          ...vm.members.map(
            (member) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MemberRow(
                vm: vm,
                member: member,
                onRemove: () => onRemove(member),
              ),
            ),
          ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  final ShareCategoryViewModel vm;
  final MemberEntity member;
  final VoidCallback onRemove;

  const _MemberRow({required this.vm, required this.member, required this.onRemove});

  String get _initials {
    final parts = member.displayName.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    final letters = [for (final part in parts.take(2)) part[0].toUpperCase()].join();
    return letters.isEmpty ? '?' : letters;
  }

  @override
  Widget build(BuildContext context) {
    final isOwnerRow = member.role == SpaceRole.owner;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            alignment: Alignment.center,
            decoration: BoxDecoration(color: context.primary.withValues(alpha: 0.15), shape: BoxShape.circle),
            child: Text(
              _initials,
              style: context.labelMedium.copyWith(color: context.primary, fontWeight: FontWeight.w700),
            ),
          ),
          widthBox(10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  member.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  member.email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.labelSmall.copyWith(color: context.textSecondary),
                ),
              ],
            ),
          ),
          if (isOwnerRow)
            _RolePill(label: 'Owner')
          else if (vm.isOwner) ...[
            _RoleDropdown(
              role: member.role,
              onChanged: (role) => vm.updateMemberRole(userId: member.userId, role: role),
            ),
            IconButton(
              onPressed: onRemove,
              icon: Icon(Iconsax.close_circle, size: 20, color: context.error),
              tooltip: 'Remove',
            ),
          ] else
            _RolePill(label: member.role == SpaceRole.editor ? 'Editor' : 'Viewer'),
        ],
      ),
    );
  }
}

class _RolePill extends StatelessWidget {
  final String label;

  const _RolePill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: context.textSecondary.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(99),
      ),
      child: Text(
        label,
        style: context.labelSmall.copyWith(color: context.textSecondary, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _RoleDropdown extends StatelessWidget {
  final SpaceRole role;
  final void Function(SpaceRole role) onChanged;

  const _RoleDropdown({required this.role, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return DropdownButton<SpaceRole>(
      value: role,
      underline: const SizedBox.shrink(),
      style: context.labelSmall.copyWith(color: context.textPrimary),
      items: const [
        DropdownMenuItem(value: SpaceRole.editor, child: Text('Editor')),
        DropdownMenuItem(value: SpaceRole.viewer, child: Text('Viewer')),
      ],
      onChanged: (value) {
        if (value != null) onChanged(value);
      },
    );
  }
}

class _PendingInvitationsSection extends StatelessWidget {
  final ShareCategoryViewModel vm;

  const _PendingInvitationsSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Pending invitations',
          style: context.titleSmall.copyWith(fontWeight: FontWeight.w700),
        ),
        heightBox(10),
        ...vm.pendingInvitations.map(
          (invitation) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _PendingInvitationRow(vm: vm, invitation: invitation),
          ),
        ),
      ],
    );
  }
}

class _PendingInvitationRow extends StatelessWidget {
  final ShareCategoryViewModel vm;
  final PendingInvitationEntity invitation;

  const _PendingInvitationRow({required this.vm, required this.invitation});

  @override
  Widget build(BuildContext context) {
    final daysLeft = invitation.expiresAt.difference(DateTime.now()).inDays;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  invitation.invitedEmail,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                ),
                Text(
                  daysLeft > 0 ? 'Invited — expires in $daysLeft days' : 'Invited — expiring soon',
                  style: context.labelSmall.copyWith(color: context.textSecondary),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: () => vm.revokeInvitation(invitation.id),
            icon: Icon(Iconsax.close_circle, size: 20, color: context.error),
            tooltip: 'Revoke',
          ),
        ],
      ),
    );
  }
}

class _SyncNowRow extends StatelessWidget {
  final ShareCategoryViewModel vm;

  const _SyncNowRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(Iconsax.refresh, size: 20, color: context.primary),
          widthBox(10),
          Expanded(
            child: Text(
              vm.isSyncing ? 'Syncing…' : 'Keep documents up to date on every device',
              style: context.bodySmall.copyWith(color: context.textSecondary),
            ),
          ),
          TextButton(
            onPressed: vm.isSyncing ? null : vm.syncNow,
            child: const Text('Sync now'),
          ),
        ],
      ),
    );
  }
}
