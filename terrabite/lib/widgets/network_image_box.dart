import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class NetworkImageBox extends StatelessWidget {
  final String url;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const NetworkImageBox({
    super.key,
    required this.url,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    final image = CachedNetworkImage(
      imageUrl: url,
      fit: fit,
      placeholder: (context, _) => Container(
        color: AppColors.surfaceMuted,
        alignment: Alignment.center,
        child: const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.textMuted),
          ),
        ),
      ),
      errorWidget: (context, _, _) => Container(
        color: AppColors.surfaceMuted,
        alignment: Alignment.center,
        child: const Icon(
          Icons.broken_image_rounded,
          color: AppColors.textMuted,
        ),
      ),
    );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
