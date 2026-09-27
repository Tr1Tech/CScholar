import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/cscholar_logo.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _studentIdController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _error;
  final String _selectedRole = 'student';
  Program? _selectedProgram;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final user = User(
      id: DateTime.now().millisecondsSinceEpoch,
      username: _nameController.text.trim().isNotEmpty
          ? _nameController.text.trim()
          : _emailController.text.split('@').first,
      email: _emailController.text.trim(),
      passwordHash: _passwordController.text,
      role: _selectedRole,
      isActive: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final auth = ref.read(authProvider.notifier);
    final ok = await auth.register(user);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      context.go('/student/dashboard');
    } else {
      setState(() => _error = 'Registration failed. Email may already be in use.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 860;

    return Scaffold(
      // Same clay-on-canvas treatment as login — the two auth screens are one
      // visual unit (see the material law in material_tokens.dart).
      backgroundColor: CScholarMaterial.canvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 1040),
            decoration: BoxDecoration(
              color: CScholarMaterial.clay,
              borderRadius: BorderRadius.circular(CScholarRadius.xxl),
              boxShadow: CScholarMaterial.clayDrop(depth: 1.2),
              // No drawn outline — see login_screen for why a panel this large
              // does not take the control hairline.
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
            CScholarColors.heroMid,
            CScholarColors.heroBase,
            CScholarColors.heroFloor,
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const CScholarLogo(
            iconSize: 52,
            isDark: true,
            subtitle: 'CEIT THESIS REPOSITORY',
          ),
          const SizedBox(height: 24),
          Text(
            'Join your fellow CEIT researchers and access published thesis manuscripts, capstone projects, and AI-powered semantic similarity recommendations.',
            textAlign: TextAlign.center,
            style: CScholarTextStyles.inter(
              13.5,
              FontWeight.w400,
              CScholarColors.heroText,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 32),
          _benefitRow(Icons.search, 'Find prior arts & avoid topic duplication'),
          const SizedBox(height: 14),
          _benefitRow(Icons.bookmark_outline, 'Save and organize reference studies'),
          const SizedBox(height: 14),
          _benefitRow(Icons.school_outlined, 'CEIT official academic indexing'),
        ],
      ),
    );
  }

  Widget _benefitRow(IconData icon, String text) {
    return Row(
      children: [
        // tile-exempt: 28px disc on the DARK hero panel — see login_screen's
        // _featureItem for the full reason.
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
                  'Create Account',
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
              'Register using your CSU institutional credentials',
              style: CScholarTextStyles.inter(13.5, FontWeight.w400, CScholarColors.textSecondary),
            ),
            const SizedBox(height: 24),

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

            // Full Name & Student ID Row
            Row(
              // Top-align: if only one field shows a validation message the
              // other must not float downward.
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: NeumorphField(
                    controller: _nameController,
                    label: 'Full Name',
                    hintText: 'Enter your full name',
                    prefixIcon: Icons.person_outline,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.name],
                    validator: (v) =>
                        (v == null || v.isEmpty) ? 'Enter your full name' : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: NeumorphField(
                    controller: _studentIdController,
                    label: 'Student ID',
                    hintText: 'e.g. 2021-00001',
                    prefixIcon: Icons.badge_outlined,
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Email Field
            NeumorphField(
              controller: _emailController,
              label: 'Institutional Email',
              hintText: 'you@example.com',
              prefixIcon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              autofillHints: const [AutofillHints.email],
              validator: (v) => (v == null || !v.contains('@'))
                  ? 'Please enter a valid institutional email'
                  : null,
            ),

            const SizedBox(height: 16),

            // Degree Program Dropdown (loaded live from GET /api/programs)
            Text('ACADEMIC PROGRAM', style: CScholarTextStyles.inter(11, FontWeight.w700, CScholarColors.textSecondary, letterSpacing: 0.5)),
            const SizedBox(height: 6),
            Consumer(
              builder: (context, ref, _) {
                final programsAsync = ref.watch(programsProvider);
                return programsAsync.when(
                  data: (programs) {
                    if (programs.isEmpty) {
                      return const Text('No programs available');
                    }
                    return NeumorphSelect<Program>(
                      initialValue: _selectedProgram != null &&
                              programs.any((p) => p.id == _selectedProgram!.id)
                          ? programs.firstWhere((p) => p.id == _selectedProgram!.id)
                          : null,
                      prefixIcon: Icons.school_outlined,
                      hintText: 'Select your academic program',
                      items: programs
                          .map((p) => DropdownMenuItem(
                                value: p,
                                child: Text('${p.name} (${p.code})'),
                              ))
                          .toList(),
                      onChanged: (v) => setState(() => _selectedProgram = v),
                      validator: (v) => v == null ? 'Select your academic program' : null,
                    );
                  },
                  loading: () => const ClayLoader(height: 8),
                  error: (err, _) => Text('Could not load programs: $err'),
                );
              },
            ),

            const SizedBox(height: 16),

            // Password & Confirm Password
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: NeumorphField(
                    controller: _passwordController,
                    label: 'Password',
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) => (v == null || v.length < 4)
                        ? 'Min 4 characters'
                        : null,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: NeumorphField(
                    controller: _confirmPasswordController,
                    label: 'Confirm Password',
                    hintText: '••••••••',
                    prefixIcon: Icons.lock_outline,
                    obscureText: true,
                    autofillHints: const [AutofillHints.newPassword],
                    validator: (v) => (v == null || v.length < 4)
                        ? 'Confirm password'
                        : null,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Submit Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: _isLoading ? null : _register,
                style: FilledButton.styleFrom(
                  backgroundColor: CScholarColors.primaryGreen,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(CScholarRadius.lg)),
                ),
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Text('Create Account', style: CScholarTextStyles.inter(15, FontWeight.w700, Colors.white)),
              ),
            ),

            const SizedBox(height: 18),

            // Already have account
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?', style: CScholarTextStyles.inter(13, FontWeight.w400, CScholarColors.textSecondary)),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text('Sign In', style: CScholarTextStyles.inter(13, FontWeight.w700, CScholarColors.primaryGreen)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
