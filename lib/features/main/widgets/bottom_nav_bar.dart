import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:rakni_v2/core/localization/app_strings.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';

/// A bottom navigation bar with a floating "bump" effect on the active item.
/// The active icon elevates above the bar inside a colored circle, with a
/// smooth notch carved into the bar beneath it.
///
/// Supports both LTR (English) and RTL (Arabic) layouts by computing a
/// visual index that mirrors the slot positions in RTL mode.
///
/// IMPORTANT: Uses [LayoutBuilder] to get the actual rendered width of the
/// widget, NOT [MediaQuery.of(context).size.width]. On web the app is
/// constrained to 430 px inside _WebShell; MediaQuery would return the full
/// browser window width (~1280 px+), causing the bubble to fly far outside
/// the visible frame.
class RakniBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const RakniBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  static const _svgPaths = [
    'assets/images/home_Icon.svg',
    'assets/images/map_Icon.svg',
    'assets/images/booking_Icon.svg',
    'assets/images/vehicle.svg',
    'assets/images/profile_Icon.svg',
  ];

  @override
  Widget build(BuildContext context) {
    const double barHeight = 64;
    const double bubbleSize = 56;
    const double bubbleLift = 24; // how far the bubble protrudes above the bar

    // Localized labels — read at build time so they update on locale change.
    final labels = [
      AppStrings.navHome,
      AppStrings.navMap,
      AppStrings.navBookings,
      AppStrings.navVehicles,
      AppStrings.navProfile,
    ];

    final itemCount = _svgPaths.length;
    final isRtl = Directionality.of(context) == TextDirection.rtl;

    // In RTL the visual order of slots is reversed: slot 0 appears on the
    // right. We must mirror the active index so the notch and bubble are
    // drawn at the correct physical x position.
    final visualActiveIndex = isRtl ? (itemCount - 1 - currentIndex) : currentIndex;

    final bottomPadding = MediaQuery.of(context).padding.bottom;

    // LayoutBuilder gives us the actual rendered width of the nav bar widget,
    // which is constrained to 430 px on web by _WebShell. This is the key fix
    // for the bubble flying outside the frame on desktop browsers.
    return LayoutBuilder(
      builder: (context, constraints) {
        final containerWidth = constraints.maxWidth;

        return SizedBox(
          height: barHeight + bubbleLift + bottomPadding,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // ── Bar background with notch ──────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: CustomPaint(
                  painter: _NotchedBarPainter(
                    activeIndex: visualActiveIndex,
                    itemCount: itemCount,
                    notchRadius: (bubbleSize / 2) + 8,
                    barColor: AppColors.navBarBackground,
                    barHeight: barHeight + bottomPadding,
                  ),
                  child: SizedBox(
                    height: barHeight + bottomPadding,
                  ),
                ),
              ),

              // ── Tap areas + inactive icons ─────────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: bottomPadding,
                child: SizedBox(
                  height: barHeight,
                  child: Row(
                    children: List.generate(itemCount, (i) {
                      final isActive = i == currentIndex;
                      return Expanded(
                        child: GestureDetector(
                          onTap: () => onTap(i),
                          behavior: HitTestBehavior.opaque,
                          child: AnimatedOpacity(
                            opacity: isActive ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SvgPicture.asset(
                                  _svgPaths[i],
                                  height: 20,
                                  colorFilter: ColorFilter.mode(
                                    AppColors.textSecondary,
                                    BlendMode.srcIn,
                                  ),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  labels[i],
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ),

              // ── Floating active bubble ─────────────────────────────────────────
              // Uses containerWidth from LayoutBuilder (actual widget width),
              // NOT MediaQuery.of(context).size.width (full browser window width).
              AnimatedPositioned(
                duration: const Duration(milliseconds: 300),
                curve: Curves.easeOutBack,
                left: (visualActiveIndex / itemCount) * containerWidth +
                    (containerWidth / itemCount / 2) -
                    bubbleSize / 2,
                bottom: bottomPadding + barHeight - bubbleLift - bubbleSize / 2 + 12,
                child: GestureDetector(
                  onTap: () => onTap(currentIndex),
                  child: Container(
                    width: bubbleSize,
                    height: bubbleSize,
                    decoration: BoxDecoration(
                      color: AppColors.secondary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.secondary.withValues(alpha: 0.45),
                          blurRadius: 16,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: SvgPicture.asset(
                        _svgPaths[currentIndex],
                        height: 26,
                        colorFilter: ColorFilter.mode(
                          AppColors.black,
                          BlendMode.srcIn,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Custom painter — bar with a smooth circular notch
// ---------------------------------------------------------------------------

class _NotchedBarPainter extends CustomPainter {
  final int activeIndex;
  final int itemCount;
  final double notchRadius;
  final Color barColor;
  final double barHeight;

  const _NotchedBarPainter({
    required this.activeIndex,
    required this.itemCount,
    required this.notchRadius,
    required this.barColor,
    required this.barHeight,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = barColor
      ..style = PaintingStyle.fill;

    final slotWidth = size.width / itemCount;
    final notchCenterX = slotWidth * activeIndex + slotWidth / 2;
    const notchDepth = 18.0; // how deep the notch dips into the bar
    const notchTop = 0.0;

    final path = Path();
    path.moveTo(0, notchTop);

    final leftEdge = notchCenterX - notchRadius * 1.4;
    final rightEdge = notchCenterX + notchRadius * 1.4;

    // Left flat portion
    path.lineTo(leftEdge - 10, notchTop);

    // Left curve into notch
    path.cubicTo(
      leftEdge,
      notchTop,
      notchCenterX - notchRadius,
      notchTop + notchDepth,
      notchCenterX,
      notchTop + notchDepth,
    );

    // Right curve out of notch
    path.cubicTo(
      notchCenterX + notchRadius,
      notchTop + notchDepth,
      rightEdge,
      notchTop,
      rightEdge + 10,
      notchTop,
    );

    // Right flat, bottom edges
    path.lineTo(size.width, notchTop);
    path.lineTo(size.width, barHeight);
    path.lineTo(0, barHeight);
    path.close();

    canvas.drawPath(path, paint);

    // Top border line
    final borderPaint = Paint()
      ..color = AppColors.fieldStroke
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final borderPath = Path();
    borderPath.moveTo(0, notchTop);
    borderPath.lineTo(leftEdge - 10, notchTop);
    borderPath.cubicTo(
      leftEdge,
      notchTop,
      notchCenterX - notchRadius,
      notchTop + notchDepth,
      notchCenterX,
      notchTop + notchDepth,
    );
    borderPath.cubicTo(
      notchCenterX + notchRadius,
      notchTop + notchDepth,
      rightEdge,
      notchTop,
      rightEdge + 10,
      notchTop,
    );
    borderPath.lineTo(size.width, notchTop);
    canvas.drawPath(borderPath, borderPaint);
  }

  @override
  bool shouldRepaint(_NotchedBarPainter old) =>
      old.activeIndex != activeIndex ||
      old.notchRadius != notchRadius ||
      old.barColor != barColor;
}
