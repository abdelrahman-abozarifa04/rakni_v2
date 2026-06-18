import 'package:flutter/material.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';

/// Immutable data object returned by [FilterBottomSheet].
class FilterConfig {
  final double minPrice;
  final double maxPrice;
  final double maxDistance;
  final Set<String> slotTypes;

  const FilterConfig({
    required this.minPrice,
    required this.maxPrice,
    required this.maxDistance,
    required this.slotTypes,
  });

  /// Returns true if the parking lot price matches this filter's price range.
  bool matchesPrice(double pricePerHour) =>
      pricePerHour >= minPrice && pricePerHour <= maxPrice;

  /// Slot type labels exactly as stored in Firestore ('regular', 'ev', 'disabled').
  Set<String> get firestoreSlotTypes => slotTypes
      .map((t) => t.toLowerCase().replaceAll(' ', ''))
      .toSet();
}

class FilterBottomSheet extends StatefulWidget {
  const FilterBottomSheet({super.key});

  /// Shows the filter sheet and returns a [FilterConfig] when applied, or
  /// `null` if the user dismisses without applying.
  static Future<FilterConfig?> show(BuildContext context) {
    return showModalBottomSheet<FilterConfig>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => const FilterBottomSheet(),
    );
  }

  @override
  State<FilterBottomSheet> createState() => _FilterBottomSheetState();
}

class _FilterBottomSheetState extends State<FilterBottomSheet> {
  RangeValues _priceRange = const RangeValues(5, 50);
  double _maxDistance = 5.0;
  final Set<String> _selectedSlotTypes = {'Regular'};
  static const _slotTypes = ['Regular', 'EV', 'Disabled'];
  static const Map<String, IconData> _slotIcons = {
    'Regular': Icons.directions_car,
    'EV': Icons.electric_car,
    'Disabled': Icons.accessible,
  };

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.hintColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: 20),
          Text(
            'Filter Parking',
            style: TextStyle(
              color: AppColors.white,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: 24),
          _lbl('Price Range (EGP/hr)'),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'EGP ${_priceRange.start.round()}',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                'EGP ${_priceRange.end.round()}',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.secondary,
              inactiveTrackColor: AppColors.fieldStroke,
              thumbColor: AppColors.secondary,
              overlayColor: AppColors.secondary.withValues(alpha: 0.2),
              rangeThumbShape:
                  const RoundRangeSliderThumbShape(enabledThumbRadius: 8),
            ),
            child: RangeSlider(
              values: _priceRange,
              min: 5,
              max: 50,
              divisions: 9,
              onChanged: (v) => setState(() => _priceRange = v),
            ),
          ),
          SizedBox(height: 20),
          _lbl('Slot Type'),
          SizedBox(height: 12),
          _buildSlotChips(),
          SizedBox(height: 24),
          _lbl('Max Distance'),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_maxDistance.toStringAsFixed(1)} km',
                style: TextStyle(
                  color: AppColors.secondary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '10 km',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
              ),
            ],
          ),
          SliderTheme(
            data: SliderThemeData(
              activeTrackColor: AppColors.secondary,
              inactiveTrackColor: AppColors.fieldStroke,
              thumbColor: AppColors.secondary,
              overlayColor: AppColors.secondary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: _maxDistance,
              min: 0.5,
              max: 10,
              divisions: 19,
              onChanged: (v) => setState(() => _maxDistance = v),
            ),
          ),
          SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(
                context,
                FilterConfig(
                  minPrice: _priceRange.start,
                  maxPrice: _priceRange.end,
                  maxDistance: _maxDistance,
                  slotTypes: Set.from(_selectedSlotTypes),
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.secondary,
                foregroundColor: AppColors.black,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                'Apply Filters',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
              ),
            ),
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom),
        ],
      ),
    );
  }

  Widget _lbl(String t) => Text(
        t,
        style: TextStyle(
          color: AppColors.white.withValues(alpha: 0.9),
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      );

  Widget _buildSlotChips() => Row(
        children: _slotTypes.map((type) {
          final sel = _selectedSlotTypes.contains(type);
          return Padding(
            padding: const EdgeInsets.only(right: 10),
            child: GestureDetector(
              onTap: () => setState(
                () => sel
                    ? _selectedSlotTypes.remove(type)
                    : _selectedSlotTypes.add(type),
              ),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: sel
                      ? AppColors.secondary.withValues(alpha: 0.15)
                      : AppColors.fieldColor,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: sel ? AppColors.secondary : AppColors.fieldStroke,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _slotIcons[type],
                      size: 18,
                      color: sel ? AppColors.secondary : AppColors.hintColor,
                    ),
                    SizedBox(width: 6),
                    Text(
                      type,
                      style: TextStyle(
                        color: sel
                            ? AppColors.secondary
                            : AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      );
}
