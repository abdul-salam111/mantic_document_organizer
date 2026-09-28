import 'package:flutter/material.dart';

import '../../utils/widget_utils.dart';

/// Shared timing math for a staggered list/grid reveal — a **fixed real
/// delay per item** ([itemDelay]), not a delay normalized against a
/// shared fixed-length window. Normalizing against a fixed window shrinks
/// the gap between items to a few imperceptible milliseconds on a short
/// list (e.g. 3 items spread across a 450ms window), which is what made
/// the very first version of this look like the whole list fading in at
/// once instead of a visible cascade. A fixed delay keeps every list
/// visibly staggered regardless of how many items it has.
class StaggeredRevealTiming {
  const StaggeredRevealTiming._();

  /// How much later each successive item starts revealing than the one
  /// before it.
  static const Duration itemDelay = Duration(milliseconds: 70);

  /// How long each individual item's own fade + slide takes once it starts.
  static const Duration itemDuration = Duration(milliseconds: 380);

  /// Items from this index onward all start at the same time as this one,
  /// so a very long list doesn't push the total reveal out unreasonably
  /// far.
  static const int maxStaggeredItems = 12;

  static int _staggeredIndex(int index) => index.clamp(0, maxStaggeredItems);

  /// Total duration an [AnimationController] driving [itemCount] items
  /// needs to play every item's reveal to completion — pass the same
  /// [itemCount] used for [intervalFor] so the two stay in sync.
  static Duration totalDuration(int itemCount) =>
      itemDelay * _staggeredIndex(itemCount) + itemDuration;

  /// The [Interval] (as fractions of [totalDuration]) that [index]'s own
  /// reveal occupies within a controller sized for [itemCount] items.
  static Interval intervalFor(int itemCount, int index) {
    final totalMs = totalDuration(itemCount).inMilliseconds;
    final startMs = itemDelay.inMilliseconds * _staggeredIndex(index);
    final endMs = startMs + itemDuration.inMilliseconds;
    return Interval(
      startMs / totalMs,
      (endMs / totalMs).clamp(0.0, 1.0),
      curve: Curves.easeOut,
    );
  }
}

/// Owns a single [AnimationController] (started immediately, played once)
/// and hands it to [builder] as the shared "reveal" animation for
/// [StaggeredRevealItem] — lets any list/grid screen add a staggered
/// cascade-in without becoming a `StatefulWidget` itself just to manage a
/// controller's lifecycle. Since Flutter keeps a widget's `State` alive
/// across rebuilds in the same tree position, the reveal plays once when
/// this widget first mounts (e.g. a tab's first appearance in an
/// `IndexedStack`) and later rebuilds (a favorite toggle, a new item
/// added) don't replay it — only remounting this widget fresh (e.g.
/// switching grid/list view, which swaps the underlying child type) does.
class StaggeredReveal extends StatefulWidget {
  /// How many items this reveal will drive — sets the controller's total
  /// duration (see [StaggeredRevealTiming.totalDuration]). Pass the same
  /// count given to each child [StaggeredRevealItem].
  final int itemCount;

  final Widget Function(BuildContext context, Animation<double> reveal) builder;

  const StaggeredReveal({
    super.key,
    required this.itemCount,
    required this.builder,
  });

  @override
  State<StaggeredReveal> createState() => _StaggeredRevealState();
}

class _StaggeredRevealState extends State<StaggeredReveal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: StaggeredRevealTiming.totalDuration(widget.itemCount),
  )..forward();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.builder(context, _controller);
}

/// Fades + slides one list/grid item in, its start time offset by [index]
/// relative to [reveal] (from a parent [StaggeredReveal]) so items cascade
/// in one after another instead of all at once — see
/// [StaggeredRevealTiming] for the delay math. [itemCount] must match the
/// value passed to the enclosing [StaggeredReveal] so this item's
/// [Interval] lines up with that controller's actual duration.
class StaggeredRevealItem extends StatelessWidget {
  final Animation<double> reveal;
  final int itemCount;
  final int index;
  final Widget child;

  /// Where the item slides in from — small and subtle by default (a
  /// vertical list settling upward); pass a horizontal offset (e.g.
  /// `Offset(0.12, 0)`) for a horizontally-scrolling strip instead.
  final Offset beginOffset;

  const StaggeredRevealItem({
    super.key,
    required this.reveal,
    required this.itemCount,
    required this.index,
    required this.child,
    this.beginOffset = const Offset(0, 0.08),
  });

  @override
  Widget build(BuildContext context) {
    final itemAnimation = CurvedAnimation(
      parent: reveal,
      curve: StaggeredRevealTiming.intervalFor(itemCount, index),
    );
    return child
        .withFadeAnimation(itemAnimation)
        .withSlideAnimation(
          Tween<Offset>(
            begin: beginOffset,
            end: Offset.zero,
          ).animate(itemAnimation),
        );
  }
}
