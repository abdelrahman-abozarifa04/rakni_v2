import 'package:flutter/material.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/home/home_screen.dart';
import 'package:rakni_v2/features/map/map_screen.dart';
import 'package:rakni_v2/features/main/widgets/bottom_nav_bar.dart';

/// Placeholder screens for tabs that are not yet built.
class _BookingsScreen extends StatelessWidget {
  const _BookingsScreen();
  @override
  Widget build(BuildContext context) => const _PlaceholderTab(
      icon: Icons.receipt_long_outlined, label: 'Bookings');
}

class _MyCarScreen extends StatelessWidget {
  const _MyCarScreen();
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderTab(icon: Icons.directions_car_outlined, label: 'My Car');
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen();
  @override
  Widget build(BuildContext context) =>
      const _PlaceholderTab(icon: Icons.person_outline_rounded, label: 'Profile');
}

class _PlaceholderTab extends StatelessWidget {
  final IconData icon;
  final String label;
  const _PlaceholderTab({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: AppColors.secondary, size: 48),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                  color: AppColors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            const Text(
              'Coming soon',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

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
    _BookingsScreen(),
    _MyCarScreen(),
    _ProfileScreen(),
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
