import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class EgyptianLicensePlate extends StatelessWidget {
  final String plateNumber;
  final double width;
  final bool useThemeColors;

  const EgyptianLicensePlate({
    super.key,
    required this.plateNumber,
    this.width = 160,
    this.useThemeColors = true,
  });

  @override
  Widget build(BuildContext context) {
    final Color headerBg = useThemeColors ? AppColors.accent : const Color(0xFF0056B3);
    final Color headerTextCol = useThemeColors ? AppColors.black : Colors.white;
    final Color bodyBg = useThemeColors ? AppColors.surface : Colors.white;
    final Color bodyTextCol = useThemeColors ? AppColors.white : Colors.black;
    final Color borderCol = useThemeColors ? AppColors.accent.withAlpha(120) : Colors.black;
    final Color dividerCol = useThemeColors ? AppColors.fieldStroke : Colors.black;

    return Container(
      width: width,
      decoration: BoxDecoration(
        color: bodyBg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderCol, width: useThemeColors ? 1.5 : 2),
        boxShadow: [
          BoxShadow(
            color: useThemeColors
                ? AppColors.accent.withAlpha(30)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: useThemeColors ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Blue Header Band
          Container(
            height: 20,
            decoration: BoxDecoration(
              color: headerBg,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'EGYPT',
                  style: TextStyle(
                    color: headerTextCol,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                    fontFamily: 'monospace',
                  ),
                ),
                Text(
                  'مصر',
                  style: TextStyle(
                    color: headerTextCol,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          // Divider line
          Container(height: 1, color: dividerCol),
          // License Number Body
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            child: Text(
              plateNumber.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: bodyTextCol,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
                fontFamily: 'monospace', // Gives a stamped mechanical plate look
              ),
            ),
          ),
        ],
      ),
    );
  }
}
