import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaamsetu/main.dart';
import 'package:kaamsetu/models/service_request_model.dart';
import 'package:kaamsetu/repositories/mock_worker_repository.dart';
import 'package:kaamsetu/services/auth_service.dart';

void main() {
  setUp(() async {
    await AuthService().logout();
  });

  testWidgets('KaamSetu full user journey test', (WidgetTester tester) async {
    await tester.pumpWidget(const KaamSetuApp());
    await tester.pumpAndSettle();

    // New flow: first pick role, then log in
    expect(find.text('Customer'), findsOneWidget);
    expect(find.text('Worker'), findsOneWidget);

    // Tap Customer role card
    await tester.tap(find.text('Customer'));
    await tester.pumpAndSettle();

    // Now the login form is visible
    expect(find.text('Log In'), findsWidgets);

    // Fill in login credentials (phone and password)
    await tester.enterText(
        find.byType(TextFormField).at(0), '+91 98765 00001');
    await tester.enterText(
        find.byType(TextFormField).at(1), 'password123');
    await tester.pumpAndSettle();

    // Tap Log In button
    await tester.tap(find.widgetWithText(ElevatedButton, 'Log In'));
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pumpAndSettle();

    expect(find.text('KaamSetu'), findsWidgets);
    expect(find.text('Find Trusted Workers\nNear You'), findsOneWidget);
    expect(find.text('Electrician'), findsWidgets);
    expect(find.text('Plumber'), findsWidgets);

    // 2. Tap on Explore Tab in Bottom Navigation
    await tester.tap(find.byIcon(Icons.search_outlined));
    await tester.pumpAndSettle();

    expect(find.text('Find Workers'), findsOneWidget);
    expect(find.text('Ramesh Electrical Services'), findsOneWidget);

    // 3. Tap on Ramesh's Worker Card to open WorkerDetailScreen
    await tester.tap(find.text('Ramesh Electrical Services'));
    await tester.pumpAndSettle();

    // Verify Worker Detail Screen loaded
    expect(find.text('Standard Visiting Charge'), findsOneWidget);
    expect(find.text('₹199'), findsWidgets);
    expect(find.text('Past Works & Portfolio'), findsOneWidget);
    expect(find.text('Request Service'), findsOneWidget);

    // 4. Open Booking Bottom Sheet
    await tester.tap(find.text('Request Service'));
    await tester.pumpAndSettle();

    expect(find.text('Submit Service Request'), findsOneWidget);

    // 5. Submit the booking request
    await tester.ensureVisible(find.text('Submit Service Request'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Submit Service Request'));
    await tester.pumpAndSettle();

    // Confirmation dialog appears
    expect(find.text('Request Sent!'), findsOneWidget);

    // Close confirmation dialog
    await tester.tap(find.text('OK'));
    await tester.pumpAndSettle();

    // Pop back to Explore screen
    await tester.pageBack();
    await tester.pumpAndSettle();

    // 6. Navigate to My Bookings tab
    await tester.tap(find.byIcon(Icons.assignment_outlined));
    await tester.pumpAndSettle();

    expect(find.text('My Requests'), findsOneWidget);
    expect(find.text('Active Requests'), findsOneWidget);

    // Verify the newly created booking is shown in the live list
    final repository = MockWorkerRepository();
    final requests = await repository.getRequests();
    expect(requests.isNotEmpty, isTrue);
    expect(requests.first.customerName, 'Harshwardhan');
  });

  testWidgets('Worker dashboard lifecycle status test', (WidgetTester tester) async {
    final repository = MockWorkerRepository();
    await repository.createRequest(
      const ServiceRequestModel(
        id: 'KS-test-lifecycle',
        customerName: 'Test Customer',
        customerPhone: '+91 90000 00000',
        customerAddress: 'Test Address',
        serviceType: 'Electrical Repair',
        workerId: 'ramesh',
        workerName: 'Ramesh Electrical Services',
        workerPhone: '+91 98765 43210',
        workerLocation: 'Vasai - Virar, Maharashtra',
        distance: '1.2 km away',
        status: BookingStatus.accepted,
        date: '28 Sep 2026',
        visitingCharge: 199,
      ),
    );

    await repository.updateRequestStatus('KS-test-lifecycle', BookingStatus.inProgress);
    final updatedRequests = await repository.getRequests();
    expect(
      updatedRequests.firstWhere((r) => r.id == 'KS-test-lifecycle').status,
      BookingStatus.inProgress,
    );

    await repository.updateRequestStatus('KS-test-lifecycle', BookingStatus.completed);
    final completedRequests = await repository.getRequests();
    expect(
      completedRequests.firstWhere((r) => r.id == 'KS-test-lifecycle').status,
      BookingStatus.completed,
    );
  });
}
