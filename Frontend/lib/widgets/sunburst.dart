import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A slowly rotating sunburst — the spinning radial backdrop from SPLIT.
class Sunburst extends StatefulWidget {
  final double size;
  final Color? color;

  const Sunburst({super.key, required this.size, this.color});

  @override
  State<Sunburst> createState() => _SunburstState();
}

class _SunburstState extends State<Sunburst>
    with SingleTickerProviderStateMixin {
  static const int _rays = 22;

  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 44),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  List<Color> get _colors {
    final rayColor = widget.color ?? AppColors.orange;
    final list = <Color>[];
    for (var i = 0; i < _rays; i++) {
      final c = i.isEven ? rayColor : const Color(0x00000000);
      list
        ..add(c)
        ..add(c);
    }
    return list;
  }

  List<double> get _stops {
    final list = <double>[];
    for (var i = 0; i < _rays; i++) {
      list
        ..add(i / _rays)
        ..add((i + 1) / _rays);
    }
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: RotationTransition(
        turns: _controller,
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: SweepGradient(colors: _colors, stops: _stops),
          ),
        ),
      ),
    );
  }
}
