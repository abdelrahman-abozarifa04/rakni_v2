import 'package:flutter/material.dart';
import 'package:rakni_v2/core/models/parking_lot_model.dart';
import 'package:rakni_v2/core/repositories/parking_lot_repository.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/home/filter_bottom_sheet.dart';
import 'package:rakni_v2/features/home/parking_lot_detail_screen.dart';

class ParkingSearchScreen extends StatefulWidget {
  const ParkingSearchScreen({super.key});

  @override
  State<ParkingSearchScreen> createState() => _ParkingSearchScreenState();
}

class _ParkingSearchScreenState extends State<ParkingSearchScreen> {
  final _controller = TextEditingController();
  String _query = '';
  List<ParkingLotModel> _results = [];
  List<ParkingLotModel> _allResults = [];
  bool _isLoading = false;
  FilterConfig? _activeFilter;

  @override
  void initState() {
    super.initState();
    _search(''); // Load all lots on open
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _search(String query) async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final results =
          await ParkingLotRepository.instance.searchLots(query);
      if (mounted) {
        _allResults = results;
        _applyFilter();
        setState(() => _isLoading = false);
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _applyFilter() {
    final filter = _activeFilter;
    if (filter == null) {
      _results = List.from(_allResults);
    } else {
      _results = _allResults
          .where((lot) => filter.matchesPrice(lot.pricePerHour))
          .toList();
    }
  }

  Future<void> _openFilter() async {
    final result = await FilterBottomSheet.show(context);
    if (result != null && mounted) {
      setState(() {
        _activeFilter = result;
        _applyFilter();
      });
    }
  }

  void _openDetail(ParkingLotModel lot) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ParkingLotDetailScreen(
          id: lot.id,
          name: lot.name,
          address: lot.address,
          availableSlots: lot.availableSlots,
          totalSlots: lot.totalSlots,
          pricePerHour: 'EGP ${lot.pricePerHour.toStringAsFixed(0)}/hr',
          imagePath: lot.imageUrl ?? 'assets/images/mall_of_arabia.png',
          latitude: lot.latitude,
          longitude: lot.longitude,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Search Parking',
          style: TextStyle(
            color: AppColors.white,
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
            child: Container(
              height: 52,
              decoration: BoxDecoration(
                color: AppColors.fieldColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.fieldStroke),
              ),
              child: Row(
                children: [
                  SizedBox(width: 16),
                  Icon(
                    Icons.search,
                    color: AppColors.hintColor,
                    size: 20,
                  ),
                  SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _controller,
                      autofocus: true,
                      style: TextStyle(
                        color: AppColors.white,
                        fontSize: 15,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Search for a parking spot...',
                        hintStyle: TextStyle(
                          color: AppColors.hintColor,
                          fontSize: 14,
                        ),
                        border: InputBorder.none,
                        isDense: true,
                      ),
                      onChanged: (v) {
                        setState(() => _query = v);
                        _search(v);
                      },
                    ),
                  ),
                  if (_query.isNotEmpty)
                    GestureDetector(
                      onTap: () {
                        _controller.clear();
                        setState(() => _query = '');
                        _search('');
                      },
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 12),
                        child: Icon(
                          Icons.close,
                          color: AppColors.hintColor,
                          size: 18,
                        ),
                      ),
                    ),
                  SizedBox(width: 16),
                  // Filter button
                  GestureDetector(
                    onTap: _openFilter,
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 8),
                      decoration: BoxDecoration(
                        color: _activeFilter != null
                            ? AppColors.secondary
                            : AppColors.fieldStroke,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.tune_rounded,
                        color: _activeFilter != null
                            ? AppColors.black
                            : AppColors.textSecondary,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(
                    child: CircularProgressIndicator(
                      color: AppColors.secondary,
                    ),
                  )
                : _results.isEmpty
                    ? _buildEmpty()
                    : _buildResults(_results),
          ),
        ],
      ),
    );
  }

  Widget _buildEmpty() => Center(
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.search_off_rounded,
          color: AppColors.hintColor,
          size: 48,
        ),
        SizedBox(height: 12),
        Text(
          _query.isEmpty
              ? 'No parking lots found'
              : 'No results for "$_query"',
          style: TextStyle(
            color: AppColors.textSecondary,
            fontSize: 15,
          ),
        ),
      ],
    ),
  );

  Widget _buildResults(List<ParkingLotModel> results) =>
      ListView.separated(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        itemCount: results.length,
        separatorBuilder: (_, _) =>
            Divider(color: AppColors.fieldStroke, height: 1),
        itemBuilder: (context, i) {
          final lot = results[i];
          return _SearchResultTile(
            lot: lot,
            onTap: () => _openDetail(lot),
          );
        },
      );
}

class _SearchResultTile extends StatelessWidget {
  final ParkingLotModel lot;
  final VoidCallback onTap;
  const _SearchResultTile({required this.lot, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.local_parking_rounded,
                color: AppColors.secondary,
                size: 24,
              ),
            ),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lot.name,
                    style: TextStyle(
                      color: AppColors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 3),
                  Text(
                    lot.address,
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '${lot.availableSlots} spots',
                  style: TextStyle(
                    color: AppColors.secondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'EGP ${lot.pricePerHour.toStringAsFixed(0)}/hr',
                  style: TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
