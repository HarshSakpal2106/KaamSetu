import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

enum BookingStatus {
  requested,
  accepted,
  inProgress,
  completed,
  cancelled;

  String get label {
    switch (this) {
      case BookingStatus.requested:
        return 'Requested';
      case BookingStatus.accepted:
        return 'Accepted';
      case BookingStatus.inProgress:
        return 'In Progress';
      case BookingStatus.completed:
        return 'Completed';
      case BookingStatus.cancelled:
        return 'Cancelled';
    }
  }

  int get stepIndex {
    switch (this) {
      case BookingStatus.requested:
        return 0;
      case BookingStatus.accepted:
        return 1;
      case BookingStatus.inProgress:
        return 2;
      case BookingStatus.completed:
        return 3;
      case BookingStatus.cancelled:
        return -1;
    }
  }

  Color get color {
    switch (this) {
      case BookingStatus.requested:
        return AppColors.statusRequested;
      case BookingStatus.accepted:
        return AppColors.statusAccepted;
      case BookingStatus.inProgress:
        return AppColors.statusInProgress;
      case BookingStatus.completed:
        return AppColors.statusCompleted;
      case BookingStatus.cancelled:
        return AppColors.statusCancelled;
    }
  }

  static BookingStatus fromString(String? val) {
    if (val == null) return BookingStatus.requested;
    switch (val.toLowerCase().replaceAll(' ', '')) {
      case 'accepted':
      case 'confirmed':
        return BookingStatus.accepted;
      case 'inprogress':
        return BookingStatus.inProgress;
      case 'completed':
      case 'done':
        return BookingStatus.completed;
      case 'cancelled':
        return BookingStatus.cancelled;
      case 'pending':
      case 'requested':
      default:
        return BookingStatus.requested;
    }
  }
}

class ServiceRequestModel {
  final String id;
  final String customerName;
  final String customerPhone;
  final String customerAddress;
  final String serviceType;
  final String workerId;
  final String workerName;
  final String workerPhone;
  final String workerLocation;
  final String distance;
  final BookingStatus status;
  final String date;
  final int visitingCharge;
  final String? problemDescription;
  final double? ratingGiven;
  final String? reviewGiven;

  const ServiceRequestModel({
    required this.id,
    required this.customerName,
    required this.customerPhone,
    required this.customerAddress,
    required this.serviceType,
    required this.workerId,
    required this.workerName,
    required this.workerPhone,
    required this.workerLocation,
    required this.distance,
    required this.status,
    required this.date,
    required this.visitingCharge,
    this.problemDescription,
    this.ratingGiven,
    this.reviewGiven,
  });

  factory ServiceRequestModel.fromJson(Map<String, dynamic> json) {
    return ServiceRequestModel(
      id: json['id'] as String? ?? 'KS-${DateTime.now().millisecondsSinceEpoch}',
      customerName: json['customerName'] as String? ?? '',
      customerPhone: json['customerPhone'] as String? ?? '',
      customerAddress: json['customerAddress'] as String? ?? '',
      serviceType: json['serviceType'] as String? ?? '',
      workerId: json['workerId'] as String? ?? '',
      workerName: json['workerName'] as String? ?? '',
      workerPhone: json['workerPhone'] as String? ?? '',
      workerLocation: json['location'] as String? ?? '',
      distance: json['distance'] as String? ?? '',
      status: BookingStatus.fromString(json['status'] as String?),
      date: json['date'] as String? ?? '',
      visitingCharge: (json['visitingCharge'] as num?)?.toInt() ?? 199,
      problemDescription: json['problemDescription'] as String?,
      ratingGiven: (json['ratingGiven'] as num?)?.toDouble(),
      reviewGiven: json['reviewGiven'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customerName': customerName,
      'customerPhone': customerPhone,
      'customerAddress': customerAddress,
      'serviceType': serviceType,
      'workerId': workerId,
      'workerName': workerName,
      'workerPhone': workerPhone,
      'location': workerLocation,
      'distance': distance,
      'status': status.label,
      'date': date,
      'visitingCharge': visitingCharge,
      'problemDescription': problemDescription,
      'ratingGiven': ratingGiven,
      'reviewGiven': reviewGiven,
    };
  }

  ServiceRequestModel copyWith({
    String? id,
    String? customerName,
    String? customerPhone,
    String? customerAddress,
    String? serviceType,
    String? workerId,
    String? workerName,
    String? workerPhone,
    String? workerLocation,
    String? distance,
    BookingStatus? status,
    String? date,
    int? visitingCharge,
    String? problemDescription,
    double? ratingGiven,
    String? reviewGiven,
  }) {
    return ServiceRequestModel(
      id: id ?? this.id,
      customerName: customerName ?? this.customerName,
      customerPhone: customerPhone ?? this.customerPhone,
      customerAddress: customerAddress ?? this.customerAddress,
      serviceType: serviceType ?? this.serviceType,
      workerId: workerId ?? this.workerId,
      workerName: workerName ?? this.workerName,
      workerPhone: workerPhone ?? this.workerPhone,
      workerLocation: workerLocation ?? this.workerLocation,
      distance: distance ?? this.distance,
      status: status ?? this.status,
      date: date ?? this.date,
      visitingCharge: visitingCharge ?? this.visitingCharge,
      problemDescription: problemDescription ?? this.problemDescription,
      ratingGiven: ratingGiven ?? this.ratingGiven,
      reviewGiven: reviewGiven ?? this.reviewGiven,
    );
  }
}
