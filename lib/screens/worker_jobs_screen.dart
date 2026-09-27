import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/service_request_model.dart';
import '../repositories/mock_worker_repository.dart';
import '../services/auth_service.dart';

class WorkerJobsScreen extends StatelessWidget {
  const WorkerJobsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final workerId = AuthService().currentUser.value?.id ?? 'ramesh';
    final repo = MockWorkerRepository();
    repo.ensureFirestoreSync();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('My Jobs'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => (context as Element).markNeedsBuild(),
          ),
        ],
      ),
      body: StreamBuilder<List<ServiceRequestModel>>(
        stream: repo.watchRequests(),
        builder: (context, snapshot) {
          final allRequests = repo.getRequestsForWorker(workerId);

          final pending = allRequests
              .where((r) => r.status == BookingStatus.requested)
              .toList();
          final active = allRequests
              .where((r) =>
                  r.status == BookingStatus.accepted ||
                  r.status == BookingStatus.inProgress)
              .toList();
          final done = allRequests
              .where((r) =>
                  r.status == BookingStatus.completed ||
                  r.status == BookingStatus.cancelled)
              .toList();

          if (allRequests.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('📋', style: TextStyle(fontSize: 52)),
                  const SizedBox(height: 12),
                  const Text(
                    'No jobs yet',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'New service requests will appear here',
                    style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  ),
                ],
              ),
            );
          }

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (pending.isNotEmpty) ...[
                _sectionHeader('🔔 New Requests', pending.length, Colors.orange),
                const SizedBox(height: 8),
                ...pending.map((r) => _JobCard(
                      request: r,
                      onAccept: () => repo.acceptRequest(r.id),
                    )),
                const SizedBox(height: 20),
              ],
              if (active.isNotEmpty) ...[
                _sectionHeader('🔧 Active Jobs', active.length, AppColors.statusAccepted),
                const SizedBox(height: 8),
                ...active.map((r) => _JobCard(
                      request: r,
                      onMarkDone: () => _confirmMarkDone(context, repo, r.id),
                    )),
                const SizedBox(height: 20),
              ],
              if (done.isNotEmpty) ...[
                _sectionHeader('✅ Completed', done.length, AppColors.statusCompleted),
                const SizedBox(height: 8),
                ...done.map((r) => _JobCard(request: r)),
              ],
            ],
          );
        },
      ),
    );
  }

  Widget _sectionHeader(String label, int count, Color color) {
    return Row(
      children: [
        Text(
          label,
          style: const TextStyle(
              fontSize: 15, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color),
          ),
        ),
      ],
    );
  }

  void _confirmMarkDone(
      BuildContext context, MockWorkerRepository repo, String requestId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Mark as Completed?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
            'This will notify the customer that the work is done. They can then leave a rating.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.statusCompleted,
              foregroundColor: Colors.white,
              shape:
                  RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () {
              repo.markAsCompleted(requestId);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Job marked as completed!'),
                  backgroundColor: AppColors.statusCompleted,
                ),
              );
            },
            child: const Text('Yes, Mark Done'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// Job card widget
// ────────────────────────────────────────────────────────

class _JobCard extends StatelessWidget {
  final ServiceRequestModel request;
  final VoidCallback? onAccept;
  final VoidCallback? onMarkDone;

  const _JobCard({required this.request, this.onAccept, this.onMarkDone});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row: service type + status pill
            Row(
              children: [
                Expanded(
                  child: Text(
                    request.serviceType,
                    style: const TextStyle(
                        fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                ),
                _StatusPill(status: request.status),
              ],
            ),
            const SizedBox(height: 6),

            // Customer name + date
            Row(
              children: [
                const Icon(Icons.person_outline,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  request.customerName,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const Spacer(),
                const Icon(Icons.calendar_today_outlined,
                    size: 13, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Text(
                  request.date,
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 4),

            // Address
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined,
                    size: 14, color: AppColors.textMuted),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    request.customerAddress,
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.textSecondary),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),

            if (request.problemDescription != null &&
                request.problemDescription!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '"${request.problemDescription}"',
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      fontStyle: FontStyle.italic),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],

            // Action buttons
            if (onAccept != null || onMarkDone != null) ...[
              const SizedBox(height: 10),
              const Divider(height: 1, color: AppColors.divider),
              const SizedBox(height: 10),
              Row(
                children: [
                  if (onAccept != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                        onPressed: onAccept,
                        icon: const Icon(Icons.check_circle_outline, size: 16),
                        label: const Text('Accept Job',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                  if (onMarkDone != null)
                    Expanded(
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.statusCompleted,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8)),
                          padding: const EdgeInsets.symmetric(vertical: 9),
                        ),
                        onPressed: onMarkDone,
                        icon: const Icon(Icons.done_all, size: 16),
                        label: const Text('Mark as Done',
                            style: TextStyle(fontSize: 13)),
                      ),
                    ),
                ],
              ),
            ],

            // Completion note
            if (request.status == BookingStatus.completed) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(Icons.verified_outlined,
                      size: 14, color: AppColors.statusCompleted),
                  const SizedBox(width: 4),
                  Text(
                    'Work completed',
                    style: TextStyle(
                        fontSize: 12,
                        color: AppColors.statusCompleted,
                        fontWeight: FontWeight.w600),
                  ),
                  if (request.ratingGiven != null) ...[
                    const Spacer(),
                    const Icon(Icons.star, size: 14, color: AppColors.star),
                    const SizedBox(width: 2),
                    Text(
                      request.ratingGiven!.toStringAsFixed(1),
                      style: const TextStyle(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ],
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final BookingStatus status;
  const _StatusPill({required this.status});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: status.color.withValues(alpha: 0.3)),
      ),
      child: Text(
        status.label,
        style: TextStyle(
            fontSize: 11, fontWeight: FontWeight.bold, color: status.color),
      ),
    );
  }
}
