import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class LoadingView extends StatelessWidget {
  final String? message;

  const LoadingView({super.key, this.message});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 34,
            height: 34,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 18),
            Text(
              message!.toUpperCase(),
              style: AppTextStyles.eyebrow.copyWith(color: AppColors.muted),
            ),
          ],
        ],
      ),
    );
  }
}
