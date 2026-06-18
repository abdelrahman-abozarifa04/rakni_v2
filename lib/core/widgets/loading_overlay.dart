import 'package:flutter/material.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';

/// A transparent overlay that blocks interaction and shows a centered
/// [CircularProgressIndicator] while [isLoading] is true.
///
/// Usage:
/// ```dart
/// LoadingOverlay(
///   isLoading: _isLoading,
///   child: MyWidget(),
/// )
/// ```
class LoadingOverlay extends StatelessWidget {
  const LoadingOverlay({
    super.key,
    required this.isLoading,
    required this.child,
  });

  final bool isLoading;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        child,
        if (isLoading)
          Positioned.fill(
            child: ColoredBox(
              color: const Color(0x80000000),
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: CircularProgressIndicator(
                    color: AppColors.secondary,
                    strokeWidth: 3,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }
}
