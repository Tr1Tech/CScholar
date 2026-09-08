// Login screen — Stitch design v2 (two-panel layout)

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final bool _isLoading = false;
  String? _error;
  bool _obscure = true;
  String _selectedRole = 'student';

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _error = null);

    final auth = ref.read(authProvider.notifier);
    final ok = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    if (ok) {
      context.go('/student/dashboard');
    } else {
      setState(() => _error = 'Invalid email or password.\n\nDemo credentials:\n• student@csu.edu.ph / pass123\n• faculty@csu.edu.ph / pass123\n• admin@csu.edu.ph / pass123');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isWide = size.width > 720;

    // Mobile: full screen form
    if (!isWide) {
      return _mobileLayout();
    }

    // Desktop: two-panel layout
    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      body: Row(
        children: [
          // Left: branded panel
          Expanded(
            flex: 5,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [CScholarColors.sidebarDeep, CScholarColors.adminSidebar],
                ),
              ),
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(48),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Logo
                      Row(
                        children: [
                          Container(
                            width: 56,
                            height: 56,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: CScholarColors.gold.withValues(alpha: 0.3)),
                            ),
                            child: const Icon(Icons.school, color: CScholarColors.gold, size: 28),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'CScholar',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 28,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: -0.5,
                                ),
                              ),
                              Text(
                                'CEIT THESIS REPOSITORY',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 2,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const SizedBox(height: 48),
                      // Tagline
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: CScholarColors.gold.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: CScholarColors.gold.withValues(alpha: 0.3)),
                        ),
                        child: const Text(
                          'CEIT Thesis & Capstone Repository',
                          style: TextStyle(
                            color: CScholarColors.gold,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      const Text(
                        'Access a world of knowledge\nand research from the\nCEIT department.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 18,
                          height: 1.5,
                        ),
                      ),
                      const SizedBox(height: 48),
                      // Stats row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: const [
                          Column(
                            children: [
                              Text('1,248', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                              Text('Archived Studies', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                          Column(
                            children: [
                              Text('3', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                              Text('CEIT Programs', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                          Column(
                            children: [
                              Text('5+', style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
                              Text('Academic Years', style: TextStyle(color: Colors.white70, fontSize: 12)),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // Right: login form
          Expanded(
            flex: 4,
            child: Center(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(48),
                child: _loginForm(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mobileLayout() {
    return Scaffold(
      backgroundColor: CScholarColors.backgroundLight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: CScholarColors.primaryGreen,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.school, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'CScholar',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: CScholarColors.textPrimary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'CEIT Repository',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: CScholarColors.textSecondary,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 32),
              _loginForm(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _loginForm() {
    return Container(
      padding: const EdgeInsets.all(40),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Role selector
            const Text(
              'Sign in as',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: CScholarColors.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
            SegmentedButton<String>(
              segments: [
                const ButtonSegment(value: 'student', label: Text('Student'), icon: Icon(Icons.person)),
                const ButtonSegment(value: 'faculty', label: Text('Faculty'), icon: Icon(Icons.person_outline)),
                const ButtonSegment(value: 'admin', label: Text('Admin'), icon: Icon(Icons.admin_panel_settings)),
              ],
              selected: {_selectedRole},
              onSelectionChanged: (set) {
                setState(() => _selectedRole = set.first);
                // Auto-fill demo credentials
                if (set.first == 'student') {
                  _emailController.text = 'student@csu.edu.ph';
                  _passwordController.text = 'pass123';
                } else if (set.first == 'faculty') {
                  _emailController.text = 'faculty@csu.edu.ph';
                  _passwordController.text = 'pass123';
                } else {
                  _emailController.text = 'admin@csu.edu.ph';
                  _passwordController.text = 'pass123';
                }
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) {
                    return CScholarColors.primaryGreen.withValues(alpha: 0.1);
                  }
                  return Colors.transparent;
                }),
              ),
            ),
            const SizedBox(height: 20),

            // Email
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              style: const TextStyle(color: CScholarColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Email address',
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: CScholarColors.backgroundLight,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
            ),
            const SizedBox(height: 16),

            // Password
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              style: const TextStyle(color: CScholarColors.textPrimary),
              decoration: InputDecoration(
                labelText: 'Password',
                prefixIcon: const Icon(Icons.lock_outlined, size: 20),
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 20),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                filled: true,
                fillColor: CScholarColors.backgroundLight,
              ),
              validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              onFieldSubmitted: (_) => _login(),
            ),
            const SizedBox(height: 8),

            // Error
            if (_error != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: CScholarColors.error.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: CScholarColors.error.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _error!,
                  style: const TextStyle(fontSize: 13, color: CScholarColors.error, height: 1.4),
                ),
              ),

            // Sign In button
            FilledButton(
              onPressed: _isLoading ? null : _login,
              style: FilledButton.styleFrom(
                backgroundColor: CScholarColors.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: _isLoading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Sign In', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            ), // FilledButton
          ],
        ), // Column
      ), // Form
    ); // Container
  }
}
