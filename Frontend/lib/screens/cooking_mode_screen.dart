import 'dart:async';

import 'package:flutter/material.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

/// Full-screen, step-by-step cooking experience for Pro users.
///
/// Keeps the device awake while open and offers per-step quick timers so
/// hands-busy cooks don't have to fumble with a separate stopwatch.
class CookingModeScreen extends StatefulWidget {
  final String title;
  final List<String> steps;

  const CookingModeScreen({
    super.key,
    required this.title,
    required this.steps,
  });

  @override
  State<CookingModeScreen> createState() => _CookingModeScreenState();
}

class _CookingModeScreenState extends State<CookingModeScreen> {
  final PageController _pageController = PageController();
  int _step = 0;

  // Quick-timer state — null when no timer is running.
  Timer? _ticker;
  Duration? _remaining;
  Duration? _initial;

  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    _ticker?.cancel();
    WakelockPlus.disable();
    _pageController.dispose();
    super.dispose();
  }

  void _go(int delta) {
    final next = (_step + delta).clamp(0, widget.steps.length - 1);
    _pageController.animateToPage(
      next,
      duration: const Duration(milliseconds: 280),
      curve: Curves.easeOutCubic,
    );
  }

  void _startTimer(Duration d) {
    _ticker?.cancel();
    setState(() {
      _initial = d;
      _remaining = d;
    });
    _ticker = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      final r = _remaining;
      if (r == null) return;
      if (r.inSeconds <= 1) {
        _ticker?.cancel();
        setState(() {
          _remaining = Duration.zero;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Timer's up — ${_format(_initial ?? Duration.zero)}",
            ),
            duration: const Duration(seconds: 4),
          ),
        );
        return;
      }
      setState(() {
        _remaining = r - const Duration(seconds: 1);
      });
    });
  }

  void _stopTimer() {
    _ticker?.cancel();
    setState(() {
      _remaining = null;
      _initial = null;
    });
  }

  String _format(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // Register a dep on platform brightness so this screen rebuilds when
    // the user flips light/dark while it's open.
    MediaQuery.platformBrightnessOf(context);
    final total = widget.steps.length;
    final isLast = _step == total - 1;
    final isFirst = _step == 0;

    return Scaffold(
      backgroundColor: AppColors.surface,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: close + step counter ─────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 6, 16, 6),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(
                      Icons.close_rounded,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'COOKING MODE',
                          style: AppTextStyles.eyebrow.copyWith(
                            color: AppColors.orange,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.title,
                          style: AppTextStyles.subheading.copyWith(
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${_step + 1} / $total',
                    style: AppTextStyles.label.copyWith(color: AppColors.muted),
                  ),
                ],
              ),
            ),

            // ── Progress bar ───────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_step + 1) / total,
                  minHeight: 4,
                  backgroundColor: AppColors.border,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.orange),
                ),
              ),
            ),

            // ── Swipeable step pages ──────────────────────────────────────
            Expanded(
              child: PageView.builder(
                controller: _pageController,
                itemCount: total,
                onPageChanged: (i) => setState(() => _step = i),
                itemBuilder: (context, i) {
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(28, 24, 28, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'STEP ${i + 1}',
                          style: AppTextStyles.eyebrow.copyWith(
                            color: AppColors.orange,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Expanded(
                          child: SingleChildScrollView(
                            child: Text(
                              widget.steps[i],
                              style: AppTextStyles.body.copyWith(
                                color: AppColors.textPrimary,
                                fontSize: 22,
                                height: 1.45,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),

            // ── Timer panel ───────────────────────────────────────────────
            _TimerPanel(
              remaining: _remaining,
              initial: _initial,
              onPick: _startTimer,
              onStop: _stopTimer,
              format: _format,
            ),

            // ── Prev / Next bar ───────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: isFirst ? null : () => _go(-1),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textPrimary,
                        side: BorderSide(
                          color: AppColors.border,
                          width: 1.4,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: const Text('Back'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        if (isLast) {
                          Navigator.of(context).pop();
                        } else {
                          _go(1);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.orange,
                        foregroundColor: AppColors.textOnDark,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                      child: Text(
                        isLast ? 'Finish' : 'Next step',
                        style: AppTextStyles.button.copyWith(fontSize: 15),
                      ),
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

class _TimerPanel extends StatelessWidget {
  final Duration? remaining;
  final Duration? initial;
  final void Function(Duration) onPick;
  final VoidCallback onStop;
  final String Function(Duration) format;

  const _TimerPanel({
    required this.remaining,
    required this.initial,
    required this.onPick,
    required this.onStop,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    final running = remaining != null;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceSunk,
        borderRadius: BorderRadius.circular(AppTheme.radiusMd),
        border: Border.all(color: AppColors.border),
      ),
      child: running ? _running(context) : _picker(context),
    );
  }

  Widget _picker(BuildContext context) {
    const picks = <int>[1, 3, 5, 10, 15];
    return Row(
      children: [
        Icon(Icons.timer_outlined, size: 18, color: AppColors.orange),
        const SizedBox(width: 10),
        Text(
          'Timer',
          style: AppTextStyles.label.copyWith(color: AppColors.textPrimary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final m in picks) ...[
                  _Chip(
                    label: '${m}m',
                    onTap: () => onPick(Duration(minutes: m)),
                  ),
                  const SizedBox(width: 6),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _running(BuildContext context) {
    final r = remaining ?? Duration.zero;
    final i = initial ?? const Duration(minutes: 1);
    final progress = i.inSeconds == 0
        ? 0.0
        : 1.0 - (r.inSeconds / i.inSeconds);
    final done = r.inSeconds == 0;
    return Row(
      children: [
        SizedBox(
          width: 30,
          height: 30,
          child: CircularProgressIndicator(
            value: progress,
            strokeWidth: 3,
            backgroundColor: AppColors.border,
            valueColor: AlwaysStoppedAnimation<Color>(
              done ? AppColors.success : AppColors.orange,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          format(r),
          style: AppTextStyles.subheading.copyWith(
            color: done ? AppColors.success : AppColors.textPrimary,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
        ),
        const Spacer(),
        TextButton(
          onPressed: onStop,
          style: TextButton.styleFrom(foregroundColor: AppColors.muted),
          child: const Text('Stop'),
        ),
      ],
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _Chip({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(50),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(50),
            border: Border.all(color: AppColors.border),
          ),
          child: Text(
            label,
            style: AppTextStyles.tag.copyWith(
              color: AppColors.textPrimary,
              letterSpacing: 0.4,
            ),
          ),
        ),
      ),
    );
  }
}

/// Splits a free-form MealDB instructions blob into discrete steps.
///
/// Prefers double-newline separation; falls back to single newlines, then
/// sentence boundaries. Trims and drops empty fragments.
List<String> splitInstructionsIntoSteps(String raw) {
  final cleaned = raw.replaceAll('\r\n', '\n').trim();
  if (cleaned.isEmpty) return const [];

  Iterable<String> parts;
  if (cleaned.contains('\n\n')) {
    parts = cleaned.split('\n\n');
  } else if (cleaned.contains('\n')) {
    parts = cleaned.split('\n');
  } else {
    // Sentence-boundary split — keep the period.
    parts = cleaned.split(RegExp(r'(?<=[.!?])\s+'));
  }

  return parts
      .map((p) => p.trim())
      .where((p) => p.isNotEmpty)
      .toList(growable: false);
}
