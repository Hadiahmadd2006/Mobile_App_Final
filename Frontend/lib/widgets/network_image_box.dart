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
      placeholder: (context, _) => const ColoredBox(
        color: AppColors.surfaceSunk,
        child: Center(
          child: SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
            ),
          ),
        ),
      ),
      errorWidget: (context, _, _) => const ColoredBox(
        color: AppColors.surfaceSunk,
        child: Center(
          child: Icon(
            Icons.image_not_supported_rounded,
            color: AppColors.textMuted,
          ),
        ),
      ),
    );

    if (borderRadius == null) return image;
    return ClipRRect(borderRadius: borderRadius!, child: image);
  }
}
