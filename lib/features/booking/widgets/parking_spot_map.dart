import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:rakni_v2/core/models/parking_slot_model.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';

class ParkingSpotMap extends StatelessWidget {
  static const String carAsset = 'assets/images/slots_car_image.png';

  final List<ParkingSlotModel> slots;
  final String? selectedSlotId;
  final String? targetSlotId;
  final bool showRoute;
  final double routeProgress;
  final ValueChanged<ParkingSlotModel>? onSlotTap;

  const ParkingSpotMap({
    super.key,
    required this.slots,
    this.selectedSlotId,
    this.targetSlotId,
    this.showRoute = false,
    this.routeProgress = 1,
    this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    final rows = math.max(4, (slots.length + 3) ~/ 4);
    final naturalHeight = math.max(360.0, rows * 68.0 + 64.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasBoundedHeight =
            constraints.maxHeight.isFinite && constraints.maxHeight > 0;
        final height = hasBoundedHeight ? constraints.maxHeight : naturalHeight;

        return Container(
          height: height,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.fieldStroke.withValues(alpha: 0.35),
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Stack(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
                  child: Column(
                    children: [
                      for (int row = 0; row < rows; row++) ...[
                        Expanded(
                          child: _ParkingMapRow(
                            slots: slots,
                            row: row,
                            selectedSlotId: selectedSlotId,
                            targetSlotId: targetSlotId,
                            onSlotTap: onSlotTap,
                          ),
                        ),
                        if (row != rows - 1) const SizedBox(height: 10),
                      ],
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.login_rounded,
                            color: AppColors.accent,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'ENTRANCE',
                            style: TextStyle(
                              color: AppColors.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Container(
                            width: 1,
                            height: 12,
                            color: AppColors.white.withValues(alpha: 0.15),
                          ),
                          const SizedBox(width: 16),
                          const Icon(
                            Icons.logout_rounded,
                            color: AppColors.error,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'EXIT',
                            style: TextStyle(
                              color: AppColors.error,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (showRoute && targetSlotId != null)
                  Positioned.fill(
                    child: IgnorePointer(
                      child: CustomPaint(
                        painter: _RoutePainter(
                          slots: slots,
                          targetSlotId: targetSlotId!,
                          rows: rows,
                          progress: routeProgress,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ParkingMapRow extends StatelessWidget {
  final List<ParkingSlotModel> slots;
  final int row;
  final String? selectedSlotId;
  final String? targetSlotId;
  final ValueChanged<ParkingSlotModel>? onSlotTap;

  const _ParkingMapRow({
    required this.slots,
    required this.row,
    required this.selectedSlotId,
    required this.targetSlotId,
    required this.onSlotTap,
  });

  @override
  Widget build(BuildContext context) {
    final aisleWidth = MediaQuery.sizeOf(context).width < 380 ? 44.0 : 64.0;

    return Row(
      children: [
        Expanded(
          child: Row(
            children: [
              Expanded(child: _slotAt(row * 4)),
              SizedBox(width: 10),
              Expanded(child: _slotAt(row * 4 + 1)),
            ],
          ),
        ),
        SizedBox(
          width: aisleWidth,
          child: Center(
            child: Container(
              width: 1,
              color: Colors.white.withValues(alpha: 0.14),
            ),
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _slotAt(row * 4 + 2)),
              SizedBox(width: 10),
              Expanded(child: _slotAt(row * 4 + 3)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _slotAt(int index) {
    if (index >= slots.length) {
      return const SizedBox.shrink();
    }

    final slot = slots[index];
    final isSelected = selectedSlotId == slot.id;
    final isTarget = targetSlotId == slot.id || targetSlotId == slot.slotNumber;
    final isOccupied = !slot.isAvailable && !isTarget;
    final canTap = onSlotTap != null && !isOccupied;

    return GestureDetector(
      onTap: canTap ? () => onSlotTap!(slot) : null,
      child: _SlotBay(
        label: slot.slotNumber,
        isOccupied: isOccupied,
        isSelected: isSelected || isTarget,
      ),
    );
  }
}

class _SlotBay extends StatelessWidget {
  final String label;
  final bool isOccupied;
  final bool isSelected;

  const _SlotBay({
    required this.label,
    required this.isOccupied,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _DashedBayPainter(
        color: isSelected
            ? AppColors.secondary
            : AppColors.textSecondary.withValues(alpha: 0.35),
        fillColor: isSelected
            ? AppColors.secondary.withValues(alpha: 0.08)
            : AppColors.surface,
        strokeWidth: isSelected ? 1.8 : 1,
      ),
      child: Center(
        child: isOccupied
            ? Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
                child: RotatedBox(
                  quarterTurns: 1,
                  child: Image.asset(
                    ParkingSpotMap.carAsset,
                    fit: BoxFit.contain,
                  ),
                ),
              )
            : AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.secondary : AppColors.background.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.secondary
                        : AppColors.textSecondary.withValues(alpha: 0.12),
                  ),
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: isSelected ? Colors.black : AppColors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
      ),
    );
  }
}

class _DashedBayPainter extends CustomPainter {
  final Color color;
  final Color? fillColor;
  final double strokeWidth;

  const _DashedBayPainter({
    required this.color,
    this.fillColor,
    this.strokeWidth = 1,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 4, size.width, size.height - 8);

    if (fillColor != null) {
      canvas.drawRRect(
        RRect.fromRectAndRadius(rect, const Radius.circular(6)),
        Paint()..color = fillColor!,
      );
    }

    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    _drawDashedLine(
      canvas,
      Offset(rect.left, rect.top),
      Offset(rect.right, rect.top),
      paint,
    );
    _drawDashedLine(
      canvas,
      Offset(rect.left, rect.bottom),
      Offset(rect.right, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.left, rect.top),
      Offset(rect.left, rect.bottom),
      paint,
    );
    canvas.drawLine(
      Offset(rect.right, rect.top),
      Offset(rect.right, rect.bottom),
      paint,
    );
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const dashWidth = 7.0;
    const dashGap = 6.0;
    final totalDistance = (end - start).distance;
    final direction = (end - start) / totalDistance;
    var distance = 0.0;

    while (distance < totalDistance) {
      final segmentStart = start + direction * distance;
      final segmentEnd =
          start + direction * math.min(distance + dashWidth, totalDistance);
      canvas.drawLine(segmentStart, segmentEnd, paint);
      distance += dashWidth + dashGap;
    }
  }

  @override
  bool shouldRepaint(_DashedBayPainter oldDelegate) =>
      oldDelegate.color != color ||
      oldDelegate.fillColor != fillColor ||
      oldDelegate.strokeWidth != strokeWidth;
}

class _RoutePainter extends CustomPainter {
  final List<ParkingSlotModel> slots;
  final String targetSlotId;
  final int rows;
  final double progress;

  const _RoutePainter({
    required this.slots,
    required this.targetSlotId,
    required this.rows,
    required this.progress,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final targetIndex = slots.indexWhere(
      (slot) => slot.id == targetSlotId || slot.slotNumber == targetSlotId,
    );
    if (targetIndex == -1) return;

    const padding = 18.0;
    const rowGap = 12.0;
    const slotGap = 10.0;
    final aisleWidth = size.width < 380 ? 44.0 : 64.0;
    final contentW = size.width - padding * 2;
    final sideW = (contentW - aisleWidth) / 2;
    final slotW = (sideW - slotGap) / 2;
    final rowH = (size.height - padding * 2 - rowGap * (rows - 1)) / rows;

    final targetRow = targetIndex ~/ 4;
    final colPos = targetIndex % 4;
    final targetX = colPos < 2
        ? padding + colPos * (slotW + slotGap) + slotW / 2
        : padding +
              sideW +
              aisleWidth +
              (colPos - 2) * (slotW + slotGap) +
              slotW / 2;
    final targetY = padding + targetRow * (rowH + rowGap) + rowH / 2;
    final isLeft = targetX < size.width / 2;
    final routeX = size.width / 2;
    final startY = size.height - padding - 24.0;
    final bendRadius = 12.0;

    final path = Path()..moveTo(routeX, startY);
    path.lineTo(routeX, targetY + bendRadius);
    path.quadraticBezierTo(
      routeX,
      targetY,
      routeX + (isLeft ? -bendRadius : bendRadius),
      targetY,
    );
    path.lineTo(targetX, targetY);

    final metrics = path.computeMetrics().toList();
    if (metrics.isEmpty) return;

    final basePaint = Paint()
      ..color = AppColors.white.withValues(alpha: 0.55)
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(path, basePaint);

    final metric = metrics.first;
    final activeLength = metric.length * progress.clamp(0.0, 1.0);
    final activePath = metric.extractPath(0, activeLength);
    final routePaint = Paint()
      ..color = AppColors.secondary
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(activePath, routePaint);

    final dotPaint = Paint()..color = AppColors.secondary.withValues(alpha: 0.35);
    canvas.drawCircle(Offset(routeX, targetY), 8, dotPaint);
    canvas.drawCircle(
      Offset(routeX, targetY),
      4,
      Paint()..color = AppColors.secondary,
    );
  }

  @override
  bool shouldRepaint(_RoutePainter oldDelegate) =>
      oldDelegate.slots != slots ||
      oldDelegate.targetSlotId != targetSlotId ||
      oldDelegate.rows != rows ||
      oldDelegate.progress != progress;
}
