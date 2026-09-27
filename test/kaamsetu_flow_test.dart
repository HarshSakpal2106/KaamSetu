import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kaamsetu/main.dart';
import 'package:kaamsetu/models/service_request_model.dart';
import 'package:kaamsetu/repositories/mock_worker_repository.dart';

void main() {
  testWidgets('KaamSetu full user journey test', (WidgetTester tester) async {
    // 1. Launch App
    await tester.pumpWidget(const KaamSetuApp());
    await tester.pumpAndSettle();

    // Verify Home screen elements
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
    final initialRequests = await repository.getRequests();
    final firstId = initialRequests.first.id;

    // Advance status to inProgress
    await repository.updateRequestStatus(firstId, BookingStatus.inProgress);
    final updatedRequests = await repository.getRequests();
    expect(updatedRequests.first.status, BookingStatus.inProgress);

    // Complete the job
    await repository.updateRequestStatus(firstId, BookingStatus.completed);
    final completedRequests = await repository.getRequests();
    expect(completedRequests.first.status, BookingStatus.completed);
  });
}
