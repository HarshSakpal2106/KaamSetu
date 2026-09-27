import 'review_model.dart';
import 'work_photo_model.dart';

class WorkerModel {
  final String id;
  final String name;
  final String businessName;
  final String category; // Electrician, Plumber, Cleaner, Carpenter, Painter, AC Repair
  final String service; // Detailed service title
  final String phone;
  final String whatsapp;
  final String location;
  final double distanceKm;
  final double rating;
  final int reviewCount;
  final int experienceYears;
  final int jobsCompleted;
  final int visitingCharge; // In Rupees, e.g. 199
  final bool isAvailable;
  final bool isVerified;
  final String about;
  final String image; // Asset path or remote image URL
  final List<WorkPhotoModel> pastWorks;
  final List<ReviewModel> reviews;
  final List<String> servicesProvided;

  const WorkerModel({
    required this.id,
    required this.name,
    required this.businessName,
    required this.category,
    required this.service,
    required this.phone,
    required this.whatsapp,
    required this.location,
    required this.distanceKm,
    required this.rating,
    required this.reviewCount,
    required this.experienceYears,
    required this.jobsCompleted,
    required this.visitingCharge,
    required this.isAvailable,
    required this.isVerified,
    required this.about,
    required this.image,
    required this.pastWorks,
    required this.reviews,
    required this.servicesProvided,
  });

  bool get isRemoteImage =>
      image.startsWith('http://') || image.startsWith('https://');

  factory WorkerModel.fromJson(Map<String, dynamic> json) {
    return WorkerModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      businessName: json['businessName'] as String? ?? '',
      category: json['category'] as String? ?? '',
      service: json['service'] as String? ?? '',
      phone: json['phone'] as String? ?? '',
      whatsapp: json['whatsapp'] as String? ?? '',
      location: json['location'] as String? ?? '',
      distanceKm: (json['distanceKm'] as num?)?.toDouble() ?? 1.0,
      rating: (json['rating'] as num?)?.toDouble() ?? 4.5,
      reviewCount: (json['reviewCount'] as num?)?.toInt() ?? 50,
      experienceYears: (json['experienceYears'] as num?)?.toInt() ?? 5,
      jobsCompleted: (json['jobsCompleted'] as num?)?.toInt() ?? 100,
      visitingCharge: (json['visitingCharge'] as num?)?.toInt() ?? 199,
      isAvailable: json['isAvailable'] as bool? ?? true,
      isVerified: json['isVerified'] as bool? ?? true,
      about: json['about'] as String? ?? '',
      image: json['image'] as String? ?? '',
      pastWorks: (json['pastWorks'] as List<dynamic>?)
              ?.map((e) => WorkPhotoModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      reviews: (json['reviews'] as List<dynamic>?)
              ?.map((e) => ReviewModel.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      servicesProvided: (json['servicesProvided'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'businessName': businessName,
      'category': category,
      'service': service,
      'phone': phone,
      'whatsapp': whatsapp,
      'location': location,
      'distanceKm': distanceKm,
      'rating': rating,
      'reviewCount': reviewCount,
      'experienceYears': experienceYears,
      'jobsCompleted': jobsCompleted,
      'visitingCharge': visitingCharge,
      'isAvailable': isAvailable,
      'isVerified': isVerified,
      'about': about,
      'image': image,
      'pastWorks': pastWorks.map((e) => e.toJson()).toList(),
      'reviews': reviews.map((e) => e.toJson()).toList(),
      'servicesProvided': servicesProvided,
    };
  }

  WorkerModel copyWith({
    String? id,
    String? name,
    String? businessName,
    String? category,
    String? service,
    String? phone,
    String? whatsapp,
    String? location,
    double? distanceKm,
    double? rating,
    int? reviewCount,
    int? experienceYears,
    int? jobsCompleted,
    int? visitingCharge,
    bool? isAvailable,
    bool? isVerified,
    String? about,
    String? image,
    List<WorkPhotoModel>? pastWorks,
    List<ReviewModel>? reviews,
    List<String>? servicesProvided,
  }) {
    return WorkerModel(
      id: id ?? this.id,
      name: name ?? this.name,
      businessName: businessName ?? this.businessName,
      category: category ?? this.category,
      service: service ?? this.service,
      phone: phone ?? this.phone,
      whatsapp: whatsapp ?? this.whatsapp,
      location: location ?? this.location,
      distanceKm: distanceKm ?? this.distanceKm,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      experienceYears: experienceYears ?? this.experienceYears,
      jobsCompleted: jobsCompleted ?? this.jobsCompleted,
      visitingCharge: visitingCharge ?? this.visitingCharge,
      isAvailable: isAvailable ?? this.isAvailable,
      isVerified: isVerified ?? this.isVerified,
      about: about ?? this.about,
      image: image ?? this.image,
      pastWorks: pastWorks ?? this.pastWorks,
      reviews: reviews ?? this.reviews,
      servicesProvided: servicesProvided ?? this.servicesProvided,
    );
  }
}
