import 'package:flutter/material.dart';
import 'package:rakni_v2/core/repositories/parking_lot_repository.dart';
import 'package:rakni_v2/core/services/favorites_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/home/parking_lot_detail_screen.dart';

class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  Set<String> _favourites = {};
  bool _loading = true;
  // Track which tiles are fetching so we can show a per-tile spinner
  final Set<String> _loadingTiles = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final favs = await FavoritesService.instance.getFavorites();
    if (mounted) {
      setState(() {
        _favourites = favs;
        _loading = false;
      });
    }
  }

  Future<void> _openDetail(String name) async {
    if (_loadingTiles.contains(name)) return;
    setState(() => _loadingTiles.add(name));

    try {
      final results = await ParkingLotRepository.instance.searchLots(name);
      if (!mounted) return;

      if (results.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Parking lot not found.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }

      final lot = results.first;
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
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to load lot: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    } finally {
      if (mounted) setState(() => _loadingTiles.remove(name));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Favourites',
          style: TextStyle(
            color: AppColors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.secondary),
            )
          : _favourites.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.favorite_border_rounded,
                    color: AppColors.hintColor,
                    size: 56,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'No favourites yet',
                    style: TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 16,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap the heart icon on any parking lot to save it here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.hintColor, fontSize: 13),
                  ),
                ],
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _favourites.length,
              separatorBuilder: (context, index) => SizedBox(height: 12),
              itemBuilder: (context, i) {
                final name = _favourites.elementAt(i);
                final isLoadingTile = _loadingTiles.contains(name);
                return GestureDetector(
                  onTap: () => _openDetail(name),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: AppColors.fieldStroke),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: AppColors.secondary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            Icons.local_parking_rounded,
                            color: AppColors.secondary,
                            size: 22,
                          ),
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            name,
                            style: TextStyle(
                              color: AppColors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        if (isLoadingTile)
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: AppColors.secondary,
                            ),
                          )
                        else
                          IconButton(
                            icon: Icon(
                              Icons.favorite_rounded,
                              color: AppColors.secondary,
                              size: 22,
                            ),
                            onPressed: () async {
                              await FavoritesService.instance
                                  .toggleFavorite(name);
                              _load();
                            },
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
