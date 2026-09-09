import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/cscholar_logo.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: 'student@csu.edu.ph');
  final _passwordController = TextEditingController(text: 'pass123');
  bool _isLoading = false;
  String? _error;
  bool _obscure = true;
  bool _rememberMe = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _fillDemo(String email) {
    setState(() {
      _emailController.text = email;
      _passwordController.text = 'pass123';
      _error = null;
    });
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final auth = ref.read(authProvider.notifier);
    final ok = await auth.login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      final user = ref.read(currentUserProvider);
      if (user?.role == 'admin') {
        context.go('/admin/dashboard');
      } else {
        context.go('/student/dashboard');
      }
    } else {
      setState(() => _error = 'Invalid credentials. Please click a demo role below.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 860;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F6),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 980),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(CScholarRadius.xxl),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.08),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            clipBehavior: Clip.antiAlias,
            child: isDesktop
                ? IntrinsicHeight(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(flex: 5, child: _leftBrandedPanel()),
                        Expanded(flex: 7, child: _rightFormPanel()),
                      ],
                    ),
                  )
                : Column(
                    children: [
                      _leftBrandedPanel(isMobile: true),
                      _rightFormPanel(),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _leftBrandedPanel({bool isMobile = false}) {
    return Container(
      padding: EdgeInsets.all(isMobile ? 28 : 44),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF005A1E),
            Color(0xFF00471B),
            Color(0xFF043313),
          ],
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Logo & Identity
          Column(
            children: [
              const CScholarLogo(
                iconSize: 52,
                isDark: true,
                subtitle: 'CEIT THESIS REPOSITORY',
              ),
              const SizedBox(height: 24),
              Text(
                'Centralized institutional repository of engineering and technology theses, capstone projects, and scholarly works.',
                textAlign: TextAlign.center,
                style: CScholarTextStyles.inter(
                  13.5,
                  FontWeight.w400,
                  const Color(0xFFD1FAE5),
                  height: 1.6,
                ),
              ),
            ],
          ),

          if (!isMobile) ...[
            const SizedBox(height: 36),
            // Value propositions
            Column(
              children: [
                _featureItem(Icons.auto_awesome, 'Semantic Similarity Engine'),
                const SizedBox(height: 14),
                _featureItem(Icons.archive_outlined, 'Centralized CEIT Archive'),
                const SizedBox(height: 14),
                _featureItem(Icons.verified_user_outlined, 'Student & Faculty Research Access'),
              ],
            ),
            const SizedBox(height: 36),
          ],

          // University affiliation footer
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(CScholarRadius.full),
              border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.school, size: 16, color: CScholarColors.gold),
                const SizedBox(width: 8),
                Text(
                  'CSU CEIT Campus Portal',
                  style: CScholarTextStyles.inter(11, FontWeight.w600, const Color(0xFFD1FAE5)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _featureItem(IconData icon, String text) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 16, color: CScholarColors.gold),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: CScholarTextStyles.inter(13, FontWeight.w500, Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _rightFormPanel() {
    return Padding(
      padding: const EdgeInsets.all(36),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Welcome Back',
                  style: CScholarTextStyles.poppins(26, FontWeight.w800, CScholarColors.textPrimary),
                ),
                TextButton(
                  onPressed: () => context.go('/'),
                  child: Text('Home', style: CScholarTextStyles.inter(12, FontWeight.w600, CScholarColors.textSecondary)),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Sign in to access your saved studies and repository tools',
              style: CScholarTextStyles.inter(13.5, FontWeight.w400, CScholarColors.textSecondary),
            ),
            const SizedBox(height: 20),

            // Demo Account Switcher Pills
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(CScholarRadius.lg),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'QUICK DEMO ACCOUNTS (CLICK TO AUTO-FILL):',
                    style: CScholarTextStyles.inter(10, FontWeight.w700, CScholarColors.textMuted, letterSpacing: 0.5),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      _demoButton('Student', 'student@csu.edu.ph', CScholarColors.primaryGreen),
                      _demoButton('Faculty', 'faculty@csu.edu.ph', const Color(0xFF9333EA)),
                      _demoButton('Admin', 'admin@csu.edu.ph', CScholarColors.orange),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            if (_error != null) ...[
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: CScholarColors.errorLight,
                  borderRadius: BorderRadius.circular(CScholarRadius.md),
                  border: Border.all(color: CScholarColors.error.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, size: 18, color: CScholarColors.error),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _error!,
                        style: CScholarTextStyles.inter(12, FontWeight.w500, CScholarColors.error),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Email Field
            Text(
              'INSTITUTIONAL EMAIL',
              style: CScholarTextStyles.inter(11, FontWeight.w700, CScholarColors.textSecondary, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              validator: (v) => (v == null || !v.contains('@')) ? 'Please enter a valid institutional email' : null,
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.email_outlined, size: 18, color: CScholarColors.textHint),
                hintText: 'e.g. juan.delacruz@csu.edu.ph',
              ),
            ),

            const SizedBox(height: 16),

            // Password Field
            Text(
              'PASSWORD',
              style: CScholarTextStyles.inter(11, FontWeight.w700, CScholarColors.textSecondary, letterSpacing: 0.5),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscure,
              validator: (v) => (v == null || v.length < 4) ? 'Password must be at least 4 characters' : null,
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.lock_outline, size: 18, color: CScholarColors.textHint),
                hintText: '••••••••',
                suffixIcon: IconButton(
                  icon: Icon(_obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: CScholarColors.textHint),
                  onPressed: () => setState(() => _obscure = !_obscure),
                ),
              ),
            ),

            const SizedBox(height: 14),

            // Remember me & Forgot password
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    SizedBox(
                      width: 20,
                      height: 20,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v ?? true),
                        activeColor: CScholarColors.primaryGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('Remember me', style: CScholarTextStyles.inter(12, FontWeight.w400, CScholarColors.textSecondary)),
                  ],
                ),
                TextButton(
                  onPressed: () {},
                  child: Text('Forgot password?', style: CScholarTextStyles.inter(12, FontWeight.w600, CScholarColors.primaryGreen)),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Sign In Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isLoading ? null : _login,
                style: FilledButton.styleFrom(
                  backgroundColor: CScholarColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.lg)),
                  elevation: 2,
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Sign In', style: CScholarTextStyles.inter(15, FontWeight.w700, Colors.white)),
              ),
            ),

            const SizedBox(height: 20),

            // Register Link
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?", style: CScholarTextStyles.inter(13, FontWeight.w400, CScholarColors.textSecondary)),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: Text('Register here', style: CScholarTextStyles.inter(13, FontWeight.w700, CScholarColors.primaryGreen)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _demoButton(String role, String email, Color color) {
    return InkWell(
      onTap: () => _fillDemo(email),
      borderRadius: BorderRadius.circular(CScholarRadius.sm),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(CScholarRadius.sm),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Text(
          role,
          style: CScholarTextStyles.inter(11.5, FontWeight.w700, color),
        ),
      ),
    );
  }
}
