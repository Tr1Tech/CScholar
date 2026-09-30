import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/presentation/widgets/common/auth_shell.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';

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
    return AuthShell(
      maxCardWidth: 560,
      child: Form(
        key: _formKey,
        child: StaggerColumn(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create your account',
              textAlign: TextAlign.center,
              style: CScholarTextStyles.poppins(
                  26, FontWeight.w800, CScholarColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Register using your CSU institutional credentials',
              textAlign: TextAlign.center,
              style: CScholarTextStyles.inter(
                  13.5, FontWeight.w400, CScholarColors.textMuted),
            ),
            const SizedBox(height: 20),

            AuthErrorBanner(error: _error),

            LayoutBuilder(
              builder: (context, constraints) {
                final paired = constraints.maxWidth > 420;
                final nameField = NeumorphField(
                  controller: _nameController,
                  label: 'Full Name',
                  hintText: 'Enter your full name',
                  prefixIcon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Enter your full name' : null,
                );
                final idField = NeumorphField(
                  controller: _studentIdController,
                  label: 'Student ID',
                  hintText: 'e.g. 2021-00001',
                  prefixIcon: Icons.badge_outlined,
                  textInputAction: TextInputAction.next,
                );
                if (paired) {
                  // Top-align: if only one field shows a validation message the
                  // other must not float downward.
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: nameField),
                      const SizedBox(width: 14),
                      Expanded(child: idField),
                    ],
                  );
                }
                return Column(
                  children: [
                    nameField,
                    const SizedBox(height: 16),
                    idField,
                  ],
                );
              },
            ),

            const SizedBox(height: 16),

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
            Consumer(
              builder: (context, ref, _) {
                final programsAsync = ref.watch(programsProvider);
                return programsAsync.when(
                  data: (programs) {
                    if (programs.isEmpty) {
                      return const Text('No programs available');
                    }
                    return NeumorphSelect<Program>(
                      label: 'Academic Program',
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

            LayoutBuilder(
              builder: (context, constraints) {
                final paired = constraints.maxWidth > 420;
                final passwordField = NeumorphField(
                  controller: _passwordController,
                  label: 'Password',
                  hintText: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) => (v == null || v.length < 4)
                      ? 'Min 4 characters'
                      : null,
                );
                final confirmField = NeumorphField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hintText: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  obscureText: true,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) => (v == null || v.length < 4)
                      ? 'Confirm password'
                      : null,
                );
                if (paired) {
                  return Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(child: passwordField),
                      const SizedBox(width: 14),
                      Expanded(child: confirmField),
                    ],
                  );
                }
                return Column(
                  children: [
                    passwordField,
                    const SizedBox(height: 16),
                    confirmField,
                  ],
                );
              },
            ),

            const SizedBox(height: 24),

            NeumorphButton(
              onPressed: _isLoading ? null : _register,
              label: 'Create Account',
              expand: true,
              loading: _isLoading,
            ),

            const SizedBox(height: 18),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text('Already have an account?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CScholarTextStyles.inter(13,
                          FontWeight.w400, CScholarColors.textMuted)),
                ),
                Flexible(
                  child: TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text('Sign In',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CScholarTextStyles.inter(13,
                            FontWeight.w700, CScholarColors.primaryGreen)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
