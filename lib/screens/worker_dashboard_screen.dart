import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/service_request_model.dart';
import '../models/worker_model.dart';
import '../repositories/mock_worker_repository.dart';
import '../services/auth_service.dart';
import '../services/launcher_service.dart';

class WorkerDashboardScreen extends StatefulWidget {
  const WorkerDashboardScreen({super.key});

  @override
  State<WorkerDashboardScreen> createState() => _WorkerDashboardScreenState();
}

class _WorkerDashboardScreenState extends State<WorkerDashboardScreen> {
  final MockWorkerRepository _repository = MockWorkerRepository();
  bool _isOnline = true;
  WorkerModel? _currentWorker;

  @override
  void initState() {
    super.initState();
    _loadWorker();
  }

  void _loadWorker() async {
    final worker = await _repository.getWorkerById('ramesh');
    if (mounted) {
      setState(() {
        _currentWorker = worker;
      });
    }
  }

  void _updateRequest(String id, BookingStatus newStatus) async {
    await _repository.updateRequestStatus(id, newStatus);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Request updated to: ${newStatus.label}'),
          backgroundColor: newStatus.color,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  void _showEditProfileSheet() {
    if (_currentWorker == null) return;
    final nameCtrl = TextEditingController(text: _currentWorker!.name);
    final businessCtrl = TextEditingController(text: _currentWorker!.businessName);
    final feeCtrl = TextEditingController(text: _currentWorker!.visitingCharge.toString());
    final phoneCtrl = TextEditingController(text: _currentWorker!.phone);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
            top: 20,
            left: 20,
            right: 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Edit Worker Profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 14),
              TextField(
                controller: nameCtrl,
                decoration: const InputDecoration(labelText: 'Worker Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: businessCtrl,
                decoration: const InputDecoration(labelText: 'Business Name', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: feeCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                    labelText: 'Standard Visiting Fee (₹)', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: phoneCtrl,
                decoration: const InputDecoration(labelText: 'Contact Phone', border: OutlineInputBorder()),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    final updated = _currentWorker!.copyWith(
                      name: nameCtrl.text.trim(),
                      businessName: businessCtrl.text.trim(),
                      visitingCharge: int.tryParse(feeCtrl.text.trim()) ?? _currentWorker!.visitingCharge,
                      phone: phoneCtrl.text.trim(),
                    );
                    await _repository.updateWorkerProfile(updated);
                    setState(() => _currentWorker = updated);
                    if (ctx.mounted) Navigator.pop(ctx);
                  },
                  child: const Text('Save Changes'),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Worker Dashboard', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primaryDark,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_note_rounded),
            tooltip: 'Edit Profile',
            onPressed: _showEditProfileSheet,
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Log Out',
            onPressed: () => AuthService().logout(),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Worker Header Card
            Container(
              color: AppColors.primaryDark,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: Column(
                children: [
                      Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: Colors.white24,
                        backgroundImage: _currentWorker != null &&
                                _currentWorker!.image.isNotEmpty &&
                                !_currentWorker!.isRemoteImage
                            ? AssetImage(_currentWorker!.image)
                            : null,
                        child: _currentWorker == null ||
                                _currentWorker!.image.isEmpty
                            ? const Icon(Icons.person, color: Colors.white)
                            : null,
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              AuthService().currentUser.value?.name ??
                                  _currentWorker?.businessName ??
                                  'Worker Dashboard',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${AuthService().currentUser.value?.category ?? _currentWorker?.category ?? "Professional"} • ${AuthService().currentUser.value?.shopAddress ?? _currentWorker?.location ?? ""}',
                              style: const TextStyle(color: Colors.white70, fontSize: 13),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                '✓ KaamSetu Verified Professional',
                                style: TextStyle(color: Colors.white, fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Online / Offline Availability Switcher
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: _isOnline ? AppColors.available : AppColors.busy,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _isOnline ? 'Online • Ready for Jobs' : 'Offline • Not Taking Jobs',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        Switch(
                          value: _isOnline,
                          activeColor: AppColors.available,
                          onChanged: (val) => setState(() => _isOnline = val),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Performance Statistics
            Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  _buildStatTile('₹4,850', 'This Week', Icons.currency_rupee),
                  const SizedBox(width: 8),
                  _buildStatTile('${_currentWorker?.jobsCompleted ?? 120}', 'Completed', Icons.check_circle_outline),
                  const SizedBox(width: 8),
                  _buildStatTile('${_currentWorker?.rating ?? 4.8} ⭐', 'Rating', Icons.star_outline),
                ],
              ),
            ),

            // Incoming Bookings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Incoming & Active Leads',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    'Real-time Live Sync',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 10),

            // Live Requests Stream for Worker
            StreamBuilder<List<ServiceRequestModel>>(
              stream: _repository.watchRequests(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final requests = snapshot.data!;
                if (requests.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(32),
                    child: Text('No job requests at the moment.'),
                  );
                }

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: requests.length,
                  itemBuilder: (context, index) {
                    final req = requests[index];
                    return _buildWorkerJobCard(req);
                  },
                );
              },
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildStatTile(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: AppColors.primary),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkerJobCard(ServiceRequestModel req) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                req.customerName,
                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: req.status.color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  req.status.label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: req.status.color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Service: ${req.serviceType} • Visit Fee: ₹${req.visitingCharge}',
            style: const TextStyle(fontSize: 13, color: AppColors.primary, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textMuted),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  req.customerAddress,
                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                ),
              ),
            ],
          ),
          if (req.problemDescription != null && req.problemDescription!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              'Note: "${req.problemDescription}"',
              style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic, color: AppColors.textSecondary),
            ),
          ],
          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.divider),
          const SizedBox(height: 10),

          // Customer Direct Contact Buttons
          Row(
            children: [
              OutlinedButton.icon(
                onPressed: () => LauncherService.makePhoneCall(req.customerPhone),
                icon: const Icon(Icons.call, size: 14, color: AppColors.call),
                label: const Text('Call Customer', style: TextStyle(fontSize: 12, color: AppColors.call)),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => LauncherService.openWhatsApp(
                  phoneNumber: req.customerPhone,
                  message: 'Hello ${req.customerName}, this is regarding your KaamSetu service request for ${req.serviceType}.',
                ),
                icon: const Icon(Icons.chat, size: 14, color: AppColors.whatsApp),
                label: const Text('WhatsApp', style: TextStyle(fontSize: 12, color: AppColors.whatsApp)),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // Lifecycle Progression Action Buttons for Demoing to Professors
          if (req.status == BookingStatus.requested) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusAccepted,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _updateRequest(req.id, BookingStatus.accepted),
                child: const Text('Accept Booking Request'),
              ),
            ),
          ] else if (req.status == BookingStatus.accepted) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusInProgress,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _updateRequest(req.id, BookingStatus.inProgress),
                child: const Text('Start Work (Mark In-Progress)'),
              ),
            ),
          ] else if (req.status == BookingStatus.inProgress) ...[
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.statusCompleted,
                  foregroundColor: Colors.white,
                ),
                onPressed: () => _updateRequest(req.id, BookingStatus.completed),
                child: const Text('Mark Work as Completed'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
