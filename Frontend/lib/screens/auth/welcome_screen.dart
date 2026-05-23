import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../routing/app_router.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';
import '../../widgets/sunburst.dart';

/// The first screen a signed-out visitor sees.
///
/// Acts as a marketing landing page: brand, hero image, two clear CTAs
/// pointing to Sign In and Sign Up. Once authenticated the GoRouter
/// redirect skips this screen entirely on subsequent launches.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      body: SafeArea(
        child: Stack(
          children: [
            Positioned(
              top: -120,
              right: -100,
              child: IgnorePointer(
                child: Sunburst(
                  size: 400,
                  color: AppColors.orange.withValues(alpha: 0.10),
                ),
              ),
            ),
            Positioned(
              bottom: -150,
              left: -100,
              child: IgnorePointer(
                child: Sunburst(
                  size: 360,
                  color: AppColors.lime.withValues(alpha: 0.10),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(
                AppTheme.spaceLg,
                AppTheme.spaceLg,
                AppTheme.spaceLg,
                AppTheme.spaceXl,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'TerraBite',
                        style: AppTextStyles.heading.copyWith(fontSize: 28),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        width: 12,
                        height: 12,
                        decoration: BoxDecoration(
                          color: AppColors.orange,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    'NO SHORTCUTS · JUST FLAVOUR',
                    style: AppTextStyles.eyebrow,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  Text(
                    'Cook better.\nEat slower.',
                    style: AppTextStyles.hero,
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  Text(
                    'Browse hundreds of recipes from TheMealDB, save your '
                    'favourites with personal notes, and unlock the Michelin '
                    'collection with Pro.',
                    style: AppTextStyles.body.copyWith(fontSize: 16),
                  ),
                  const SizedBox(height: AppTheme.spaceXl),
                  ElevatedButton(
                    onPressed: () => context.go(AppRoutes.signUp),
                    child: const Text('CREATE AN ACCOUNT'),
                  ),
                  const SizedBox(height: AppTheme.spaceSm + 2),
                  OutlinedButton(
                    onPressed: () => context.go(AppRoutes.signIn),
                    child: const Text('SIGN IN'),
                  ),
                  const SizedBox(height: AppTheme.spaceMd),
                  Center(
                    child: Text(
                      'Free forever · Pro unlocks Michelin recipes',
                      style: AppTextStyles.label,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

