import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/worker_model.dart';
import '../services/launcher_service.dart';

class WorkerCard extends StatelessWidget {
  final WorkerModel worker;
  final VoidCallback onTap;

  const WorkerCard({
    super.key,
    required this.worker,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: AppColors.border.withOpacity(0.6)),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Worker Photo + Info + Rating
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Worker Image
                    ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        width: 72,
                        height: 72,
                        color: AppColors.surface,
                        child: worker.isRemoteImage
                            ? Image.network(
                                worker.image,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: AppColors.textMuted,
                                ),
                              )
                            : Image.asset(
                                worker.image,
                                fit: BoxFit.cover,
                                errorBuilder: (ctx, err, stack) => const Icon(
                                  Icons.person,
                                  size: 40,
                                  color: AppColors.textMuted,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 14),

                    // Worker Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  worker.businessName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (worker.isVerified) ...[
                                const SizedBox(width: 4),
                                const Icon(
                                  Icons.verified,
                                  size: 16,
                                  color: AppColors.verified,
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            worker.name,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 3,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withOpacity(0.08),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  worker.category,
                                  style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              // Distance
                              Row(
                                children: [
                                  const Icon(
                                    Icons.location_on,
                                    size: 13,
                                    color: AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 2),
                                  Text(
                                    '${worker.distanceKm.toStringAsFixed(1)} km',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textSecondary,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),

                    // Rating Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.amber.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.star_rounded,
                            size: 16,
                            color: AppColors.star,
                          ),
                          const SizedBox(width: 2),
                          Text(
                            worker.rating.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFB45309),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                const Divider(height: 1, color: AppColors.divider),
                const SizedBox(height: 12),

                // Middle Row: Visiting Charge + Availability
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Visiting Charge Tag
                    Row(
                      children: [
                        const Text(
                          'Visiting Fee: ',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textSecondary,
                          ),
                        ),
                        Text(
                          '₹${worker.visitingCharge}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),

                    // Availability Status
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: worker.isAvailable
                                ? AppColors.available
                                : AppColors.busy,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          worker.isAvailable ? 'Available Now' : 'Busy',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: worker.isAvailable
                                ? AppColors.available
                                : AppColors.busy,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Bottom Row: Direct Action Buttons (Call & WhatsApp)
                Row(
                  children: [
                    // Call Button
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () =>
                            LauncherService.makePhoneCall(worker.phone),
                        icon: const Icon(Icons.call, size: 16, color: AppColors.call),
                        label: const Text(
                          'Call',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.call,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.call),
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),

                    // WhatsApp Button
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () => LauncherService.openWhatsApp(
                          phoneNumber: worker.whatsapp,
                          message:
                              'Hello ${worker.name}, I found your service (${worker.category}) on KaamSetu and would like to hire you.',
                        ),
                        icon: const Icon(
                          Icons.chat_bubble_outline_rounded,
                          size: 16,
                          color: Colors.white,
                        ),
                        label: const Text(
                          'WhatsApp',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.whatsApp,
                          padding: const EdgeInsets.symmetric(vertical: 10),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
