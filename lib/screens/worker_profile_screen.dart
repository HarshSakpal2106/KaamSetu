import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/service_request_model.dart';
import '../models/user_model.dart';
import '../repositories/mock_worker_repository.dart';
import '../services/auth_service.dart';
import 'auth_screen.dart';

class WorkerProfileScreen extends StatelessWidget {
  const WorkerProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<UserModel?>(
      valueListenable: AuthService().currentUser,
      builder: (context, user, _) {
        if (user == null) return const SizedBox.shrink();
        final workerId = user.id;
        final repo = MockWorkerRepository();
        final allJobs = repo.getRequestsForWorker(workerId);
        final completed =
            allJobs.where((r) => r.status == BookingStatus.completed).toList();
        final reviews = completed.where((r) => r.ratingGiven != null).toList();
        final avgRating = reviews.isEmpty
            ? 0.0
            : reviews.map((r) => r.ratingGiven!).reduce((a, b) => a + b) /
                reviews.length;

        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('My Profile'),
            actions: [
              IconButton(
                icon: const Icon(Icons.edit_outlined),
                onPressed: () => _showEditSheet(context, user),
                tooltip: 'Edit Profile',
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // ── Profile card ──────────────────────────────
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        // Avatar
                        Container(
                          width: 72,
                          height: 72,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(36),
                            border: Border.all(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                width: 2),
                          ),
                          child: user.photoPath != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(36),
                                  child: Image.asset(
                                    user.photoPath!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (ctx, err, stack) =>
                                        _avatarFallback(user.name),
                                  ),
                                )
                              : _avatarFallback(user.name),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.name,
                                style: const TextStyle(
                                    fontSize: 17,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary),
                              ),
                              if (user.category != null) ...[
                                const SizedBox(height: 3),
                                Row(
                                  children: [
                                    const Icon(Icons.build_outlined,
                                        size: 13, color: AppColors.textMuted),
                                    const SizedBox(width: 4),
                                    Text(
                                      user.category!,
                                      style: const TextStyle(
                                          fontSize: 13,
                                          color: AppColors.textSecondary),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 3),
                              Row(
                                children: [
                                  const Icon(Icons.star,
                                      size: 14, color: AppColors.star),
                                  const SizedBox(width: 3),
                                  Text(
                                    reviews.isEmpty
                                        ? 'No ratings yet'
                                        : '${avgRating.toStringAsFixed(1)}  (${reviews.length} review${reviews.length > 1 ? 's' : ''})',
                                    style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),
                    const Divider(height: 1, color: AppColors.divider),
                    const SizedBox(height: 14),

                    _infoRow(Icons.phone_outlined, user.phone),
                    if (user.shopAddress != null)
                      _infoRow(Icons.store_outlined, user.shopAddress!),
                    if (user.workerHours != null)
                      _infoRow(Icons.access_time_outlined, user.workerHours!),
                    if (user.description != null &&
                        user.description!.isNotEmpty)
                      _infoRow(
                          Icons.notes_outlined, user.description!,
                          italic: true),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Stats row ────────────────────────────────
              Row(
                children: [
                  _statBox('Total Jobs', allJobs.length.toString()),
                  const SizedBox(width: 10),
                  _statBox('Completed', completed.length.toString()),
                  const SizedBox(width: 10),
                  _statBox(
                      'Rating',
                      reviews.isEmpty
                          ? '—'
                          : avgRating.toStringAsFixed(1)),
                ],
              ),

              const SizedBox(height: 20),

              // ── Past completed work ──────────────────────
              if (completed.isNotEmpty) ...[
                const Text(
                  'Past Completed Work',
                  style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary),
                ),
                const SizedBox(height: 10),
                ...completed.map((job) => _PastJobCard(job: job)),
                const SizedBox(height: 20),
              ],

              // ── Logout ────────────────────────────────────
              OutlinedButton.icon(
                onPressed: () => _confirmLogout(context),
                icon: const Icon(Icons.logout, color: Colors.red, size: 18),
                label: const Text('Log Out',
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  minimumSize: const Size(double.infinity, 0),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        );
      },
    );
  }

  Widget _avatarFallback(String name) {
    return Center(
      child: Text(
        name.isNotEmpty ? name[0].toUpperCase() : '?',
        style: const TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.bold,
            color: AppColors.primary),
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, {bool italic = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: AppColors.textMuted),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                fontStyle: italic ? FontStyle.italic : FontStyle.normal,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _statBox(String label, String value) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 11, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Edit profile bottom sheet
  // ─────────────────────────────────────────────────────

  void _showEditSheet(BuildContext context, UserModel user) {
    final nameCtrl = TextEditingController(text: user.name);
    final phoneCtrl = TextEditingController(text: user.phone);
    final shopCtrl = TextEditingController(text: user.shopAddress ?? '');
    final hoursCtrl = TextEditingController(text: user.workerHours ?? '');
    final descCtrl = TextEditingController(text: user.description ?? '');
    String? selectedCategory = user.category;

    const categories = [
      'Electrician', 'Plumber', 'Carpenter', 'Painter',
      'AC Repair', 'Cleaning', 'Mechanic', 'Other',
    ];

    final formKey = GlobalKey<FormState>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Padding(
          padding: EdgeInsets.only(
              bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius:
                  BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Form(
              key: formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: Colors.grey.shade300,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Edit Profile',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),

                    _sheetField(nameCtrl, 'Name', Icons.person_outline,
                        hint: 'e.g. Raju Electricals',
                        validator: (v) => v!.trim().isEmpty
                            ? 'Required'
                            : null),
                    const SizedBox(height: 10),
                    _sheetField(phoneCtrl, 'Phone Number', Icons.phone_outlined,
                        hint: 'e.g. +91 98765 43210',
                        keyboardType: TextInputType.phone,
                        validator: (v) => v!.trim().isEmpty
                            ? 'Required'
                            : null),
                    const SizedBox(height: 10),
                    _sheetField(shopCtrl, 'Shop / Work Address',
                        Icons.store_outlined,
                        hint: 'e.g. Shop 4, Sai Market, Vasai'),
                    const SizedBox(height: 10),

                    // Category
                    DropdownButtonFormField<String>(
                      value: selectedCategory,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Service Category',
                        prefixIcon: const Icon(Icons.build_outlined,
                            size: 20),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                      ),
                      hint: const Text('Select category'),
                      items: categories
                          .map((c) =>
                              DropdownMenuItem(value: c, child: Text(c)))
                          .toList(),
                      onChanged: (v) =>
                          setSheetState(() => selectedCategory = v),
                    ),
                    const SizedBox(height: 10),

                    _sheetField(hoursCtrl, 'Working Hours',
                        Icons.access_time_outlined,
                        hint: 'e.g. Mon–Sat, 9am–7pm'),
                    const SizedBox(height: 10),
                    _sheetField(descCtrl, 'Short Description',
                        Icons.notes_outlined,
                        hint: 'Brief about your experience...',
                        maxLines: 2),
                    const SizedBox(height: 20),

                    SizedBox(
                      width: double.infinity,
                      height: 46,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: () async {
                          if (!formKey.currentState!.validate()) return;
                          await AuthService().updateUserProfile(
                            name: nameCtrl.text.trim(),
                            phone: phoneCtrl.text.trim(),
                            address: shopCtrl.text.trim(),
                            email: user.email,
                            shopAddress: shopCtrl.text.trim(),
                            workerHours: hoursCtrl.text.trim(),
                            description: descCtrl.text.trim(),
                            category: selectedCategory,
                          );
                          if (!ctx.mounted) return;
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Profile updated!'),
                              backgroundColor: AppColors.primary,
                            ),
                          );
                        },
                        child: const Text('Save Changes',
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _sheetField(
    TextEditingController ctrl,
    String label,
    IconData icon, {
    String? hint,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: ctrl,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: validator,
    );
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Log Out?',
            style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Are you sure you want to log out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              await AuthService().logout();
              if (!context.mounted) return;
              Navigator.of(context, rootNavigator: true).pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const AuthScreen()),
                (_) => false,
              );
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }
}

// ────────────────────────────────────────────────────────
// Past job card
// ────────────────────────────────────────────────────────

class _PastJobCard extends StatelessWidget {
  final ServiceRequestModel job;
  const _PastJobCard({required this.job});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  job.serviceType,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                job.date,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            job.customerName,
            style: const TextStyle(
                fontSize: 12, color: AppColors.textSecondary),
          ),
          if (job.ratingGiven != null) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                ...List.generate(
                  5,
                  (i) => Icon(
                    i < job.ratingGiven!.round()
                        ? Icons.star
                        : Icons.star_border,
                    size: 14,
                    color: AppColors.star,
                  ),
                ),
                const SizedBox(width: 6),
                if (job.reviewGiven != null)
                  Expanded(
                    child: Text(
                      '"${job.reviewGiven}"',
                      style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textSecondary,
                          fontStyle: FontStyle.italic),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
