import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// A small lock chip used to mark Pro-gated regular meals in list rows.
///
/// Render it as a Positioned child inside the Stack that contains the
/// recipe thumbnail. Free users get a clear visual signal that the
/// recipe lives behind the Pro paywall.
class ProLockOverlay extends StatelessWidget {
  final double size;

  const ProLockOverlay({super.key, this.size = 22});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.orange,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.textOnDark, width: 1.5),
      ),
      child: Icon(
        Icons.lock_rounded,
        color: AppColors.textOnDark,
        size: size * 0.55,
      ),
    );
  }
}

/// Full-thumbnail dim + center lock — used when a tile's image area is
/// large enough to warrant a more prominent treatment than the chip.
class ProLockScrim extends StatelessWidget {
  const ProLockScrim({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Container(color: Colors.black.withValues(alpha: 0.32)),
        Center(child: ProLockOverlay(size: 32)),
      ],
    );
  }
}
