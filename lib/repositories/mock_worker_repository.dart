import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/category_model.dart';
import '../models/review_model.dart';
import '../models/service_request_model.dart';
import '../models/user_model.dart';
import '../models/work_photo_model.dart';
import '../models/worker_model.dart';
import 'worker_repository.dart';

class MockWorkerRepository implements WorkerRepository {
  // Singleton pattern for easy access across screens
  static final MockWorkerRepository _instance = MockWorkerRepository._internal();
  factory MockWorkerRepository() => _instance;

  final StreamController<List<ServiceRequestModel>> _requestsStreamController =
      StreamController<List<ServiceRequestModel>>.broadcast();

  List<WorkerModel> _workers = [];
  List<ServiceRequestModel> _requests = [];
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _firestoreRequestsSub;

  MockWorkerRepository._internal() {
    _initWorkers();
    _initDemoRequests();
    _syncWorkersWithRequests();
  }

  void _initDemoRequests() {
    _requests = [
      const ServiceRequestModel(
        id: 'KS-1001',
        customerName: 'Rahul Mehta',
        customerPhone: '+91 98200 11223',
        customerAddress: 'Flat 302, Sai Galaxy, Vasai West',
        serviceType: 'House Wiring & Repair',
        workerId: 'ramesh',
        workerName: 'Ramesh Electrical Services',
        workerPhone: '+91 98765 43210',
        workerLocation: 'Vasai - Virar, Maharashtra',
        distance: '1.2 km away',
        status: BookingStatus.completed,
        date: '2 days ago',
        visitingCharge: 199,
        problemDescription: 'Main breaker tripping frequently.',
        ratingGiven: 5.0,
        reviewGiven: 'Very professional, arrived in 20 minutes and completed the wiring work properly.',
      ),
      const ServiceRequestModel(
        id: 'KS-1002',
        customerName: 'Amit Verma',
        customerPhone: '+91 98200 44556',
        customerAddress: 'Shop 12, Station Road, Vasai',
        serviceType: 'Switchboard Repair',
        workerId: 'ramesh',
        workerName: 'Ramesh Electrical Services',
        workerPhone: '+91 98765 43210',
        workerLocation: 'Vasai - Virar, Maharashtra',
        distance: '1.2 km away',
        status: BookingStatus.completed,
        date: '2 weeks ago',
        visitingCharge: 199,
        problemDescription: 'Short circuit near kitchen switch.',
        ratingGiven: 4.5,
        reviewGiven: 'Fixed the short circuit issue quickly. Highly recommended!',
      ),
      const ServiceRequestModel(
        id: 'KS-1003',
        customerName: 'Pooja K.',
        customerPhone: '+91 98200 77889',
        customerAddress: 'Sector 4, Vasai West',
        serviceType: 'Fan & Light Installation',
        workerId: 'wkr_demo_1',
        workerName: 'Raju Electricals',
        workerPhone: '+91 98765 43210',
        workerLocation: 'Vasai West, Maharashtra',
        distance: '1.0 km away',
        status: BookingStatus.completed,
        date: 'Yesterday',
        visitingCharge: 199,
        problemDescription: 'Need 2 ceiling fans installed.',
        ratingGiven: 5.0,
        reviewGiven: 'Neat and quick fan installation. Very polite behavior!',
      ),
    ];
  }

  void _syncWorkersWithRequests() {
    for (int i = 0; i < _workers.length; i++) {
      final worker = _workers[i];
      final workerReqs = _requests.where((r) => r.workerId == worker.id).toList();

      final completedReqs = workerReqs
          .where((r) => r.status == BookingStatus.completed)
          .toList();
      final reviewedReqs = workerReqs
          .where((r) => r.ratingGiven != null && r.ratingGiven! > 0)
          .toList();

      if (reviewedReqs.isNotEmpty || completedReqs.isNotEmpty) {
        // Collect reviews from requests
        final dynamicReviews = reviewedReqs.map((r) => ReviewModel(
          reviewerName: r.customerName.isNotEmpty ? r.customerName : 'Verified Customer',
          rating: r.ratingGiven!,
          comment: (r.reviewGiven != null && r.reviewGiven!.trim().isNotEmpty)
              ? r.reviewGiven!.trim()
              : 'Work completed smoothly.',
          date: r.date.isNotEmpty ? r.date : 'Recently',
        )).toList();

        // Merge with existing reviews if any, avoiding duplicate comment/reviewer pairs
        final combinedReviews = <ReviewModel>[...dynamicReviews];
        for (final existingRev in worker.reviews) {
          final isDupe = combinedReviews.any(
            (cr) => cr.comment == existingRev.comment && cr.reviewerName == existingRev.reviewerName,
          );
          if (!isDupe) {
            combinedReviews.add(existingRev);
          }
        }

        final double avgRating = combinedReviews.isEmpty
            ? 0.0
            : combinedReviews.map((r) => r.rating).reduce((a, b) => a + b) / combinedReviews.length;

        final completedCount = completedReqs.length > worker.jobsCompleted
            ? completedReqs.length
            : worker.jobsCompleted;

        _workers[i] = worker.copyWith(
          reviews: combinedReviews,
          reviewCount: combinedReviews.length,
          rating: double.parse(avgRating.toStringAsFixed(1)),
          jobsCompleted: completedCount,
        );
      }
    }
  }

  void ensureFirestoreSync() {
    if (!_isFirebaseReady || _firestoreRequestsSub != null) return;
    try {
      _firestoreRequestsSub = FirebaseFirestore.instance
          .collection('service_requests')
          .snapshots()
          .listen((snap) {
        for (final doc in snap.docs) {
          try {
            final data = Map<String, dynamic>.from(doc.data());
            data['id'] = doc.id;
            final req = ServiceRequestModel.fromJson(data);
            final idx = _requests.indexWhere((r) => r.id == req.id);
            if (idx >= 0) {
              _requests[idx] = req;
            } else {
              _requests.insert(0, req);
            }
          } catch (e) {
            debugPrint('Error parsing request from Firestore: $e');
          }
        }
        _syncWorkersWithRequests();
        _requestsStreamController.add(List.unmodifiable(_requests));
      }, onError: (err) {
        debugPrint('Firestore service_requests listener error: $err');
      });
    } catch (e) {
      debugPrint('Could not initialize Firestore sync: $e');
    }
  }

  @override
  List<CategoryModel> getCategories() {
    return const [
      CategoryModel(
        id: 'electrician',
        title: 'Electrician',
        subtitle: 'Wiring & repairs',
        iconEmoji: '⚡',
        assetImage: 'assets/images/electrician.jpg',
      ),
      CategoryModel(
        id: 'plumber',
        title: 'Plumber',
        subtitle: 'Pipes & leaks',
        iconEmoji: '🔧',
        assetImage: 'assets/images/plumber.jpg',
      ),
      CategoryModel(
        id: 'cleaning',
        title: 'Cleaning',
        subtitle: 'Home & deep clean',
        iconEmoji: '🧹',
        assetImage: 'assets/images/cleaning.jpg',
      ),
      CategoryModel(
        id: 'carpenter',
        title: 'Carpenter',
        subtitle: 'Furniture & woodwork',
        iconEmoji: '🪚',
        assetImage: 'assets/images/carpenter.jpg',
      ),
      CategoryModel(
        id: 'painter',
        title: 'Painter',
        subtitle: 'Interior & exterior',
        iconEmoji: '🎨',
        assetImage: 'assets/images/painter.jpg',
      ),
      CategoryModel(
        id: 'ac',
        title: 'AC Repair',
        subtitle: 'Cooling & servicing',
        iconEmoji: '❄️',
        assetImage: 'assets/images/Ac.jpg',
      ),
    ];
  }

  bool get _isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  @override
  Future<List<WorkerModel>> getWorkers({
    String? categoryId,
    String? query,
    bool? availableOnly,
    double? minRating,
    String? sortBy,
  }) async {
    ensureFirestoreSync();
    if (_isFirebaseReady) {
      try {
        final snap = await FirebaseFirestore.instance
            .collection('users')
            .where('role', isEqualTo: 'worker')
            .get();
        for (final doc in snap.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          final user = UserModel.fromJson(data);
          addOrUpdateWorkerFromUser(user);
        }

        // Also fetch service requests to ensure work history and reviews are merged
        final reqSnap = await FirebaseFirestore.instance
            .collection('service_requests')
            .get();
        for (final doc in reqSnap.docs) {
          final data = Map<String, dynamic>.from(doc.data());
          data['id'] = doc.id;
          final req = ServiceRequestModel.fromJson(data);
          final idx = _requests.indexWhere((r) => r.id == req.id);
          if (idx >= 0) {
            _requests[idx] = req;
          } else {
            _requests.insert(0, req);
          }
        }
        _syncWorkersWithRequests();
        _requestsStreamController.add(List.unmodifiable(_requests));
      } catch (e) {
        debugPrint('Could not fetch workers from Firestore: $e');
      }
    }

    // Simulate slight async response
    await Future.delayed(const Duration(milliseconds: 50));

    List<WorkerModel> results = List.from(_workers);

    // Filter by Category
    if (categoryId != null && categoryId.isNotEmpty && categoryId != 'all') {
      results = results.where((w) {
        return w.category.toLowerCase().contains(categoryId.toLowerCase()) ||
            (categoryId == 'ac' && w.category.toLowerCase().contains('ac'));
      }).toList();
    }

    // Filter by Search Query
    if (query != null && query.trim().isNotEmpty) {
      final q = query.toLowerCase().trim();
      results = results.where((w) {
        return w.name.toLowerCase().contains(q) ||
            w.businessName.toLowerCase().contains(q) ||
            w.category.toLowerCase().contains(q) ||
            w.service.toLowerCase().contains(q) ||
            w.location.toLowerCase().contains(q) ||
            w.servicesProvided.any((s) => s.toLowerCase().contains(q));
      }).toList();
    }

    // Filter by Availability
    if (availableOnly == true) {
      results = results.where((w) => w.isAvailable).toList();
    }

    // Filter by Minimum Rating
    if (minRating != null && minRating > 0) {
      results = results.where((w) => w.rating >= minRating).toList();
    }

    // Sorting
    if (sortBy == 'nearest') {
      results.sort((a, b) => a.distanceKm.compareTo(b.distanceKm));
    } else if (sortBy == 'rating') {
      results.sort((a, b) => b.rating.compareTo(a.rating));
    } else if (sortBy == 'charge_low') {
      results.sort((a, b) => a.visitingCharge.compareTo(b.visitingCharge));
    }

    return results;
  }

  @override
  Future<WorkerModel?> getWorkerById(String id) async {
    await Future.delayed(const Duration(milliseconds: 30));
    try {
      return _workers.firstWhere((w) => w.id == id);
    } catch (_) {
      return _workers.isNotEmpty ? _workers.first : null;
    }
  }

  @override
  Future<WorkerModel?> getFeaturedWorker() async {
    return _workers.isNotEmpty ? _workers.first : null;
  }

  WorkerModel? getWorkerByIdSync(String id) {
    try {
      return _workers.firstWhere((w) => w.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<List<ServiceRequestModel>> watchRequests() {
    ensureFirestoreSync();
    // Immediately emit current state
    Future.microtask(() => _requestsStreamController.add(List.unmodifiable(_requests)));
    return _requestsStreamController.stream;
  }

  @override
  Future<List<ServiceRequestModel>> getRequests() async {
    ensureFirestoreSync();
    return List.unmodifiable(_requests);
  }

  @override
  Future<void> createRequest(ServiceRequestModel request) async {
    _requests.insert(0, request);
    _syncWorkersWithRequests();
    _requestsStreamController.add(List.unmodifiable(_requests));

    if (_isFirebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('service_requests')
            .doc(request.id)
            .set(request.toJson());
      } catch (e) {
        debugPrint('Could not save request to Firestore: $e');
      }
    }
  }

  @override
  Future<void> updateRequestStatus(String requestId, BookingStatus status) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(status: status);
      _syncWorkersWithRequests();
      _requestsStreamController.add(List.unmodifiable(_requests));
    }

    if (_isFirebaseReady) {
      try {
        await FirebaseFirestore.instance
            .collection('service_requests')
            .doc(requestId)
            .update({'status': status.label});
      } catch (e) {
        debugPrint('Could not update request status in Firestore: $e');
      }
    }
  }

  @override
  Future<void> submitReview({
    required String requestId,
    required String workerId,
    required double rating,
    required String review,
  }) async {
    // 1. Update request in memory
    final reqIndex = _requests.indexWhere((r) => r.id == requestId);
    if (reqIndex != -1) {
      _requests[reqIndex] = _requests[reqIndex].copyWith(
        ratingGiven: rating,
        reviewGiven: review,
      );
    }

    // 2. Synchronize worker stats (reviews, rating, reviewCount) in memory
    _syncWorkersWithRequests();
    _requestsStreamController.add(List.unmodifiable(_requests));

    // 3. Persist to Firestore
    if (_isFirebaseReady) {
      try {
        final db = FirebaseFirestore.instance;
        final batch = db.batch();

        // Update the rating/review on the request doc
        batch.update(
          db.collection('service_requests').doc(requestId),
          {'ratingGiven': rating, 'reviewGiven': review},
        );

        // Save the review as a sub-document under the worker
        final reviewDoc = db
            .collection('workers')
            .doc(workerId)
            .collection('reviews')
            .doc(requestId);
        batch.set(reviewDoc, {
          'requestId': requestId,
          'reviewerName': reqIndex != -1 ? _requests[reqIndex].customerName : 'Verified Customer',
          'rating': rating,
          'comment': review,
          'date': DateTime.now().toIso8601String(),
        });

        // Also update users/{workerId} with new rating/reviewCount if worker document exists
        final worker = getWorkerByIdSync(workerId);
        if (worker != null) {
          final userDocRef = db.collection('users').doc(workerId);
          batch.set(userDocRef, {
            'rating': worker.rating,
            'reviewCount': worker.reviewCount,
            'jobsCompleted': worker.jobsCompleted,
          }, SetOptions(merge: true));
        }

        await batch.commit();
      } catch (e) {
        debugPrint('Could not save review to Firestore: $e');
      }
    }
  }


  @override
  Future<void> updateWorkerProfile(WorkerModel updatedWorker) async {
    final index = _workers.indexWhere((w) => w.id == updatedWorker.id);
    if (index != -1) {
      _workers[index] = updatedWorker;
    }
  }

  // Populate all workers from the KaamSetu dataset
  void _initWorkers() {
    _workers = [
      // 1. ELECTRICIANS
      const WorkerModel(
        id: 'ramesh',
        name: 'Ramesh Kumar',
        businessName: 'Ramesh Electrical Services',
        category: 'Electrician',
        service: 'Electrical Repair & Installation',
        phone: '+91 98765 43210',
        whatsapp: '919876543210',
        location: 'Vasai - Virar, Maharashtra',
        distanceKm: 1.2,
        rating: 4.8,
        reviewCount: 124,
        experienceYears: 8,
        jobsCompleted: 120,
        visitingCharge: 199,
        isAvailable: true,
        isVerified: true,
        about: 'Experienced electrician providing reliable electrical repair, installation and maintenance services in the local area with 8+ years of field expertise.',
        image: 'assets/images/electrician.jpg',
        pastWorks: [
          WorkPhotoModel(title: 'House Wiring', imagePath: 'assets/images/ps/elect/p1.jpg'),
          WorkPhotoModel(title: 'Fan Installation', imagePath: 'assets/images/ps/elect/p2.jpg'),
          WorkPhotoModel(title: 'Lighting Work', imagePath: 'assets/images/ps/elect/p3.jpg'),
        ],
        reviews: [
          ReviewModel(reviewerName: 'Rahul Mehta', rating: 5.0, comment: 'Very professional, arrived in 20 minutes and completed the wiring work properly.', date: '2 days ago'),
          ReviewModel(reviewerName: 'Neha Sharma', rating: 5.0, comment: 'Good service and reasonable pricing. Cleaned up after finishing the repair.', date: '1 week ago'),
          ReviewModel(reviewerName: 'Amit Verma', rating: 4.0, comment: 'Fixed the short circuit issue quickly. Highly recommended!', date: '2 weeks ago'),
        ],
        servicesProvided: [
          'Electrical Repair',
          'House Wiring',
          'Fan Installation',
          'Switchboard Repair',
          'MCB & Fuse Fixing',
          'Light Installation',
        ],
      ),
      const WorkerModel(
        id: 'mahesh',
        name: 'Mahesh Kumar',
        businessName: 'Mahesh Electrical Works',
        category: 'Electrician',
        service: 'Electrical Repair & Installation',
        phone: '+91 98765 43211',
        whatsapp: '919876543211',
        location: 'Vasai West, Maharashtra',
        distanceKm: 1.8,
        rating: 4.7,
        reviewCount: 98,
        experienceYears: 6,
        jobsCompleted: 95,
        visitingCharge: 149,
        isAvailable: true,
        isVerified: true,
        about: 'Certified residential wireman specializing in quick emergency visits, circuit troubleshooting, and appliance setup.',
        image: 'assets/images/electrician.jpg',
        pastWorks: [
          WorkPhotoModel(title: 'Appliance Fitting', imagePath: 'assets/images/ps/elect/p2.jpg'),
          WorkPhotoModel(title: 'Switchboard Overhaul', imagePath: 'assets/images/ps/elect/p3.jpg'),
        ],
        reviews: [
          ReviewModel(reviewerName: 'Vikas Shah', rating: 5.0, comment: 'Prompt response and polite behavior. Solved the problem quickly.', date: '3 days ago'),
        ],
        servicesProvided: ['Circuit Repair', 'Appliance Setup', 'Wiring', 'Inverter Installation'],
      ),
      const WorkerModel(
        id: 'sunil',
        name: 'Sunil Patil',
        businessName: 'Sunil Power Solutions',
        category: 'Electrician',
        service: 'Electrical Repair & Maintenance',
        phone: '+91 98765 43212',
        whatsapp: '919876543212',
        location: 'Virar East, Maharashtra',
        distanceKm: 2.1,
        rating: 4.6,
        reviewCount: 76,
        experienceYears: 5,
        jobsCompleted: 80,
        visitingCharge: 199,
        isAvailable: false,
        isVerified: true,
        about: 'Specialist in heavy electrical work, distribution boards, and industrial & residential maintenance.',
        image: 'assets/images/electrician.jpg',
        pastWorks: [
          WorkPhotoModel(title: 'Main Line Repair', imagePath: 'assets/images/ps/elect/p1.jpg'),
        ],
        reviews: [
          ReviewModel(reviewerName: 'Kishore J.', rating: 4.5, comment: 'Knowledgeable worker, gave good advice for home earthing.', date: '5 days ago'),
        ],
        servicesProvided: ['Earthing Work', 'Inverter Wiring', 'Power Load Balancing', 'Fan Repair'],
      ),
      const WorkerModel(
        id: 'amit',
        name: 'Amit Sharma',
        businessName: 'Amit Electrical Services',
        category: 'Electrician',
        service: 'Electrical Repair & Installation',
        phone: '+91 98765 43213',
        whatsapp: '919876543213',
        location: 'Nalasopara, Maharashtra',
        distanceKm: 2.7,
        rating: 4.5,
        reviewCount: 64,
        experienceYears: 4,
        jobsCompleted: 60,
        visitingCharge: 179,
        isAvailable: true,
        isVerified: true,
        about: 'Friendly technician with expertise in LED lighting, decorative fixtures, and regular repair work.',
        image: 'assets/images/electrician.jpg',
        pastWorks: [
          WorkPhotoModel(title: 'LED Strip Setup', imagePath: 'assets/images/ps/elect/p3.jpg'),
        ],
        reviews: [
          ReviewModel(reviewerName: 'Pooja K.', rating: 4.5, comment: 'Did neat lighting work for Diwali decoration.', date: '2 weeks ago'),
        ],
        servicesProvided: ['LED Fixtures', 'Chandelier Hanging', 'Wiring Checks', 'Switch Replacement'],
      ),

      // 2. PLUMBERS
      const WorkerModel(
        id: 'suresh',
        name: 'Suresh Yadav',
        businessName: 'Suresh Plumbing Services',
        category: 'Plumber',
        service: 'Plumbing Repair & Installation',
        phone: '+91 98765 43214',
        whatsapp: '919876543214',
        location: 'Vasai - Virar, Maharashtra',
        distanceKm: 2.4,
        rating: 4.6,
        reviewCount: 110,
        experienceYears: 7,
        jobsCompleted: 115,
        visitingCharge: 199,
        isAvailable: true,
        isVerified: true,
        about: 'Expert plumber for water leakage, pipe blockages, taps, flush tanks, and motor pump installations.',
        image: 'assets/images/plumber.jpg',
        pastWorks: [
          WorkPhotoModel(title: 'Bathroom Fittings', imagePath: 'assets/images/ps/plum/plum1.jpg'),
          WorkPhotoModel(title: 'Pipe Leakage Fix', imagePath: 'assets/images/ps/plum/plum2.jpg'),
          WorkPhotoModel(title: 'Water Tank Connection', imagePath: 'assets/images/ps/plum/plum3.jpg'),
        ],
        reviews: [
          ReviewModel(reviewerName: 'Sunil Rao', rating: 5.0, comment: 'Fixed a stubborn drain blockage quickly. Great rate!', date: '3 days ago'),
          ReviewModel(reviewerName: 'Geeta Nair', rating: 4.5, comment: 'Replaced kitchen sink faucet neatly without any mess.', date: '1 week ago'),
        ],
        servicesProvided: [
          'Tap & Faucet Repair',
          'Drain Cleaning & Unclogging',
          'Pipe Leakage Sealing',
          'Water Tank Installation',
          'Toilet Flush Repair',
        ],
      ),
      const WorkerModel(
        id: 'rajplumbing',
        name: 'Raj Singh',
        businessName: 'Raj Plumbing Works',
        category: 'Plumber',
        service: 'Pipe Repair & Plumbing',
        phone: '+91 98765 43215',
        whatsapp: '919876543215',
        location: 'Vasai East, Maharashtra',
        distanceKm: 3.1,
        rating: 4.5,
        reviewCount: 82,
        experienceYears: 5,
        jobsCompleted: 90,
        visitingCharge: 199,
        isAvailable: true,
        isVerified: true,
        about: 'Reliable plumber handling high-pressure pump installations, concealed pipeline repair, and sanitary fixtures.',
        image: 'assets/images/plumber.jpg',
        pastWorks: [
          WorkPhotoModel(title: 'Sanitary Ware Setup', imagePath: 'assets/images/ps/plum/plum1.jpg'),
          WorkPhotoModel(title: 'Concealed Pipe Fitting', imagePath: 'assets/images/ps/plum/plum2.jpg'),
        ],
        reviews: [
          ReviewModel(reviewerName: 'Anil Desai', rating: 4.5, comment: 'Arrived right on time and fixed the shower mixer.', date: '4 days ago'),
        ],
        servicesProvided: ['Shower Mixer Repair', 'Motor Pump Setup', 'Pipeline Fitting', 'Grouting'],
      ),
      const WorkerModel(
        id: 'vijay',
        name: 'Vijay Kumar',
        businessName: 'Vijay Plumbers',
        category: 'Plumber',
        service: 'Plumbing Repair & Fixtures',
        phone: '+91 98765 43216',
        whatsapp: '919876543216',
        location: 'Virar West, Maharashtra',
        distanceKm: 3.5,
        rating: 4.4,
        reviewCount: 50,
        experienceYears: 4,
        jobsCompleted: 58,
        visitingCharge: 149,
        isAvailable: false,
        isVerified: true,
        about: 'Affordable domestic plumbing services for everyday kitchen and washroom leakages.',
        image: 'assets/images/plumber.jpg',
        pastWorks: [
          WorkPhotoModel(title: 'Kitchen Sink Drain', imagePath: 'assets/images/ps/plum/plum3.jpg'),
        ],
        reviews: [
          ReviewModel(reviewerName: 'Preeti S.', rating: 4.0, comment: 'Good work and very reasonable visiting fee.', date: '1 week ago'),
        ],
        servicesProvided: ['Tap Replacement', 'Leak Detection', 'Sink Siphon Repair'],
      ),

      // 3. CLEANING SERVICES
      const WorkerModel(
        id: 'priya',
        name: 'Priya Sharma',
        businessName: 'Priya Home Services',
        category: 'Cleaning',
        service: 'Home Cleaning & Sanitization',
        phone: '+91 98765 43218',
        whatsapp: '919876543218',
        location: 'Vasai - Virar, Maharashtra',
        distanceKm: 0.8,
        rating: 4.9,
        reviewCount: 142,
        experienceYears: 6,
        jobsCompleted: 160,
        visitingCharge: 249,
        isAvailable: true,
        isVerified: true,
        about: 'Professional home hygiene and deep cleaning team. Eco-friendly cleaning materials, high-power scrubbers, and thorough sanitation.',
        image: 'assets/images/cleaning.jpg',
        pastWorks: [
          WorkPhotoModel(title: 'Kitchen Deep Clean', imagePath: 'assets/images/ps/clean/clean1.jpg'),
          WorkPhotoModel(title: 'Bathroom Sanitization', imagePath: 'assets/images/ps/clean/clean2.jpg'),
          WorkPhotoModel(title: 'Sofa & Carpet Wash', imagePath: 'assets/images/ps/clean/clean3.jpg'),
        ],
        reviews: [
          ReviewModel(reviewerName: 'Sneha Patel', rating: 5.0, comment: 'My kitchen looks brand new! Spotless chimney and tile work.', date: '1 day ago'),
          ReviewModel(reviewerName: 'Manish Tiwari', rating: 5.0, comment: 'Superb team. Punctual, polite, and very thorough.', date: '4 days ago'),
        ],
        servicesProvided: [
          'Full House Deep Cleaning',
          'Kitchen Degreasing',
          'Bathroom Tile Scrubbing',
          'Sofa & Carpet Shampooing',
          'Balcony Cleaning',
        ],
      ),
      const WorkerModel(
        id: 'cleancare',
        name: 'CleanCare Team',
        businessName: 'CleanCare Services',
        category: 'Cleaning',
        service: 'Home & Commercial Deep Cleaning',
        phone: '+91 98765 43219',
        whatsapp: '919876543219',
        location: 'Virar West, Maharashtra',
        distanceKm: 1.5,
        rating: 4.7,
        reviewCount: 94,
        experienceYears: 5,
        jobsCompleted: 110,
        visitingCharge: 299,
        isAvailable: true,
        isVerified: true,
        about: 'Equipped with industrial vacuum cleaners and steam sanitizers for deep residential cleaning.',
        image: 'assets/images/cleaning.jpg',
        pastWorks: [
          WorkPhotoModel(title: 'Living Room Cleanup', imagePath: 'assets/images/ps/clean/clean1.jpg'),
          WorkPhotoModel(title: 'Floor Polishing', imagePath: 'assets/images/ps/clean/clean2.jpg'),
        ],
        reviews: [
          ReviewModel(reviewerName: 'Deepak G.', rating: 4.5, comment: 'Great job with festival cleaning before Diwali.', date: '2 weeks ago'),
        ],
        servicesProvided: ['Steam Sanitization', 'Window Glass Cleaning', 'Floor Buffing', 'Move-in Cleaning'],
      ),

      // 4. CARPENTERS
      const WorkerModel(
        id: 'ravi',
        name: 'Ravi Kumar',
        businessName: 'Ravi Furniture Works',
        category: 'Carpenter',
        service: 'Furniture Repair & Custom Carpentry',
        phone: '+91 98765 43222',
        whatsapp: '919876543222',
        location: 'Vasai - Virar, Maharashtra',
        distanceKm: 1.9,
        rating: 4.8,
        reviewCount: 115,
        experienceYears: 9,
        jobsCompleted: 130,
        visitingCharge: 249,
        isAvailable: true,
        isVerified: true,
        about: 'Master carpenter specializing in modular kitchen fittings, door lock repairs, wardrobe alignment, and custom wood restoration.',
        image: 'assets/images/carpenter.jpg',
        pastWorks: [
          WorkPhotoModel(title: 'Wardrobe Fixing', imagePath: 'assets/images/ps/carp/carp1.jpg'),
          WorkPhotoModel(title: 'Door Lock Installation', imagePath: 'assets/images/ps/carp/carp2.jpg'),
          WorkPhotoModel(title: 'Custom Wood Table', imagePath: 'assets/images/ps/carp/carp3.jpg'),
        ],
        reviews: [
          ReviewModel(reviewerName: 'Rohan Joshi', rating: 5.0, comment: 'Realigned 3 wardrobe sliding doors in under an hour. Excellent skill.', date: '3 days ago'),
          ReviewModel(reviewerName: 'Meena Kapoor', rating: 4.5, comment: 'Installed digital door lock perfectly. Very clean job.', date: '1 week ago'),
        ],
        servicesProvided: [
          'Door & Lock Repair',
          'Wardrobe & Drawer Fitting',
          'Modular Kitchen Repair',
          'Bed Assembly & Repair',
          'Wood Polishing',
        ],
      ),
      const WorkerModel(
        id: 'manoj',
        name: 'Manoj Sharma',
        businessName: 'Manoj Carpenter Services',
        category: 'Carpenter',
        service: 'Furniture Repair & Assembly',
        phone: '+91 98765 43223',
        whatsapp: '919876543223',
        location: 'Vasai East, Maharashtra',
        distanceKm: 2.6,
        rating: 4.6,
        reviewCount: 78,
        experienceYears: 6,
        jobsCompleted: 85,
        visitingCharge: 199,
        isAvailable: true,
        isVerified: true,
        about: 'Expert in flat-pack furniture assembly (IKEA, Pepperfry, Urban Ladder) and latch/hinge repairs.',
        image: 'assets/images/carpenter.jpg',
        pastWorks: [
          WorkPhotoModel(title: 'Modular Assembly', imagePath: 'assets/images/ps/carp/carp1.jpg'),
          WorkPhotoModel(title: 'Hinge Replacement', imagePath: 'assets/images/ps/carp/carp3.jpg'),
        ],
        reviews: [
          ReviewModel(reviewerName: 'Aakash M.', rating: 4.5, comment: 'Assembled study table and bookshelf quickly.', date: '5 days ago'),
        ],
        servicesProvided: ['Furniture Assembly', 'Hinge Repair', 'Curtain Rod Fitting', 'Chair Repair'],
      ),

      // 5. PAINTERS
      const WorkerModel(
        id: 'rohit',
        name: 'Rohit Sharma',
        businessName: 'Rohit Painting Services',
        category: 'Painter',
        service: 'Interior & Exterior Painting',
        phone: '+91 98765 43226',
        whatsapp: '919876543226',
        location: 'Vasai - Virar, Maharashtra',
        distanceKm: 1.7,
        rating: 4.8,
        reviewCount: 105,
        experienceYears: 8,
        jobsCompleted: 110,
        visitingCharge: 199,
        isAvailable: true,
        isVerified: true,
        about: 'High-quality wall painting, waterproof putty application, texture designs, and dampness/leakage wall repair.',
        image: 'assets/images/painter.jpg',
        pastWorks: [
          WorkPhotoModel(title: 'Interior Wall Paint', imagePath: 'assets/images/ps/paint/paint1.jpg'),
          WorkPhotoModel(title: 'Texture Design', imagePath: 'assets/images/ps/paint/paint2.jpg'),
          WorkPhotoModel(title: 'Waterproof Primer', imagePath: 'assets/images/ps/paint/paint3.jpg'),
        ],
        reviews: [
          ReviewModel(reviewerName: 'Vivek Jain', rating: 5.0, comment: 'Covered all furniture with plastic sheets before painting. Zero splatter!', date: '6 days ago'),
          ReviewModel(reviewerName: 'Ananya Roy', rating: 4.5, comment: 'Beautiful texture accent wall created in master bedroom.', date: '2 weeks ago'),
        ],
        servicesProvided: [
          'Interior Wall Painting',
          'Waterproofing & Damp Treatment',
          'Texture & Stencil Design',
          'Exterior Weatherproof Paint',
          'Enamel Paint on Doors/Grills',
        ],
      ),

      // 6. AC REPAIR & COOLING
      const WorkerModel(
        id: 'cooltech',
        name: 'CoolTech Engineers',
        businessName: 'CoolTech AC Services',
        category: 'AC Repair',
        service: 'AC Servicing, Gas Refill & Installation',
        phone: '+91 98765 43230',
        whatsapp: '919876543230',
        location: 'Vasai - Virar, Maharashtra',
        distanceKm: 1.4,
        rating: 4.9,
        reviewCount: 160,
        experienceYears: 10,
        jobsCompleted: 180,
        visitingCharge: 299,
        isAvailable: true,
        isVerified: true,
        about: 'Certified HVAC technicians for split and window AC deep jet cleaning, gas charging (R32, R410A), PCB board repair, and installation.',
        image: 'assets/images/Ac.jpg',
        pastWorks: [
          WorkPhotoModel(title: 'Split AC Servicing', imagePath: 'assets/images/ps/ac/ac1.jpg'),
          WorkPhotoModel(title: 'Gas Refill & Check', imagePath: 'assets/images/ps/ac/ac2.jpg'),
          WorkPhotoModel(title: 'Outdoor Unit Mounting', imagePath: 'assets/images/ps/ac/ac3.jpg'),
        ],
        reviews: [
          ReviewModel(reviewerName: 'Kunal Saxena', rating: 5.0, comment: 'Powerjet foam wash did magic. Cooling is like brand new now.', date: '2 days ago'),
          ReviewModel(reviewerName: 'Divya Iyer', rating: 5.0, comment: 'Honest technician. Checked gas pressure in front of me before filling.', date: '1 week ago'),
        ],
        servicesProvided: [
          'Power Jet AC Service',
          'Refrigerant Gas Charging',
          'AC Installation & Uninstallation',
          'PCB Board Troubleshooting',
          'Water Leakage Fix',
        ],
      ),
      const WorkerModel(
        id: 'rajac',
        name: 'Rajendra Verma',
        businessName: 'Raj AC Repair & Services',
        category: 'AC Repair',
        service: 'AC Cooling & Maintenance',
        phone: '+91 98765 43231',
        whatsapp: '919876543231',
        location: 'Virar East, Maharashtra',
        distanceKm: 2.2,
        rating: 4.7,
        reviewCount: 88,
        experienceYears: 6,
        jobsCompleted: 95,
        visitingCharge: 249,
        isAvailable: true,
        isVerified: true,
        about: 'Quick emergency AC technician ready for same-day cooling diagnosis, condenser coil repair, and fan motor repair.',
        image: 'assets/images/Ac.jpg',
        pastWorks: [
          WorkPhotoModel(title: 'Jet Cleaning', imagePath: 'assets/images/ps/ac/ac1.jpg'),
          WorkPhotoModel(title: 'Coil Inspection', imagePath: 'assets/images/ps/ac/ac2.jpg'),
        ],
        reviews: [
          ReviewModel(reviewerName: 'Gaurav B.', rating: 4.5, comment: 'Quick turnaround on a hot summer afternoon.', date: '4 days ago'),
        ],
        servicesProvided: ['Emergency Cooling Fix', 'Condenser Replacement', 'Filter Cleaning', 'Thermostat Fix'],
      ),
    ];
  }

  // ── Worker actions ──────────────────────────────────────

  /// Returns all requests assigned to [workerId] (any status)
  List<ServiceRequestModel> getRequestsForWorker(String workerId) {
    return _requests.where((r) => r.workerId == workerId).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  /// Worker accepts a pending request → status becomes accepted
  void acceptRequest(String requestId) {
    updateRequestStatus(requestId, BookingStatus.accepted);
  }

  /// Worker marks a job as completed → status becomes completed
  void markAsCompleted(String requestId) {
    updateRequestStatus(requestId, BookingStatus.completed);
  }

  /// Registers/updates a worker in the local catalog so they appear in customer Explore & Category lists
  void addOrUpdateWorkerFromUser(UserModel user) {
    if (!user.isWorker) return;
    final cat = user.category ?? 'Electrician';
    String fallbackImg;
    switch (cat.toLowerCase()) {
      case 'electrician':
        fallbackImg = 'assets/images/electrician.jpg';
        break;
      case 'plumber':
        fallbackImg = 'assets/images/plumber.jpg';
        break;
      case 'cleaning':
        fallbackImg = 'assets/images/cleaning.jpg';
        break;
      case 'carpenter':
        fallbackImg = 'assets/images/carpenter.jpg';
        break;
      case 'painter':
        fallbackImg = 'assets/images/painter.jpg';
        break;
      case 'ac repair':
      case 'ac':
        fallbackImg = 'assets/images/Ac.jpg';
        break;
      default:
        fallbackImg = 'assets/images/worker1.png';
    }

    final isOther = cat.toLowerCase() == 'other';
    final serviceTitle = isOther
        ? 'General Repair & Services'
        : '$cat Repair & Services';
    final aboutText = (user.description != null && user.description!.trim().isNotEmpty)
        ? user.description!.trim()
        : isOther
            ? 'Professional local technician providing reliable repair and maintenance services.'
            : 'Professional $cat services with guaranteed quality and workmanship.';

    final servicesList = isOther
        ? ['General Repair', 'Inspection & Estimate', 'Maintenance']
        : ['$cat Inspection', 'Standard Repair', 'Installation & Maintenance'];

    final worker = WorkerModel(
      id: user.id,
      name: user.name,
      businessName: user.name,
      category: cat,
      service: serviceTitle,
      phone: user.phone,
      whatsapp: user.phone,
      location: user.shopAddress ?? user.address,
      distanceKm: 1.0,
      rating: 0.0,
      reviewCount: 0,
      experienceYears: user.experienceYears ?? 0,
      jobsCompleted: 0,
      visitingCharge: user.visitingCharge ?? 0,
      isAvailable: true,
      isVerified: true,
      about: aboutText,
      image: user.photoPath ?? fallbackImg,
      pastWorks: const [],
      reviews: const [],
      servicesProvided: servicesList,
    );

    final idx = _workers.indexWhere((w) => w.id == user.id);
    if (idx >= 0) {
      _workers[idx] = worker;
    } else {
      _workers.insert(0, worker);
    }
    _syncWorkersWithRequests();
  }
}
