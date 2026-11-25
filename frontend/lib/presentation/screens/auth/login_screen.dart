import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/config.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/cscholar_palette.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/core/router/app_router.dart';
import 'package:frontend/core/utils/user_facing_error.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';
import 'package:frontend/presentation/widgets/common/auth_shell.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_auth.dart';

class LoginScreen extends ConsumerStatefulWidget {
  /// Set when the router bounces a non-student off the mobile gate
  /// (`/login?reason=use-web`): the screen signs the session out and
  /// shows the student-only notice.
  final String? reason;

  /// Prefills the email field — used by the register success panel so a
  /// freshly created account only has to type its password (`/login?email=`).
  final String? initialEmail;

  /// Where an unauthenticated deep link was trying to go. After a successful
  /// sign-in the user lands there instead of a fixed dashboard (NAV-5).
  final String? initialFrom;

  const LoginScreen({
    super.key,
    this.reason,
    this.initialEmail,
    this.initialFrom,
  });

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
  void initState() {
    super.initState();
    // Seed from the register hand-off before the first frame, so the field
    // never flashes empty and then fills itself.
    final seeded = widget.initialEmail?.trim();
    if (seeded != null && seeded.isNotEmpty) {
      _emailController.text = seeded;
      _emailController.selection = TextSelection.collapsed(
        offset: seeded.length,
      );
    }
    if (widget.reason == 'use-web') {
      final user = ref.read(currentUserProvider);
      if (user?.role == 'admin' || user?.role == 'faculty') {
        ref.read(authProvider.notifier).logout();
        _error = mobileOnlyNotice;
      }
    }
  }

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
        // Native mobile is student-only: sign a fresh non-student sign-in
        // straight back out instead of routing to a dashboard that the
        // guard would only bounce. (Restored sessions take the init path.)
        if (isMobileApp && user != null && user.role != 'student') {
          await auth.logout();
          if (!mounted) return;
          setState(() => _error = mobileOnlyNotice);
          return;
        }
        if (user?.role == 'admin') {
          context.go(_destinationFor('admin'));
        } else if (user?.role == 'faculty') {
          context.go(_destinationFor('faculty'));
        } else {
          context.go(_destinationFor('student'));
        }
      } else {
        setState(
          () => _error =
              'Invalid credentials. Please check your email and password.',
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = userFacingError(
          e,
          fallback: "We couldn't reach CScholar. Check your connection and try again.",
        );
      });
    }
  }

  String? _validateEmail(String? v) => (v == null || !v.contains('@'))
      ? 'Please enter a valid institutional email'
      : null;

  /// Restores the deep link the router captured, when it is safe to do so.
  /// Only same-app absolute paths are accepted — never a scheme or `//host`.
  String _destinationFor(String role) {
    final from = widget.initialFrom?.trim();
    if (from != null &&
        from.startsWith('/') &&
        !from.startsWith('//') &&
        !from.startsWith('/login') &&
        !from.startsWith('/register')) {
      return from;
    }
    if (role == 'admin') return '/admin/dashboard';
    if (role == 'faculty') return '/faculty/dashboard';
    return '/student/dashboard';
  }

  String? _validatePassword(String? v) => (v == null || v.length < 6)
      ? 'Password must be at least 6 characters'
      : null;

  @override
  Widget build(BuildContext context) {
    // At phone widths the mobile system owns the screen: paper, mobile header,
    // surface card, green pill. The glass slab is web chrome.
    if (MediaQuery.sizeOf(context).width <= AppConfig.mobileMaxWidth) {
      return _mobileBody(context);
    }
    return _webBody(context);
  }

  Widget _webBody(BuildContext context) {
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
              style: CScholarTextStyles.heading(
                26,
                FontWeight.w800,
                CScholarColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sign in to access your saved studies and repository tools',
              textAlign: TextAlign.center,
              style: CScholarTextStyles.body(
                13.5,
                FontWeight.w400,
                CScholarColors.textMuted,
              ),
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
              validator: _validateEmail,
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
              validator: _validatePassword,
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
                  child: Semantics(
                    label: 'Remember me',
                    toggled: _rememberMe,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(CScholarRadius.full),
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 4,
                          vertical: 8,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            NeumorphToggle(
                              value: _rememberMe,
                              onChanged: (v) => setState(() => _rememberMe = v),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'Remember me',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: CScholarTextStyles.body(
                                  12,
                                  FontWeight.w500,
                                  CScholarColors.textMuted,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
                          'Visit the CEIT office or message your admin with your username and email.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(ctx),
                            child: const Text('Got it'),
                          ),
                        ],
                      ),
                    ),
                    child: Text(
                      'Forgot password?',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CScholarTextStyles.body(
                        12,
                        FontWeight.w600,
                        CScholarColors.primaryGreen,
                      ),
                    ),
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
                  child: Text(
                    "Don't have an account?",
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CScholarTextStyles.body(
                      13,
                      FontWeight.w400,
                      CScholarColors.textMuted,
                    ),
                  ),
                ),
                Flexible(
                  child: TextButton(
                    onPressed: () => context.go('/register'),
                    child: Text(
                      'Register here',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: CScholarTextStyles.body(
                        13,
                        FontWeight.w700,
                        CScholarColors.primaryGreen,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Phone layout: paper, mobile header, one surface card.
  Widget _mobileBody(BuildContext context) {
    final t = CScholarMobileTheme.of(context);

    return MobileAuthShell(
      footer: MobileAuthFooter(
        leading: 'New here?',
        action: 'Create an account',
        onAction: () => context.go('/register'),
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 9),
            Text('CEIT THESIS REPOSITORY', style: t.eyebrow),
            const SizedBox(height: 7),
            Text(
              'Welcome back.',
              style: t.manrope(
                31,
                FontWeight.w700,
                t.ink,
                height: 1.12,
                letterSpacing: -0.45,
              ),
            ),
            const SizedBox(height: 7),
            Text(
              'Sign in to pick up your saved studies and repository tools.',
              style: t.bodyMuted,
            ),
            if ((_error ?? '').isNotEmpty) ...[
              const SizedBox(height: 16),
              MobileAuthError(message: _error!),
            ],
            const SizedBox(height: 18),
            MobileAuthCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  MobileAuthField(
                    controller: _emailController,
                    label: 'Institutional email',
                    hint: 'you@example.com',
                    icon: Icons.mail_outline,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    autofillHints: const [AutofillHints.email],
                    validator: _validateEmail,
                  ),
                  const SizedBox(height: 15),
                  MobileAuthField(
                    controller: _passwordController,
                    label: 'Password',
                    hint: '••••••••',
                    icon: Icons.lock_outline,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    onSubmitted: (_) => _login(),
                    validator: _validatePassword,
                    suffix: MobileAuthSuffixButton(
                      icon: _obscure
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      semanticLabel: _obscure
                          ? 'Show password'
                          : 'Hide password',
                      onPressed: () => setState(() => _obscure = !_obscure),
                    ),
                  ),
                  const SizedBox(height: 15),
                  Row(
                    children: [
                      MobileAuthSwitch(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Remember me',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: t.dmSans(12, FontWeight.w500, t.muted),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Flexible(
                        child: TextButton(
                          onPressed: () => _showForgotPasswordSheet(context),
                          style: TextButton.styleFrom(
                            minimumSize: Size.zero,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 4,
                              vertical: 6,
                            ),
                            tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                          child: Text(
                            'Forgot password?',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: t.dmSans(12, FontWeight.w600, t.green),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  MobileAuthButton(
                    label: 'Sign in',
                    loading: _isLoading,
                    onPressed: _isLoading ? null : _login,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showForgotPasswordSheet(BuildContext context) {
    final t = CScholarMobileTheme.of(context);
    return showModalBottomSheet<void>(
      context: context,
      backgroundColor: t.surface,
      barrierColor: CScholarPalette.active.scrim,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(CScholarMobileRadius.sheet),
        ),
      ),
      builder: (ctx) {
        final sheet = CScholarMobileTheme.of(ctx);
        return SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: sheet.line,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Forgot password?',
                  style: sheet.manrope(18, FontWeight.w700, sheet.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  'Password resets are handled by your administrator. '
                  'Visit the CEIT office or message your admin with your '
                  'username and email.',
                  style: sheet.bodyMuted,
                ),
                const SizedBox(height: 20),
                MobileAuthButton(
                  label: 'Got it',
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
