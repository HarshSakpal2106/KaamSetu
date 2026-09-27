import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/service_request_model.dart';
import '../repositories/mock_worker_repository.dart';
import '../services/auth_service.dart';
import 'worker_jobs_screen.dart';
import 'worker_profile_screen.dart';

class WorkerMainNavigationScreen extends StatefulWidget {
  const WorkerMainNavigationScreen({super.key});

  @override
  State<WorkerMainNavigationScreen> createState() =>
      _WorkerMainNavigationScreenState();
}

class _WorkerMainNavigationScreenState
    extends State<WorkerMainNavigationScreen> {
  int _currentIndex = 0;

  static const _screens = [
    WorkerJobsScreen(),
    WorkerProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final workerId = AuthService().currentUser.value?.id ?? '';

    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: StreamBuilder<List<ServiceRequestModel>>(
        stream: MockWorkerRepository().watchRequests(),
        builder: (context, _) {
          final pending = MockWorkerRepository()
              .getRequestsForWorker(workerId)
              .where((r) => r.status == BookingStatus.requested)
              .length;

          return NavigationBar(
            selectedIndex: _currentIndex,
            onDestinationSelected: (i) =>
                setState(() => _currentIndex = i),
            backgroundColor: Colors.white,
            elevation: 0,
            shadowColor: AppColors.border,
            indicatorColor: AppColors.primary.withValues(alpha: 0.1),
            destinations: [
              NavigationDestination(
                icon: Badge(
                  isLabelVisible: pending > 0,
                  label: Text('$pending',
                      style: const TextStyle(fontSize: 10)),
                  child: const Icon(Icons.work_outline),
                ),
                selectedIcon: Badge(
                  isLabelVisible: pending > 0,
                  label: Text('$pending',
                      style: const TextStyle(fontSize: 10)),
                  child: const Icon(Icons.work_rounded),
                ),
                label: 'Jobs',
              ),
              const NavigationDestination(
                icon: Icon(Icons.person_outline),
                selectedIcon: Icon(Icons.person),
                label: 'Profile',
              ),
            ],
          );
        },
      ),
    );
  }
}
