import 'package:flutter/material.dart';
import 'package:rakni_v2/core/services/favorites_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';

// TODO: Implement full Favourites screen - load lots by name from FavoritesService,
// then fetch full ParkingLotModel data from FirestoreService and display as cards
// navigating to ParkingLotDetailScreen.
class FavouritesScreen extends StatefulWidget {
  const FavouritesScreen({super.key});

  @override
  State<FavouritesScreen> createState() => _FavouritesScreenState();
}

class _FavouritesScreenState extends State<FavouritesScreen> {
  Set<String> _favourites = {};
  bool _loading = true;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: AppColors.white,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
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
          ? const Center(
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
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final name = _favourites.elementAt(i);
                return Container(
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
                        child: const Icon(
                          Icons.local_parking_rounded,
                          color: AppColors.secondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          name,
                          style: const TextStyle(
                            color: AppColors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(
                          Icons.favorite_rounded,
                          color: AppColors.secondary,
                          size: 22,
                        ),
                        onPressed: () async {
                          await FavoritesService.instance.toggleFavorite(name);
                          _load();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
