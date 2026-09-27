import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class AuthResult {
  final bool success;
  final String? message;

  const AuthResult.ok() : success = true, message = null;
  const AuthResult.fail(this.message) : success = false;
}

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;

  AuthService._internal();

  final ValueNotifier<UserModel?> currentUser = ValueNotifier<UserModel?>(null);

  bool get isAuthenticated => currentUser.value != null;
  bool get isWorker => currentUser.value?.isWorker ?? false;
  bool get isFirebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  String _toAuthEmail(String phoneOrEmail) {
    final value = phoneOrEmail.trim();
    if (value.contains('@')) return value.toLowerCase();
    final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) {
      throw const FormatException('Enter a valid phone number or email');
    }
    return '$digits@users.kaamsetu.app';
  }

  Future<void> restoreSession() async {
    if (!isFirebaseReady) return;
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;
    currentUser.value = await _loadProfile(firebaseUser.uid);
  }

  Future<AuthResult> login({
    required String phoneOrEmail,
    required String password,
    UserRole role = UserRole.customer,
  }) async {
    if (isFirebaseReady) {
      return _firebaseLogin(
        phoneOrEmail: phoneOrEmail,
        password: password,
        expectedRole: role,
      );
    }
    return _mockLogin(phoneOrEmail: phoneOrEmail, role: role);
  }

  Future<AuthResult> signUp({
    required String name,
    required String phone,
    required String address,
    required String password,
    UserRole role = UserRole.customer,
    String? email,
    String? shopAddress,
    String? workerHours,
    String? description,
    String? category,
  }) async {
    if (password.trim().length < 6) {
      return const AuthResult.fail('Password must be at least 6 characters');
    }

    if (isFirebaseReady) {
      return _firebaseSignUp(
        name: name,
        phone: phone,
        address: address,
        password: password,
        role: role,
        email: email,
        shopAddress: shopAddress,
        workerHours: workerHours,
        description: description,
        category: category,
      );
    }

    return _mockSignUp(
      name: name,
      phone: phone,
      address: address,
      role: role,
      shopAddress: shopAddress,
      workerHours: workerHours,
      description: description,
      category: category,
    );
  }

  Future<void> updateUserProfile({
    required String name,
    required String phone,
    required String address,
    required String email,
    String? shopAddress,
    String? workerHours,
    String? description,
    String? category,
  }) async {
    final existing = currentUser.value;
    if (existing == null) return;

    currentUser.value = existing.copyWith(
      name: name,
      phone: phone,
      address: address,
      email: email,
      shopAddress: shopAddress,
      workerHours: workerHours,
      description: description,
      category: category,
    );

    if (!isFirebaseReady) return;
    await FirebaseFirestore.instance.collection('users').doc(existing.id).set(
          currentUser.value!.toJson(),
          SetOptions(merge: true),
        );
  }

  Future<void> logout() async {
    if (isFirebaseReady) {
      await FirebaseAuth.instance.signOut();
    }
    currentUser.value = null;
  }

  Future<AuthResult> _firebaseLogin({
    required String phoneOrEmail,
    required String password,
    required UserRole expectedRole,
  }) async {
    try {
      final credential = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _toAuthEmail(phoneOrEmail),
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        return const AuthResult.fail('Could not sign in. Try again.');
      }

      final profile = await _loadProfile(uid);
      if (profile == null) {
        await FirebaseAuth.instance.signOut();
        return const AuthResult.fail('No profile found for this account.');
      }
      if (profile.role != expectedRole) {
        await FirebaseAuth.instance.signOut();
        final actual = profile.isWorker ? 'worker' : 'customer';
        return AuthResult.fail(
          'This account is a $actual. Switch the toggle at the top and try again.',
        );
      }

      currentUser.value = profile;
      return const AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_authError(e));
    } on FormatException catch (e) {
      return AuthResult.fail(e.message);
    } catch (e) {
      return AuthResult.fail('Login failed. ${e.toString()}');
    }
  }

  Future<AuthResult> _firebaseSignUp({
    required String name,
    required String phone,
    required String address,
    required String password,
    required UserRole role,
    String? email,
    String? shopAddress,
    String? workerHours,
    String? description,
    String? category,
  }) async {
    try {
      final authEmail = email != null && email.contains('@')
          ? email.trim().toLowerCase()
          : _toAuthEmail(phone);
      final credential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: authEmail,
        password: password,
      );
      final uid = credential.user?.uid;
      if (uid == null) {
        return const AuthResult.fail('Could not create account. Try again.');
      }

      final profile = UserModel(
        id: uid,
        name: name.trim(),
        phone: phone.trim(),
        address: address.trim(),
        email: authEmail,
        role: role,
        shopAddress: shopAddress?.trim(),
        workerHours: workerHours?.trim(),
        description: description?.trim(),
        category: category?.trim(),
      );

      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .set(profile.toJson());

      currentUser.value = profile;
      return const AuthResult.ok();
    } on FirebaseAuthException catch (e) {
      return AuthResult.fail(_authError(e));
    } on FormatException catch (e) {
      return AuthResult.fail(e.message);
    } catch (e) {
      return AuthResult.fail('Sign up failed. ${e.toString()}');
    }
  }

  Future<UserModel?> _loadProfile(String uid) async {
    final snap =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (!snap.exists || snap.data() == null) return null;
    final data = Map<String, dynamic>.from(snap.data()!);
    data['id'] = uid;
    return UserModel.fromJson(data);
  }

  String _authError(FirebaseAuthException e) {
    switch (e.code) {
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Wrong email/phone or password.';
      case 'email-already-in-use':
        return 'An account already exists with this phone or email.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'invalid-email':
        return 'Enter a valid phone number or email.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection.';
      default:
        return e.message ?? 'Authentication failed.';
    }
  }

  Future<AuthResult> _mockLogin({
    required String phoneOrEmail,
    required UserRole role,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    if (role == UserRole.worker) {
      currentUser.value = const UserModel(
        id: 'wkr_demo_1',
        name: 'Raju Electricals',
        phone: '+91 98765 43210',
        address: 'Vasai West, Maharashtra',
        email: 'raju@kaamsetu.com',
        role: UserRole.worker,
        shopAddress: 'Shop No 4, Sai Market, Station Road, Vasai West',
        workerHours: 'Mon–Sat, 9am–7pm',
        description:
            'Expert in all kinds of electrical repairs, wiring and fan installation.',
        category: 'Electrician',
        photoPath: 'assets/images/electrician.jpg',
      );
    } else {
      currentUser.value = UserModel(
        id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
        name: 'Harshwardhan',
        phone: phoneOrEmail.contains('@') ? '+91 98765 00001' : phoneOrEmail,
        address: 'Flat 402, Sai Residency, Vasai West',
        email: phoneOrEmail.contains('@') ? phoneOrEmail : 'user@kaamsetu.com',
        role: UserRole.customer,
      );
    }
    return const AuthResult.ok();
  }

  Future<AuthResult> _mockSignUp({
    required String name,
    required String phone,
    required String address,
    required UserRole role,
    String? shopAddress,
    String? workerHours,
    String? description,
    String? category,
  }) async {
    await Future.delayed(const Duration(milliseconds: 300));
    currentUser.value = UserModel(
      id: '${role == UserRole.worker ? 'wkr' : 'usr'}_${DateTime.now().millisecondsSinceEpoch}',
      name: name,
      phone: phone,
      address: address,
      email: '${name.toLowerCase().replaceAll(' ', '')}@kaamsetu.com',
      role: role,
      shopAddress: shopAddress,
      workerHours: workerHours ?? 'Mon–Sat, 9am–6pm',
      description: description,
      category: category,
    );
    return const AuthResult.ok();
  }
}
