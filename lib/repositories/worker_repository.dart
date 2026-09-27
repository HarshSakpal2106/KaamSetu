import '../models/category_model.dart';
import '../models/service_request_model.dart';
import '../models/worker_model.dart';

abstract class WorkerRepository {
  List<CategoryModel> getCategories();
  
  Future<List<WorkerModel>> getWorkers({
    String? categoryId,
    String? query,
    bool? availableOnly,
    double? minRating,
    String? sortBy, // 'recommended', 'nearest', 'rating'
  });

  Future<WorkerModel?> getWorkerById(String id);

  Future<WorkerModel?> getFeaturedWorker();

  Stream<List<ServiceRequestModel>> watchRequests();

  Future<List<ServiceRequestModel>> getRequests();

  Future<void> createRequest(ServiceRequestModel request);

  Future<void> updateRequestStatus(String requestId, BookingStatus status);

  Future<void> submitReview({
    required String requestId,
    required String workerId,
    required double rating,
    required String review,
  });

  // Worker side functions
  Future<void> updateWorkerProfile(WorkerModel updatedWorker);
}
