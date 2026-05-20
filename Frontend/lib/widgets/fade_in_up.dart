import 'package:flutter/material.dart';

/// A lightweight entrance animation — fades and rises its child into place.
/// Echoes the GSAP reveal animations on the SPLIT landing page.
class FadeInUp extends StatefulWidget {
  final Widget child;
  final Duration delay;
  final double offset;

  const FadeInUp({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offset = 28,
  });

  @override
  State<FadeInUp> createState() => _FadeInUpState();
}

class _FadeInUpState extends State<FadeInUp>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _curve;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 620),
    );
    _curve = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    Future<void>.delayed(widget.delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _curve,
      builder: (context, child) {
        return Opacity(
          opacity: _curve.value.clamp(0.0, 1.0),
          child: Transform.translate(
            offset: Offset(0, widget.offset * (1 - _curve.value)),
            child: child,
          ),
        );
      },
      child: widget.child,
    );
  }
}
