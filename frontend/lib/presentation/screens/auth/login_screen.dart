import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/common/auth_shell.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController(text: '');
  final _passwordController = TextEditingController();
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

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final auth = ref.read(authProvider.notifier);
      final ok = await auth.login(
        _emailController.text.trim(),
        _passwordController.text,
      );

      if (!mounted) return;
      setState(() => _isLoading = false);

      if (ok) {
        await Future.delayed(const Duration(milliseconds: 100));
        if (!mounted) return;
        final user = ref.read(currentUserProvider);
        if (user?.role == 'admin') {
          context.go('/admin/dashboard');
        } else if (user?.role == 'faculty') {
          context.go('/faculty/dashboard');
        } else {
          context.go('/student/dashboard');
        }
      } else {
        setState(() => _error = 'Invalid credentials. Please check your email and password.');
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = 'Error: ${e.toString()}';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return AuthShell(
      maxCardWidth: 460,
      child: Form(
        key: _formKey,
        // Tight rhythm: the form reads as one gesture, and the submit lands
        // at the clamp (160ms ≈ the 180ms PART 7 beat).
        child: StaggerColumn(
          pitch: MotionPitch.tight,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Welcome back',
              textAlign: TextAlign.center,
              style: CScholarTextStyles.poppins(
                  26, FontWeight.w800, CScholarColors.textPrimary),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in to access your saved studies and repository tools',
              textAlign: TextAlign.center,
              style: CScholarTextStyles.inter(
                  13.5, FontWeight.w400, CScholarColors.textMuted),
            ),
            const SizedBox(height: 20),

            AuthErrorBanner(error: _error),

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

            NeumorphField(
              controller: _passwordController,
              label: 'Password',
              hintText: '••••••••',
              prefixIcon: Icons.lock_outline,
              obscureText: _obscure,
              textInputAction: TextInputAction.done,
              autofillHints: const [AutofillHints.password],
              onSubmitted: (_) => _login(),
              validator: (v) => (v == null || v.length < 4)
                  ? 'Password must be at least 4 characters'
                  : null,
              suffixIcon: IconButton(
                tooltip: _obscure ? 'Show password' : 'Hide password',
                // Outline <-> filled morphs instead of hard-swapping (the
                // ad-hoc switcher this replaces is now one shared primitive).
                icon: MorphIcon(
                  icon: Icons.visibility_outlined,
                  selectedIcon: Icons.visibility_off_outlined,
                  selected: _obscure,
                  color: CScholarColors.textMuted,
                  selectedColor: CScholarColors.textMuted,
                  size: 18,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),

            const SizedBox(height: 14),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 20,
                        height: 20,
                        // control-exempt: Task C.1 — "Remember me" is still a
                        // stock Checkbox; decide NeumorphToggle vs exemption.
                        child: Checkbox(
                          value: _rememberMe,
                          onChanged: (v) =>
                              setState(() => _rememberMe = v ?? true),
                          activeColor: CScholarColors.primaryGreen,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(4)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: Text('Remember me',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: CScholarTextStyles.inter(12,
                                FontWeight.w400, CScholarColors.textMuted)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: TextButton(
                    onPressed: () => showClayDialog(
                      context: context,
                      builder: (ctx) => GlassDialog(
                        title: const Text('Forgot password?'),
                        content: const Text(
                            'Password resets are handled by your administrator. '
                            'Visit the CEIT office or message your admin with your username and email.'),
                        actions: [
                          TextButton(
                              onPressed: () => Navigator.pop(ctx),
                              child: const Text('Got it')),
                        ],
                      ),
                    ),
                    child: Text('Forgot password?',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CScholarTextStyles.inter(12, FontWeight.w600,
                            CScholarColors.primaryGreen)),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            NeumorphButton(
              onPressed: _isLoading ? null : _login,
              label: 'Sign In',
              expand: true,
              loading: _isLoading,
            ),

            const SizedBox(height: 20),

            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Flexible(
                  child: Text("Don't have an account?",
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CScholarTextStyles.inter(13,
                          FontWeight.w400, CScholarColors.textMuted)),
                ),
                Flexible(
                  child: TextButton(
                    onPressed: () => context.go('/register'),
                    child: Text('Register here',
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
