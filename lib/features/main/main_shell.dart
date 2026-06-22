import 'package:flutter/material.dart';
import 'package:rakni_v2/core/localization/locale_service.dart';
import 'package:rakni_v2/core/services/theme_service.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/home/home_screen.dart';
import 'package:rakni_v2/features/map/map_screen.dart';
import 'package:rakni_v2/features/main/widgets/bottom_nav_bar.dart';
import 'package:rakni_v2/features/main/widgets/lazy_indexed_stack.dart';
import 'package:rakni_v2/features/profile/profile_screen.dart';
import 'package:rakni_v2/features/profile/my_vehicles_screen.dart';
import 'package:rakni_v2/features/bookings/bookings_screen.dart';

/// ──────────────────────────────────────────────────────────────────
/// Main shell — keeps the selected tab index and swaps pages.
/// Listens to ThemeService and LocaleService so that both dark/light
/// mode toggles and language switches immediately rebuild the entire
/// Scaffold including the bottom nav bar.
/// ──────────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => MainShellState();
}

class MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  void setTab(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  void initState() {
    super.initState();
    ThemeService.instance.addListener(_onStateChanged);
    LocaleService.instance.addListener(_onStateChanged);
  }

  @override
  void dispose() {
    ThemeService.instance.removeListener(_onStateChanged);
    LocaleService.instance.removeListener(_onStateChanged);
    super.dispose();
  }

  void _onStateChanged() {
    if (mounted) setState(() {});
  }

  static const List<Widget> _pages = [
    HomeScreen(),
    MapScreen(),
    BookingsScreen(),
    MyVehiclesScreen(),
    ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      // LazyIndexedStack keeps the state of every tab alive but delays initialization
      body: LazyIndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: RakniBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
