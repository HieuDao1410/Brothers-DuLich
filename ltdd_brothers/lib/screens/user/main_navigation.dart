import 'package:flutter/material.dart';
import '../../utils/app_colors.dart';

import 'home_screen.dart';
import 'nearby_screen.dart';
import 'schedule_screen.dart';
import 'community_screen.dart';
import 'review_screen.dart';
import 'profile_screen.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({Key? key}) : super(key: key);

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onNavigateToNearby: () => _onItemTapped(1)),
      const NearbyScreen(),
      const ScheduleScreen(),
      const CommunityScreen(),
      const ReviewScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: AppColors.bg(context),
      body: IndexedStack(
        index: _selectedIndex,
        children: screens,
      ),
      bottomNavigationBar: Theme(
        data: Theme.of(context).copyWith(
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: BottomNavigationBar(
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
          backgroundColor: AppColors.bg(context),
          type: BottomNavigationBarType.fixed,
          selectedItemColor: AppColors.text(context),
          unselectedItemColor: AppColors.textMuted(context),
          selectedFontSize: 11,
          unselectedFontSize: 11,
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Khám phá'),
            BottomNavigationBarItem(icon: Icon(Icons.near_me_outlined), label: 'Lân cận'),
            BottomNavigationBarItem(icon: Icon(Icons.favorite_border), label: 'Chuyến đi'),
            BottomNavigationBarItem(icon: Icon(Icons.groups_outlined), label: 'Cộng đồng'),
            BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Đánh giá'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Tài khoản'),
          ],
        ),
      ),
    );
  }
}
