import 'package:flutter/material.dart';

import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../domain/entities/space_role.dart';

/// Secondary invite path (see docs/space_sharing_ux_plan.txt §2) -- the
/// QR/link above this is the fast path; this is for someone who wants to
/// name exactly who gets access instead. Returns the chosen
/// `(email, role)` once sent, or `null` if cancelled.
class InviteByEmailSheet extends StatefulWidget {
  const InviteByEmailSheet({super.key});

  static Future<(String, SpaceRole)?> show(BuildContext context) {
    return showModalBottomSheet<(String, SpaceRole)>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const InviteByEmailSheet(),
    );
  }

  @override
  State<InviteByEmailSheet> createState() => _InviteByEmailSheetState();
}

class _InviteByEmailSheetState extends State<InviteByEmailSheet> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  SpaceRole _role = SpaceRole.editor;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _send() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.of(context).pop((_emailController.text.trim(), _role));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: context.paddingBottom),
      child: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          decoration: BoxDecoration(
            color: context.surfaceElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: context.border.withValues(alpha: 0.8),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                heightBox(20),
                Text(
                  'Invite by email',
                  style: context.titleMedium.copyWith(fontWeight: FontWeight.w700),
                ),
                heightBox(16),
                CustomTextFormField(
                  controller: _emailController,
                  hintText: 'Email address',
                  keyboardType: TextInputType.emailAddress,
                  validator: Validator.validateEmail,
                ),
                heightBox(16),
                Text('Role', style: context.labelMedium.copyWith(color: context.textSecondary)),
                heightBox(8),
                Row(
                  children: [
                    Expanded(
                      child: _RoleOption(
                        label: 'Editor',
                        subtitle: 'Can add documents',
                        selected: _role == SpaceRole.editor,
                        onTap: () => setState(() => _role = SpaceRole.editor),
                      ),
                    ),
                    widthBox(10),
                    Expanded(
                      child: _RoleOption(
                        label: 'Viewer',
                        subtitle: 'Can only view',
                        selected: _role == SpaceRole.viewer,
                        onTap: () => setState(() => _role = SpaceRole.viewer),
                      ),
                    ),
                  ],
                ),
                heightBox(24),
                CustomButton(text: 'Send invite', onPressed: _send),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _RoleOption extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _RoleOption({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? context.primary.withValues(alpha: 0.1) : context.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected ? context.primary : context.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: context.bodyMedium.copyWith(fontWeight: FontWeight.w600),
            ),
            heightBox(2),
            Text(
              subtitle,
              style: context.labelSmall.copyWith(color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}
