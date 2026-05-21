import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

/// The skewed, infinitely scrolling espresso ticker bar from the SPLIT site.
class MarqueeTicker extends StatefulWidget {
  final List<String> items;
  final double pixelsPerSecond;

  const MarqueeTicker({
    super.key,
    required this.items,
    this.pixelsPerSecond = 55,
  });

  @override
  State<MarqueeTicker> createState() => _MarqueeTickerState();
}

class _MarqueeTickerState extends State<MarqueeTicker>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  final GlobalKey _trackKey = GlobalKey();
  double _trackWidth = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 20),
    )..repeat();
    WidgetsBinding.instance.addPostFrameCallback((_) => _measure());
  }

  void _measure() {
    final size = _trackKey.currentContext?.size;
    if (size == null) return;
    final width = size.width;
    if (width > 0 && width != _trackWidth) {
      setState(() {
        _trackWidth = width;
        final seconds = (width / widget.pixelsPerSecond).clamp(8, 80).round();
        _controller
          ..duration = Duration(seconds: seconds)
          ..reset()
          ..repeat();
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Widget _buildTrack() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        for (final item in widget.items) ...[
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 22),
            child: Text(item.toUpperCase(), style: AppTextStyles.ticker),
          ),
          Text(
            '✦',
            style: AppTextStyles.ticker.copyWith(
              color: AppColors.orange,
              fontSize: 16,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.items.isEmpty) return const SizedBox.shrink();

    final track = _buildTrack();
    final Widget content = _trackWidth == 0
        ? KeyedSubtree(key: _trackKey, child: track)
        : AnimatedBuilder(
            animation: _controller,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [track, track],
            ),
            builder: (context, child) => Transform.translate(
              offset: Offset(-_controller.value * _trackWidth, 0),
              child: child,
            ),
          );

    return Transform(
      transform: Matrix4.identity()..setEntry(1, 0, -0.03),
      alignment: Alignment.center,
      child: ColoredBox(
        color: AppColors.surfaceDark,
        child: SizedBox(
          height: 56,
          width: double.infinity,
          child: ClipRect(
            child: OverflowBox(
              alignment: Alignment.centerLeft,
              minWidth: 0,
              maxWidth: double.infinity,
              child: content,
            ),
          ),
        ),
      ),
    );
  }
}
