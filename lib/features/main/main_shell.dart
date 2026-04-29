import 'package:flutter/material.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/home/home_screen.dart';
import 'package:rakni_v2/features/map/map_screen.dart';
import 'package:rakni_v2/features/main/widgets/bottom_nav_bar.dart';
import 'package:rakni_v2/features/profile/profile_screen.dart';
import 'package:rakni_v2/features/profile/my_vehicles_screen.dart';
import 'package:rakni_v2/features/bookings/bookings_screen.dart';



/// ──────────────────────────────────────────────────────────────────
/// Main shell — keeps the selected tab index and swaps pages.
/// ──────────────────────────────────────────────────────────────────
class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

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
      // IndexedStack keeps the state of every tab alive
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: RakniBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
      ),
    );
  }
}
