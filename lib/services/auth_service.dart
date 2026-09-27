import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  // Starts null so the Auth screen is shown on first launch
  final ValueNotifier<UserModel?> currentUser = ValueNotifier<UserModel?>(null);

  bool get isAuthenticated => currentUser.value != null;
  bool get isWorker => currentUser.value?.isWorker ?? false;

  // ─────────────────── Customer auth ───────────────────

  Future<bool> login({
    required String phoneOrEmail,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    currentUser.value = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: 'Harshwardhan',
      phone: phoneOrEmail.contains('@') ? '+91 98765 00001' : phoneOrEmail,
      address: 'Flat 402, Sai Residency, Vasai West',
      email: phoneOrEmail.contains('@') ? phoneOrEmail : 'user@kaamsetu.com',
      role: UserRole.customer,
    );
    return true;
  }

  Future<bool> signUp({
    required String name,
    required String phone,
    required String address,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    currentUser.value = UserModel(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      address: address,
      email: '${name.toLowerCase().replaceAll(' ', '')}@kaamsetu.com',
      role: UserRole.customer,
    );
    return true;
  }

  // ─────────────────── Worker auth ───────────────────

  Future<bool> workerLogin({
    required String phoneOrEmail,
    required String password,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    // Mock: any credentials work, return a demo worker profile
    currentUser.value = const UserModel(
      id: 'wkr_demo_1',
      name: 'Raju Electricals',
      phone: '+91 98765 43210',
      address: 'Vasai West, Maharashtra',
      email: 'raju@kaamsetu.com',
      role: UserRole.worker,
      shopAddress: 'Shop No 4, Sai Market, Station Road, Vasai West',
      workerHours: 'Mon–Sat, 9am–7pm',
      description: 'Expert in all kinds of electrical repairs, wiring and fan installation.',
      category: 'Electrician',
      photoPath: 'assets/images/electrician.jpg',
    );
    return true;
  }

  Future<bool> workerSignUp({
    required String name,
    required String phone,
    required String shopAddress,
    required String category,
    required String password,
    String? workerHours,
    String? description,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    currentUser.value = UserModel(
      id: 'wkr_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      address: shopAddress,
      email: '${name.toLowerCase().replaceAll(' ', '')}@kaamsetu.com',
      role: UserRole.worker,
      shopAddress: shopAddress,
      workerHours: workerHours ?? 'Mon–Sat, 9am–6pm',
      description: description,
      category: category,
    );
    return true;
  }

  // ─────────────────── Profile update ───────────────────

  void updateUserProfile({
    required String name,
    required String phone,
    required String address,
    required String email,
    // Worker extras (ignored for customers)
    String? shopAddress,
    String? workerHours,
    String? description,
    String? category,
  }) {
    if (currentUser.value != null) {
      currentUser.value = currentUser.value!.copyWith(
        name: name,
        phone: phone,
        address: address,
        email: email,
        shopAddress: shopAddress,
        workerHours: workerHours,
        description: description,
        category: category,
      );
    }
  }

  void logout() {
    currentUser.value = null;
  }
}
