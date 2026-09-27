import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/material_tokens.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/presentation/widgets/common/cscholar_logo.dart';
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
    final size = MediaQuery.of(context).size;
    final isDesktop = size.width > 860;

    return Scaffold(
      // The auth card is a clay panel on the shared canvas — the old
      // #F3F4F6 cool grey belonged to no hue family in this palette and made
      // login look like a different product from the rest of the app.
      backgroundColor: CScholarMaterial.canvas,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 980),
            decoration: BoxDecoration(
              color: CScholarMaterial.clay,
              borderRadius: BorderRadius.circular(CScholarRadius.xxl),
              boxShadow: CScholarMaterial.clayDrop(depth: 1.2),
              // No drawn outline: at 980px the clay slab and its shadow are the
              // boundary, and a rim this long just reads as a heavy frame.
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
                  CScholarColors.heroText,
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
                Flexible(
                  child: Text(
                    'CSU CEIT Campus Portal',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CScholarTextStyles.inter(
                        11, FontWeight.w600, CScholarColors.heroText),
                  ),
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
        // tile-exempt: a 28px disc on the DARK hero panel. ClayIconTile is a
        // moulded clay/gel SQUARE — on the deep-green hero it would read as a
        // stray light chip, so this one keeps its white-alpha disc.
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
                Flexible(
                  child: Text(
                    'Welcome Back',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: CScholarTextStyles.poppins(26, FontWeight.w800, CScholarColors.textPrimary),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: TextButton(
                    onPressed: () => context.go('/'),
                    child: Text('Home',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CScholarTextStyles.inter(12, FontWeight.w600, CScholarColors.textSecondary)),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Sign in to access your saved studies and repository tools',
              style: CScholarTextStyles.inter(13.5, FontWeight.w400, CScholarColors.textSecondary),
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

            // Password Field
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
                icon: Icon(
                  _obscure
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 18,
                  color: CScholarColors.textMuted,
                ),
                onPressed: () => setState(() => _obscure = !_obscure),
              ),
            ),

            const SizedBox(height: 14),

            // Remember me & Forgot password
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
                                FontWeight.w400, CScholarColors.textSecondary)),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: TextButton(
                    onPressed: () => showDialog(
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

            // Sign In Button
            NeumorphButton(
              onPressed: _isLoading ? null : _login,
              label: 'Sign In',
              expand: true,
              loading: _isLoading,
            ),

            const SizedBox(height: 20),

            // Register Link
            Center(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text("Don't have an account?",
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: CScholarTextStyles.inter(13,
                            FontWeight.w400, CScholarColors.textSecondary)),
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
            ),
          ],
        ),
      ),
    );
  }

}
