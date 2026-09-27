import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/service_request_model.dart';

class StatusStepper extends StatelessWidget {
  final BookingStatus currentStatus;

  const StatusStepper({
    super.key,
    required this.currentStatus,
  });

  @override
  Widget build(BuildContext context) {
    if (currentStatus == BookingStatus.cancelled) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.red.shade50,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cancel_outlined, size: 16, color: AppColors.statusCancelled),
            SizedBox(width: 6),
            Text(
              'Booking Cancelled',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: AppColors.statusCancelled,
              ),
            ),
          ],
        ),
      );
    }

    final int currentStep = currentStatus.stepIndex; // 0, 1, 2, 3
    final steps = [
      {'title': 'Requested', 'icon': Icons.assignment_outlined},
      {'title': 'Accepted', 'icon': Icons.thumb_up_alt_outlined},
      {'title': 'In Progress', 'icon': Icons.build_outlined},
      {'title': 'Completed', 'icon': Icons.check_circle_outline},
    ];

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      child: Column(
        children: [
          Row(
            children: List.generate(steps.length * 2 - 1, (index) {
              if (index.isOdd) {
                // Divider line between circles
                final stepBefore = index ~/ 2;
                final isPassed = stepBefore < currentStep;
                return Expanded(
                  child: Container(
                    height: 3,
                    color: isPassed ? AppColors.primaryLight : AppColors.border,
                  ),
                );
              } else {
                // Step icon circle
                final stepIndex = index ~/ 2;
                final isDone = stepIndex <= currentStep;
                final isCurrent = stepIndex == currentStep;

                return Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isDone
                        ? (isCurrent ? AppColors.primary : AppColors.primaryLight)
                        : Colors.white,
                    border: Border.all(
                      color: isDone ? AppColors.primary : AppColors.border,
                      width: 2,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: AppColors.primary.withOpacity(0.3),
                              blurRadius: 6,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                  ),
                  child: Icon(
                    isDone ? Icons.check : (steps[stepIndex]['icon'] as IconData),
                    size: 14,
                    color: isDone ? Colors.white : AppColors.textMuted,
                  ),
                );
              }
            }),
          ),
          const SizedBox(height: 8),
          // Step Labels
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: steps.asMap().entries.map((entry) {
              final idx = entry.key;
              final isCurrent = idx == currentStep;
              final isDone = idx <= currentStep;

              return SizedBox(
                width: 65,
                child: Text(
                  entry.value['title'] as String,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                    color: isCurrent
                        ? AppColors.primary
                        : (isDone ? AppColors.textPrimary : AppColors.textMuted),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
