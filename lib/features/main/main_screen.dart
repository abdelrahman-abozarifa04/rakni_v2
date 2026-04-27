import 'package:flutter/material.dart';
import 'package:rakni_v2/core/theme/app_colors.dart';
import 'package:rakni_v2/features/home/home_screen.dart';
import 'package:rakni_v2/features/main/widgets/custom_bottom_nav_bar.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const HomeScreen(),
    const Scaffold(body: Center(child: Text('Map Screen', style: TextStyle(color: Colors.white)))),
    const Scaffold(body: Center(child: Text('Booking Screen', style: TextStyle(color: Colors.white)))),
    const Scaffold(body: Center(child: Text('Profile Screen', style: TextStyle(color: Colors.white)))),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: _screens[_currentIndex],
      bottomNavigationBar: CustomBottomNavBar(
        currentIndex: _currentIndex,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
      ),
    );
  }
}
