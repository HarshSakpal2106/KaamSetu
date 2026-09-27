import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/service_request_model.dart';
import '../repositories/mock_worker_repository.dart';
import 'bookings_screen.dart';
import 'explore_screen.dart';
import 'home_screen.dart';
import 'profile_screen.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _currentIndex = 0;
  String? _initialCategoryForExplore;

  void _onNavigate(int index, {String? category}) {
    setState(() {
      _currentIndex = index;
      if (category != null) {
        _initialCategoryForExplore = category;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> screens = [
      HomeScreen(onNavigate: _onNavigate),
      ExploreScreen(
        key: ValueKey(_initialCategoryForExplore ?? 'explore_default'),
        initialCategory: _initialCategoryForExplore,
      ),
      BookingsScreen(
        onExploreTap: () => _onNavigate(1),
      ),
      const ProfileScreen(),
    ];

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: screens,
      ),
      bottomNavigationBar: StreamBuilder<List<ServiceRequestModel>>(
        stream: MockWorkerRepository().watchRequests(),
        builder: (context, snapshot) {
          final activeCount = snapshot.hasData
              ? snapshot.data!
                  .where((r) =>
                      r.status == BookingStatus.requested ||
                      r.status == BookingStatus.accepted ||
                      r.status == BookingStatus.inProgress)
                  .length
              : 0;

          return Container(
            decoration: BoxDecoration(
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.08),
                  blurRadius: 10,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (index) {
                setState(() {
                  _currentIndex = index;
                  if (index != 1) {
                    _initialCategoryForExplore = null;
                  }
                });
              },
              type: BottomNavigationBarType.fixed,
              backgroundColor: Colors.white,
              selectedItemColor: AppColors.primary,
              unselectedItemColor: AppColors.textMuted,
              selectedLabelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 11),
              unselectedLabelStyle: const TextStyle(fontSize: 11),
              elevation: 0,
              items: [
                const BottomNavigationBarItem(
                  icon: Icon(Icons.home_outlined),
                  activeIcon: Icon(Icons.home_filled),
                  label: 'Home',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.search_outlined),
                  activeIcon: Icon(Icons.search),
                  label: 'Explore',
                ),
                BottomNavigationBarItem(
                  icon: activeCount > 0
                      ? Badge(
                          label: Text('$activeCount'),
                          backgroundColor: AppColors.primary,
                          child: const Icon(Icons.assignment_outlined),
                        )
                      : const Icon(Icons.assignment_outlined),
                  activeIcon: activeCount > 0
                      ? Badge(
                          label: Text('$activeCount'),
                          backgroundColor: AppColors.primary,
                          child: const Icon(Icons.assignment),
                        )
                      : const Icon(Icons.assignment),
                  label: 'Bookings',
                ),
                const BottomNavigationBarItem(
                  icon: Icon(Icons.person_outline),
                  activeIcon: Icon(Icons.person),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
