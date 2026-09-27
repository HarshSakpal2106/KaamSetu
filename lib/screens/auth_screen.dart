import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import 'main_navigation_screen.dart';
import 'worker_main_navigation_screen.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Role selection — shown BEFORE the form
  UserRole? _selectedRole;

  // Login form
  final _loginFormKey = GlobalKey<FormState>();
  final _loginPhoneOrEmailCtrl = TextEditingController();
  final _loginPasswordCtrl = TextEditingController();

  // Customer sign-up form
  final _signupFormKey = GlobalKey<FormState>();
  final _signupNameCtrl = TextEditingController();
  final _signupPhoneCtrl = TextEditingController();
  final _signupAddressCtrl = TextEditingController();
  final _signupPasswordCtrl = TextEditingController();

  // Worker sign-up extra fields
  final _workerShopAddressCtrl = TextEditingController();
  final _workerHoursCtrl = TextEditingController();
  final _workerDescCtrl = TextEditingController();
  String? _workerCategory;

  static const _categories = [
    'Electrician',
    'Plumber',
    'Carpenter',
    'Painter',
    'AC Repair',
    'Cleaning',
    'Mechanic',
    'Other',
  ];

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
    _workerShopAddressCtrl.dispose();
    _workerHoursCtrl.dispose();
    _workerDescCtrl.dispose();
    super.dispose();
  }

  void _navigateToHome() {
    final isWorker = AuthService().isWorker;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => isWorker
            ? const WorkerMainNavigationScreen()
            : const MainNavigationScreen(),
      ),
    );
  }

  void _handleLogin() async {
    if (!_loginFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final result = await AuthService().login(
      phoneOrEmail: _loginPhoneOrEmailCtrl.text.trim(),
      password: _loginPasswordCtrl.text.trim(),
      role: _selectedRole ?? UserRole.customer,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      _navigateToHome();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Login failed'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  void _handleSignUp() async {
    if (!_signupFormKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    final isWorker = _selectedRole == UserRole.worker;
    final result = await AuthService().signUp(
      name: _signupNameCtrl.text.trim(),
      phone: _signupPhoneCtrl.text.trim(),
      address: isWorker
          ? _workerShopAddressCtrl.text.trim()
          : _signupAddressCtrl.text.trim(),
      password: _signupPasswordCtrl.text.trim(),
      role: _selectedRole ?? UserRole.customer,
      shopAddress: isWorker ? _workerShopAddressCtrl.text.trim() : null,
      workerHours: isWorker && _workerHoursCtrl.text.trim().isNotEmpty
          ? _workerHoursCtrl.text.trim()
          : null,
      description: isWorker && _workerDescCtrl.text.trim().isNotEmpty
          ? _workerDescCtrl.text.trim()
          : null,
      category: isWorker ? _workerCategory : null,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (result.success) {
      _navigateToHome();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.message ?? 'Sign up failed'),
          backgroundColor: Colors.red.shade600,
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding:
                const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Brand Header with custom logo
                ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: Image.asset(
                    'assets/images/app_logo.png',
                    width: 110,
                    height: 110,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'KaamSetu',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your Trusted Local Service Network',
                  style: TextStyle(
                      fontSize: 13, color: AppColors.textSecondary),
                ),
                const SizedBox(height: 24),

                // ── Step 1: Role selection ──────────────────
                if (_selectedRole == null) ...[
                  _buildRoleSelection(),
                ] else ...[
                  // ── Step 2: Login / Sign-up form ───────────
                  _buildFormCard(),
                ],

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

  // ─────────────────────────────────────────────────────
  // Role selection cards
  // ─────────────────────────────────────────────────────

  Widget _buildRoleSelection() {
    return Column(
      children: [
        const Text(
          'I am a...',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: _RoleCard(
                imageAsset: 'assets/images/customer_icon.jpg',
                label: 'Customer',
                subtitle: 'Find & book workers',
                onTap: () => setState(() => _selectedRole = UserRole.customer),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _RoleCard(
                imageAsset: 'assets/images/worker_icon.jpg',
                label: 'Worker',
                subtitle: 'Accept & manage jobs',
                onTap: () => setState(() => _selectedRole = UserRole.worker),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  // Form card (login + signup tabs)
  // ─────────────────────────────────────────────────────

  Widget _buildFormCard() {
    final isWorker = _selectedRole == UserRole.worker;
    return Column(
      children: [
        // "Back" to role selection
        Row(
          children: [
            GestureDetector(
              onTap: () => setState(() => _selectedRole = null),
              child: Row(
                children: [
                  const Icon(Icons.arrow_back_ios,
                      size: 14, color: AppColors.primary),
                  const SizedBox(width: 2),
                  Text(
                    'Change role',
                    style: const TextStyle(
                        fontSize: 13, color: AppColors.primary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              decoration: BoxDecoration(
                color: isWorker
                    ? Colors.orange.shade50
                    : AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: isWorker
                        ? Colors.orange.shade300
                        : AppColors.primary.withValues(alpha: 0.3)),
              ),
              child: Text(
                isWorker ? '🔧 Worker' : '👤 Customer',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isWorker ? Colors.orange.shade700 : AppColors.primary,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),

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
              // Tab Bar
              Container(
                decoration: const BoxDecoration(
                  border:
                      Border(bottom: BorderSide(color: AppColors.border)),
                ),
                child: TabBar(
                  controller: _tabController,
                  indicatorColor: AppColors.primary,
                  indicatorWeight: 3,
                  labelColor: AppColors.primary,
                  unselectedLabelColor: AppColors.textMuted,
                  labelStyle: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 15),
                  tabs: const [
                    Tab(text: 'Log In'),
                    Tab(text: 'Sign Up'),
                  ],
                ),
              ),

              // Tab Views — dynamic height
              SizedBox(
                height: isWorker ? 480 : 400,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    _buildLoginForm(),
                    _buildSignUpForm(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────
  // Login form
  // ─────────────────────────────────────────────────────

  Widget _buildLoginForm() {
    final isWorker = _selectedRole == UserRole.worker;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _loginFormKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              isWorker ? 'Welcome Back, Worker' : 'Welcome Back',
              style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              isWorker
                  ? 'Sign in to manage your jobs and profile'
                  : 'Sign in to contact workers and manage bookings',
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 18),

            TextFormField(
              controller: _loginPhoneOrEmailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: 'Phone Number or Email',
                hintText: isWorker
                    ? 'e.g. +91 98765 43210'
                    : 'e.g. +91 98765 43210',
                prefixIcon:
                    const Icon(Icons.person_outline, size: 20),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Enter your phone or email'
                  : null,
            ),
            const SizedBox(height: 12),

            TextFormField(
              controller: _loginPasswordCtrl,
              obscureText: !_isPasswordVisible,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Enter your password',
                prefixIcon:
                    const Icon(Icons.lock_outline, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_off
                          : Icons.visibility,
                      size: 18),
                  onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 14, vertical: 12),
              ),
              validator: (v) =>
                  (v == null || v.length < 4) ? 'Enter password' : null,
            ),
            const SizedBox(height: 24),

            SizedBox(
              width: double.infinity,
              height: 46,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isLoading ? null : _handleLogin,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2))
                    : const Text('Log In',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────
  // Sign-up form (customer or worker)
  // ─────────────────────────────────────────────────────

  Widget _buildSignUpForm() {
    final isWorker = _selectedRole == UserRole.worker;
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Form(
        key: _signupFormKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isWorker
                    ? 'Register as Worker'
                    : 'Create Customer Account',
                style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                isWorker
                    ? 'Set up your profile to start receiving jobs'
                    : 'Register in seconds to connect with workers',
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary),
              ),
              const SizedBox(height: 14),

              // Full Name
              _field(
                controller: _signupNameCtrl,
                label: 'Full Name',
                hint: isWorker
                    ? 'e.g. Raju Electricals'
                    : 'e.g. Rahul Sharma',
                icon: Icons.person_outline,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter your name'
                    : null,
              ),
              const SizedBox(height: 10),

              // Phone
              _field(
                controller: _signupPhoneCtrl,
                label: 'Phone Number',
                hint: 'e.g. +91 98765 43210',
                icon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'Enter phone number'
                    : null,
              ),
              const SizedBox(height: 10),

              // Customer: home address | Worker: shop address (required)
              if (!isWorker)
                _field(
                  controller: _signupAddressCtrl,
                  label: 'Area / Address',
                  hint: 'e.g. Vasai West, Maharashtra',
                  icon: Icons.location_on_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter your address'
                      : null,
                ),

              if (isWorker) ...[
                _field(
                  controller: _workerShopAddressCtrl,
                  label: 'Shop / Work Address',
                  hint: 'e.g. Shop 4, Sai Market, Station Rd, Vasai',
                  icon: Icons.store_outlined,
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Shop address is required'
                      : null,
                ),
                const SizedBox(height: 10),

                // Category dropdown
                DropdownButtonFormField<String>(
                  value: _workerCategory,
                  isExpanded: true,
                  decoration: InputDecoration(
                    labelText: 'Service Category',
                    prefixIcon:
                        const Icon(Icons.build_outlined, size: 20),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 12),
                  ),
                  hint: const Text('Select your trade'),
                  items: _categories
                      .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                      .toList(),
                  onChanged: (v) =>
                      setState(() => _workerCategory = v),
                  validator: (v) => v == null ? 'Select a category' : null,
                ),
                const SizedBox(height: 10),

                _field(
                  controller: _workerHoursCtrl,
                  label: 'Working Hours (Optional)',
                  hint: 'e.g. Mon–Sat, 9am–7pm',
                  icon: Icons.access_time_outlined,
                ),
                const SizedBox(height: 10),

                _field(
                  controller: _workerDescCtrl,
                  label: 'Short Description (Optional)',
                  hint: 'e.g. 8 years experience in house wiring...',
                  icon: Icons.notes_outlined,
                  maxLines: 2,
                ),
              ],

              const SizedBox(height: 10),

              // Password
              TextFormField(
                controller: _signupPasswordCtrl,
                obscureText: !_isPasswordVisible,
                decoration: InputDecoration(
                  labelText: 'Create Password',
                  hintText: 'At least 4 characters',
                  prefixIcon:
                      const Icon(Icons.lock_outline, size: 20),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                ),
                validator: (v) => (v == null || v.length < 4)
                    ? 'Password must be at least 4 characters'
                    : null,
              ),
              const SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: _isLoading ? null : _handleSignUp,
                  child: _isLoading
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2))
                      : const Text('Sign Up',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    required IconData icon,
    TextInputType? keyboardType,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon, size: 20),
        border:
            OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      ),
      validator: validator,
    );
  }
}

// ────────────────────────────────────────────────────────
// Role card widget
// ────────────────────────────────────────────────────────

class _RoleCard extends StatelessWidget {
  final String imageAsset;
  final String label;
  final String subtitle;
  final VoidCallback onTap;

  const _RoleCard({
    required this.imageAsset,
    required this.label,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  imageAsset,
                  fit: BoxFit.contain,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: AppColors.textPrimary),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
