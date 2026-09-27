import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../services/auth_service.dart';
import 'main_navigation_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Login form controllers
  final _loginFormKey = GlobalKey<FormState>();
  final _loginPhoneOrEmailCtrl = TextEditingController(text: '+91 98765 00001');
  final _loginPasswordCtrl = TextEditingController(text: 'password123');

  // Sign up form controllers
  final _signupFormKey = GlobalKey<FormState>();
  final _signupNameCtrl = TextEditingController();
  final _signupPhoneCtrl = TextEditingController();
  final _signupAddressCtrl = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _loginPhoneOrEmailCtrl.dispose();
    _loginPasswordCtrl.dispose();
    _signupNameCtrl.dispose();
    _signupPhoneCtrl.dispose();
    _signupAddressCtrl.dispose();
    _signupPasswordCtrl.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await AuthService().login(
      phoneOrEmail: _loginPhoneOrEmailCtrl.text.trim(),
      password: _loginPasswordCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  void _handleSignUp() async {
    if (!_signupFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    await AuthService().signUp(
      name: _signupNameCtrl.text.trim(),
      phone: _signupPhoneCtrl.text.trim(),
      address: _signupAddressCtrl.text.trim(),
      password: _signupPasswordCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const MainNavigationScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brand Header
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.3),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Text(
                      '🛠️',
                      style: TextStyle(fontSize: 32),
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                const Text(
                  'KaamSetu',
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your Trusted Local Service Network',
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 28),

                // Card Container
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.border),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Tab Switcher
                      Container(
                        decoration: const BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.border)),
                        ),
                        child: TabBar(
                          controller: _tabController,
                          indicatorColor: AppColors.primary,
                          indicatorWeight: 3,
                          labelColor: AppColors.primary,
                          unselectedLabelColor: AppColors.textMuted,
                          labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                          tabs: const [
                            Tab(text: 'Log In'),
                            Tab(text: 'Sign Up'),
                          ],
                        ),
                      ),

                      // Tab Views
                      SizedBox(
                        height: 380,
                        child: TabBarView(
                          controller: _tabController,
                          children: [
                            // 1. Login Form
                            _buildLoginForm(),

                            // 2. Sign Up Form
                            _buildSignUpForm(),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),
                const Text(
                  '© 2026 KaamSetu • Secure Local Service Platform',
                  style: TextStyle(fontSize: 11, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Welcome Back',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            const Text(
              'Sign in to contact workers and manage bookings',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),

            TextFormField(
              controller: _loginPhoneOrEmailCtrl,
              decoration: InputDecoration(
                labelText: 'Phone Number or Email',
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your phone or email' : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _loginPasswordCtrl,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_isPasswordVisible ? Icons.visibility_off : Icons.visibility, size: 18),
                  onPressed: () => setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              ),
              validator: (v) => (v == null || v.length < 4) ? 'Enter password' : null,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Log In', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSignUpForm() {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _signupFormKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Create Customer Account',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                'Register in 30 seconds to connect with workers',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),

              TextFormField(
                controller: _signupNameCtrl,
                decoration: InputDecoration(
                  labelText: 'Full Name',
                  prefixIcon: const Icon(Icons.person_outline, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your name' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _signupPhoneCtrl,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Phone Number',
                  prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter phone number' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _signupAddressCtrl,
                decoration: InputDecoration(
                  labelText: 'Area / Address (e.g. Vasai West)',
                  prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter your address' : null,
              ),
              const SizedBox(height: 10),

              TextFormField(
                controller: _signupPasswordCtrl,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Create Password',
                  prefixIcon: const Icon(Icons.lock_outline, size: 20),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                ),
                validator: (v) => (v == null || v.length < 4) ? 'Password must be at least 4 characters' : null,
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _handleSignUp,
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Sign Up', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
