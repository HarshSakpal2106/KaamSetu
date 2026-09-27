import 'dart:async';
import '../models/category_model.dart';
import '../models/review_model.dart';
import '../models/service_request_model.dart';
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

  MockWorkerRepository._internal() {
    _initWorkers();
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

  @override
  Future<List<WorkerModel>> getWorkers({
    String? categoryId,
    String? query,
    bool? availableOnly,
    double? minRating,
    String? sortBy,
  }) async {
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

  @override
  Stream<List<ServiceRequestModel>> watchRequests() {
    // Immediately emit current state
    Future.microtask(() => _requestsStreamController.add(List.unmodifiable(_requests)));
    return _requestsStreamController.stream;
  }

  @override
  Future<List<ServiceRequestModel>> getRequests() async {
    return List.unmodifiable(_requests);
  }

  @override
  Future<void> createRequest(ServiceRequestModel request) async {
    _requests.insert(0, request);
    _requestsStreamController.add(List.unmodifiable(_requests));
  }

  @override
  Future<void> updateRequestStatus(String requestId, BookingStatus status) async {
    final index = _requests.indexWhere((r) => r.id == requestId);
    if (index != -1) {
      _requests[index] = _requests[index].copyWith(status: status);
      _requestsStreamController.add(List.unmodifiable(_requests));
    }
  }

  @override
  Future<void> submitReview({
    required String requestId,
    required String workerId,
    required double rating,
    required String review,
  }) async {
    // Update request
    final reqIndex = _requests.indexWhere((r) => r.id == requestId);
    if (reqIndex != -1) {
      _requests[reqIndex] = _requests[reqIndex].copyWith(
        ratingGiven: rating,
        reviewGiven: review,
      );
      _requestsStreamController.add(List.unmodifiable(_requests));
    }

    // Add review to worker profile
    final workerIndex = _workers.indexWhere((w) => w.id == workerId);
    if (workerIndex != -1) {
      final worker = _workers[workerIndex];
      final newReview = ReviewModel(
        reviewerName: 'You (Verified Customer)',
        rating: rating,
        comment: review,
        date: 'Just now',
      );
      final updatedReviews = [newReview, ...worker.reviews];
      _workers[workerIndex] = worker.copyWith(
        reviews: updatedReviews,
        reviewCount: worker.reviewCount + 1,
      );
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
    final idx = _requests.indexWhere((r) => r.id == requestId);
    if (idx == -1) return;
    _requests[idx] = _requests[idx].copyWith(status: BookingStatus.accepted);
    _requestsStreamController.add(List.unmodifiable(_requests));
  }

  /// Worker marks a job as completed → status becomes completed
  void markAsCompleted(String requestId) {
    final idx = _requests.indexWhere((r) => r.id == requestId);
    if (idx == -1) return;
    _requests[idx] = _requests[idx].copyWith(status: BookingStatus.completed);
    _requestsStreamController.add(List.unmodifiable(_requests));
  }
}
