import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/service_request_model.dart';
import '../models/worker_model.dart';
import '../repositories/mock_worker_repository.dart';
import '../services/auth_service.dart';
import 'package:intl/intl.dart';

class BookingBottomSheet extends StatefulWidget {
  final WorkerModel worker;
  final VoidCallback? onRequestSubmitted;

  const BookingBottomSheet({
    super.key,
    required this.worker,
    this.onRequestSubmitted,
  });

  static Future<void> show(
    BuildContext context, {
    required WorkerModel worker,
    VoidCallback? onRequestSubmitted,
  }) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BookingBottomSheet(
        worker: worker,
        onRequestSubmitted: onRequestSubmitted,
      ),
    );
  }

  @override
  State<BookingBottomSheet> createState() => _BookingBottomSheetState();
}

class _BookingBottomSheetState extends State<BookingBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  final _notesController = TextEditingController();

  late String _selectedService;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill from logged-in user profile
    final user = AuthService().currentUser.value;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _addressController = TextEditingController(text: user?.address ?? '');
    _selectedService = widget.worker.servicesProvided.isNotEmpty
        ? widget.worker.servicesProvided.first
        : widget.worker.service;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final String dateString = DateFormat('dd MMM yyyy').format(DateTime.now());
    final newRequest = ServiceRequestModel(
      id: 'KS-${DateTime.now().millisecondsSinceEpoch.toString().substring(5)}',
      customerName: _nameController.text.trim(),
      customerPhone: _phoneController.text.trim(),
      customerAddress: _addressController.text.trim(),
      serviceType: _selectedService,
      workerId: widget.worker.id,
      workerName: widget.worker.businessName,
      workerPhone: widget.worker.phone,
      workerLocation: widget.worker.location,
      distance: '${widget.worker.distanceKm.toStringAsFixed(1)} km away',
      status: BookingStatus.requested,
      date: dateString,
      visitingCharge: widget.worker.visitingCharge,
      problemDescription: _notesController.text.trim().isNotEmpty
          ? _notesController.text.trim()
          : null,
    );

    await MockWorkerRepository().createRequest(newRequest);

    if (!mounted) return;

    setState(() => _isSubmitting = false);
    Navigator.pop(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.check_circle, color: AppColors.available, size: 28),
            SizedBox(width: 8),
            Text('Request Sent!'),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your request for "${widget.worker.businessName}" has been placed successfully.',
              style: const TextStyle(fontSize: 14, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Booking ID: ${newRequest.id}',
                      style: const TextStyle(
                          fontWeight: FontWeight.bold, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text('Service: ${newRequest.serviceType}',
                      style: const TextStyle(fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(
                      'Visiting Fee: ₹${newRequest.visitingCharge} (Pay on visit)',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              widget.onRequestSubmitted?.call();
            },
            child: const Text('View in My Bookings'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Drag handle
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

                // Header
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Request Service',
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.worker.businessName,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Visiting Charge Notice
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline,
                          size: 18, color: AppColors.primaryLight),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Estimated Visiting / Diagnosis Fee: ₹${widget.worker.visitingCharge}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // Customer Name
                TextFormField(
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: 'Your Full Name',
                    hintText: 'e.g. Rahul Sharma',
                    prefixIcon: const Icon(Icons.person_outline),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                ),

                const SizedBox(height: 12),

                // Phone Number
                TextFormField(
                  controller: _phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(
                    labelText: 'Phone Number',
                    hintText: 'e.g. +91 98765 43210',
                    prefixIcon: const Icon(Icons.phone_outlined),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please enter phone number' : null,
                ),

                const SizedBox(height: 12),

                // Service Address
                TextFormField(
                  controller: _addressController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Service Address / Landmark',
                    hintText: 'e.g. Flat 3, Galaxy Apts, Vasai West',
                    prefixIcon: const Icon(Icons.location_on_outlined),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Please enter address' : null,
                ),

                const SizedBox(height: 12),

                // Service Type Dropdown
                DropdownButtonFormField<String>(
                  value: _selectedService,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Select Required Service',
                    prefixIcon: const Icon(Icons.build_circle_outlined),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  items: widget.worker.servicesProvided.map((service) {
                    return DropdownMenuItem<String>(
                      value: service,
                      child: Text(service, overflow: TextOverflow.ellipsis),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => _selectedService = val);
                  },
                ),

                const SizedBox(height: 12),

                // Additional Problem Note
                TextFormField(
                  controller: _notesController,
                  maxLines: 2,
                  decoration: InputDecoration(
                    labelText: 'Problem Description (Optional)',
                    hintText: 'e.g. Switch sparked, water dripping from tap...',
                    prefixIcon: const Icon(Icons.notes_outlined),
                    border:
                        OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),

                const SizedBox(height: 20),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _isSubmitting ? null : _handleSubmit,
                    child: _isSubmitting
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Submit Service Request',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
