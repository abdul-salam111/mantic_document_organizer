import 'package:flutter/material.dart';

import '../../../../../core/di/di_exports.dart';
import '../../../../../core/localization/localization_exports.dart';
import '../../../../../core/theme/theme_exports.dart';
import '../../../../../core/utils/utils_exports.dart';
import '../../../../../core/widgets/widgets_exports.dart';
import '../../../../../routes/routes_exports.dart';
import '../../../../home/home_exports.dart';
import '../../../domain/entities/chat_message.dart';
import '../viewmodels/ai_assistant_viewmodel.dart';

class AiAssistantView extends StatefulWidget {
  const AiAssistantView({super.key});

  @override
  State<AiAssistantView> createState() => _AiAssistantViewState();
}

class _AiAssistantViewState extends State<AiAssistantView> {
  final ScrollController _scrollController = ScrollController();

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send(AiAssistantViewModel vm) async {
    await vm.send();
    if (mounted) _scrollToBottom();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) {
        final vm = sl<AiAssistantViewModel>();
        vm.failureText = AppLocalizations.of(context).aiAssistantGenericError;
        return vm;
      },
      child: Scaffold(
        appBar: CustomAppBar(
          title: AppLocalizations.of(context).aiAssistantTitle,
        ),
        body: SafeArea(
          child: Consumer<AiAssistantViewModel>(
            builder: (context, vm, _) {
              final examples = [
                AppLocalizations.of(context).aiAssistantExample1,
                AppLocalizations.of(context).aiAssistantExample2,
                AppLocalizations.of(context).aiAssistantExample3,
              ];
              return Column(
                children: [
                  Expanded(
                    child: vm.messages.isEmpty
                        ? const _EmptyState()
                        : ListView.builder(
                            controller: _scrollController,
                            padding: const .all(14),
                            itemCount: vm.messages.length,
                            itemBuilder: (context, index) => _MessageBubble(
                              message: vm.messages[index],
                              vm: vm,
                            ),
                          ),
                  ),
                  _InputBar(
                    vm: vm,
                    onSend: () => _send(vm),
                    examples: vm.messages.isEmpty ? examples : const [],
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final AiAssistantViewModel vm;

  const _MessageBubble({required this.message, required this.vm});

  bool get _isUser => message.role == ChatRole.user;

  @override
  Widget build(BuildContext context) {
    final bubbleColor = message.isError
        ? context.error.withValues(alpha: 0.1)
        : _isUser
        ? context.primary
        : context.surfaceElevated;
    final textColor = message.isError
        ? context.error
        : _isUser
        ? context.white
        : context.textPrimary;

    return Padding(
      padding: const .only(bottom: 12),
      child: Column(
        crossAxisAlignment: _isUser ? .end : .start,
        children: [
          Container(
            constraints: BoxConstraints(maxWidth: context.screenWidth * 0.78),
            padding: const .symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: bubbleColor,
              borderRadius: BorderRadius.only(
                topLeft: .circular(14),
                topRight: .circular(14),
                bottomLeft: .circular(_isUser ? 14 : 2),
                bottomRight: .circular(_isUser ? 2 : 14),
              ),
              border: message.isError
                  ? Border.all(color: context.error.withValues(alpha: 0.4))
                  : null,
            ),
            child: Text(
              message.text,
              style: context.bodyMedium.copyWith(color: textColor),
            ),
          ),
          if (message.documentIds.isNotEmpty) ...[
            heightBox(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final id in message.documentIds)
                  if (vm.documentById(id) case final document?)
                    _DocumentReferenceCard(document: document),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

/// A small tappable card resolving an assistant answer's referenced
/// [DocumentItem] — opens straight into the Document Viewer, same as
/// tapping a document anywhere else in the app.
class _DocumentReferenceCard extends StatelessWidget {
  final DocumentItem document;

  const _DocumentReferenceCard({required this.document});

  @override
  Widget build(BuildContext context) {
    final color = categoryIconColor(context, document.category);
    return InkWell(
      borderRadius: .circular(12),
      onTap: () =>
          AppNavigator.pushNamed(RouteNames.documentViewer, extra: document),
      child: Container(
        width: 170,
        padding: const .all(8),
        decoration: BoxDecoration(
          color: context.surface,
          borderRadius: .circular(12),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            DocumentCoverThumbnail(
              document: document,
              color: color,
              width: 40,
              height: 40,
              borderRadius: 8,
              iconSize: 16,
            ),
            widthBox(8),
            Expanded(
              child: Text(
                document.title,
                maxLines: 2,
                overflow: .ellipsis,
                style: context.labelSmall.copyWith(fontWeight: .w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const .all(24),
        child: Column(
          mainAxisSize: .min,
          children: [
            Icon(
              Iconsax.message_question,
              size: 64,
              color: context.textSecondary,
            ),
            heightBox(16),
            Text(
              AppLocalizations.of(context).aiAssistantEmptyTitle,
              textAlign: .center,
              style: context.titleMedium.copyWith(fontWeight: .w700),
            ),
            heightBox(6),
            Text(
              AppLocalizations.of(context).aiAssistantEmptySubtitle,
              textAlign: .center,
              style: context.bodySmall.copyWith(color: context.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

/// A tappable, pill-shaped example question — fills the input with
/// [text] rather than sending immediately, so the user can still edit it
/// first.
class _ExampleChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _ExampleChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: .circular(20),
      child: Container(
        alignment: .center,
        padding: const .symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: context.primary.withValues(alpha: 0.08),
          borderRadius: .circular(20),
          border: Border.all(color: context.primary.withValues(alpha: 0.25)),
        ),
        child: Row(
          mainAxisSize: .min,
          children: [
            Icon(Iconsax.magicpen, size: 14, color: context.primary),
            widthBox(6),
            Text(
              text,
              style: context.labelSmall.copyWith(
                color: context.primary,
                fontWeight: .w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InputBar extends StatelessWidget {
  final AiAssistantViewModel vm;
  final VoidCallback onSend;

  /// Shown as a horizontally-scrollable chip strip directly above the text
  /// field — empty once the conversation has started (these are starter
  /// prompts, not a persistent quick-reply bar).
  final List<String> examples;

  const _InputBar({
    required this.vm,
    required this.onSend,
    required this.examples,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        top: 10,
        bottom: 10 + context.paddingBottom.clamp(0, 12),
      ),
      decoration: BoxDecoration(
        color: context.surface,
        boxShadow: [
          BoxShadow(
            color: context.shadow,
            blurRadius: 12,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: .min,
          crossAxisAlignment: .stretch,
          children: [
            if (examples.isNotEmpty) ...[
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: .horizontal,
                  padding: const .symmetric(horizontal: 12),
                  itemCount: examples.length,
                  separatorBuilder: (context, index) => widthBox(8),
                  itemBuilder: (context, index) => _ExampleChip(
                    text: examples[index],
                    onTap: () => vm.inputController.text = examples[index],
                  ),
                ),
              ),
              heightBox(10),
            ],
            Padding(
              padding: const .symmetric(horizontal: 12),
              child: Row(
                crossAxisAlignment: .end,
                children: [
                  Expanded(
                    child: Container(
                      constraints: const BoxConstraints(minHeight: 48),
                      padding: const .symmetric(horizontal: 18, vertical: 6),
                      decoration: BoxDecoration(
                        color: context.surfaceElevated,
                        borderRadius: .circular(26),
                        border: Border.all(color: context.border),
                      ),
                      child: TextField(
                        controller: vm.inputController,
                        minLines: 1,
                        maxLines: 4,
                        textCapitalization: .sentences,
                        textInputAction: .send,
                        onSubmitted: (_) => onSend(),
                        style: context.bodyMedium.copyWith(
                          color: context.textPrimary,
                        ),
                        decoration: InputDecoration(
                          isCollapsed: true,
                          border: InputBorder.none,
                          hintText: AppLocalizations.of(
                            context,
                          ).aiAssistantInputHint,
                          hintStyle: context.bodyMedium.copyWith(
                            color: context.textSecondary,
                          ),
                        ),
                      ),
                    ),
                  ),
                  widthBox(10),
                  _SendButton(vm: vm, onTap: onSend),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Fills with [context.primary] and lights up only once there's something
/// to send — a flat grey circle otherwise reads as "disabled" without
/// needing a separate opacity treatment. Listens to [vm.inputController]
/// directly (a [TextEditingController] is already a [Listenable]) so it
/// reacts on every keystroke without waiting for the ViewModel's own
/// [ChangeNotifier] tick.
class _SendButton extends StatelessWidget {
  final AiAssistantViewModel vm;
  final VoidCallback onTap;

  const _SendButton({required this.vm, required this.onTap});

  static const double _size = 48;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: vm.inputController,
      builder: (context, _) {
        final canSend =
            !vm.isSending && vm.inputController.text.trim().isNotEmpty;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: _size,
          height: _size,
          decoration: BoxDecoration(
            color: canSend ? context.primary : context.grey300,
            shape: .circle,
          ),
          child: InkWell(
            onTap: canSend ? onTap : null,
            borderRadius: .circular(_size / 2),
            child: Center(child: _icon(context)),
          ),
        );
      },
    );
  }

  Widget _icon(BuildContext context) => vm.isSending
      ? SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            color: context.white,
          ),
        )
      : Icon(Iconsax.send_1, color: context.white, size: 20);
}
