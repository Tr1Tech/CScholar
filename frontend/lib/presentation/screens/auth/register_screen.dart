import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:frontend/core/config.dart';
import 'package:frontend/core/constants/cscholar_constants.dart';
import 'package:frontend/core/material/cscholar_mobile_tokens.dart';
import 'package:frontend/core/material/cscholar_palette.dart';
import 'package:frontend/presentation/widgets/material/neumorph_field.dart';
import 'package:frontend/presentation/widgets/material/neumorph_controls.dart';
import 'package:frontend/presentation/widgets/material/neumorph_select.dart';
import 'package:frontend/presentation/widgets/material/clay_progress.dart';
import 'package:frontend/presentation/widgets/material/clay_objects.dart';
import 'package:frontend/presentation/widgets/material/glass_panel.dart';
import 'package:frontend/core/providers/providers.dart';
import 'package:frontend/core/utils/user_facing_error.dart';
import 'package:frontend/models/thesis.dart';
import 'package:frontend/services/api_service.dart';
import 'package:frontend/presentation/widgets/common/auth_shell.dart';
import 'package:frontend/presentation/widgets/common/motion.dart';
import 'package:frontend/presentation/widgets/mobile/mobile_auth.dart';

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

  /// Mobile registration is two short steps instead of one long card.
  int _step = 0;
  final _stepOneKey = GlobalKey<FormState>();
  final _stepTwoKey = GlobalKey<FormState>();
  final _scrollController = ScrollController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _studentIdController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    await _submit();
  }

  /// The network half of registration, shared by the web form and both
  /// mobile steps so the two layouts can never drift apart.
  Future<void> _submit() async {
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
    try {
      await auth.register(user);
      if (!mounted) return;
      setState(() => _isLoading = false);
      _registrationSucceeded(_emailController.text.trim());
    } catch (e) {
      if (!mounted) return;
      final conflict = e is ApiException && e.statusCode == 409;
      setState(() {
        _isLoading = false;
        _error = conflict
            ? 'An account with that email or username already exists. Sign in instead.'
            : userFacingError(
                e,
                fallback: "We couldn't create your account. Check your connection and try again.",
              );
      });
    }
  }

  String _successCopy(String email) => email.isEmpty
      ? 'Your account is ready. Sign in to start saving and building your library.'
      : 'Your account is ready. Sign in as $email to start saving and building your library.';

  void _goToLogin(String email) {
    if (!mounted) return;
    context.go(
      Uri(
        path: '/login',
        queryParameters: email.isEmpty ? null : {'email': email},
      ).toString(),
    );
  }

  /// Success confirmation — the one acknowledgement of a created account.
  /// Web gets the glass dialog; phones get a bottom sheet in the mobile
  /// system. Either way, dismissing the panel (back/Escape) still lands on
  /// sign-in, because that is the only next step.
  Future<void> _registrationSucceeded(String email) async {
    final mobile = MediaQuery.sizeOf(context).width <= AppConfig.mobileMaxWidth;
    if (mobile) {
      await _showMobileSuccessSheet(email);
    } else {
      await showClayDialog<void>(
        context: context,
        barrierDismissible: false,
        barrierLabel: 'Account created',
        builder: (ctx) => GlassDialog(
          title: const Text(
            'Account created',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Green gel tile, white check: the system's success identity.
              const ClayIconTile(icon: Icons.check_rounded, size: 56),
              const SizedBox(height: 16),
              Text(
                _successCopy(email),
                textAlign: TextAlign.center,
                style: CScholarTextStyles.body(
                  13.5,
                  FontWeight.w400,
                  CScholarColors.textMuted,
                ),
              ),
            ],
          ),
          actions: [
            NeumorphButton(
              label: 'Continue to Sign In',
              onPressed: () => Navigator.pop(ctx),
            ),
          ],
        ),
      );
    }
    // Reached after the CTA pops the panel AND after a back/Escape dismissal.
    _goToLogin(email);
  }

  @override
  Widget build(BuildContext context) {
    // At phone widths registration becomes two short steps; the desktop glass
    // card keeps its single-column form.
    if (MediaQuery.sizeOf(context).width <= AppConfig.mobileMaxWidth) {
      return _mobileBody(context);
    }
    return _desktopBody(context);
  }

  Widget _desktopBody(BuildContext context) {
    return AuthShell(
      maxCardWidth: 560,
      child: Form(
        key: _formKey,
        // Tight rhythm, same as login: one gesture, submit at the clamp.
        child: StaggerColumn(
          pitch: MotionPitch.tight,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Create your account',
              textAlign: TextAlign.center,
              style: CScholarTextStyles.heading(
                26,
                FontWeight.w800,
                CScholarColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Register using your CSU institutional credentials',
              textAlign: TextAlign.center,
              style: CScholarTextStyles.body(
                13.5,
                FontWeight.w400,
                CScholarColors.textMuted,
              ),
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
                  children: [nameField, const SizedBox(height: 16), idField],
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
                      return Text(
                        'No academic programs are available yet. '
                        'Contact the CEIT office to have yours added.',
                        style: CScholarTextStyles.body(
                          12,
                          FontWeight.w400,
                          CScholarColors.textMuted,
                        ),
                      );
                    }
                    return NeumorphSelect<Program>(
                      label: 'Academic Program',
                      initialValue:
                          _selectedProgram != null &&
                              programs.any((p) => p.id == _selectedProgram!.id)
                          ? programs.firstWhere(
                              (p) => p.id == _selectedProgram!.id,
                            )
                          : null,
                      prefixIcon: Icons.school_outlined,
                      hintText: 'Select your academic program',
                      items: programs
                          .map(
                            (p) => DropdownMenuItem(
                              value: p,
                              child: Text('${p.name} (${p.code})'),
                            ),
                          )
                          .toList(),
                      onChanged: (v) => setState(() => _selectedProgram = v),
                      validator: (v) =>
                          v == null ? 'Select your academic program' : null,
                    );
                  },
                  loading: () => const ClayLoader(height: 8),
                  error: (err, _) => Row(
                    children: [
                      Expanded(
                        child: Text(
                          "We couldn't load the academic programs.",
                          style: CScholarTextStyles.body(
                            12,
                            FontWeight.w400,
                            CScholarColors.error,
                          ),
                        ),
                      ),
                      TextButton(
                        onPressed: () => ref.invalidate(programsProvider),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
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
                  obscureText: _obscurePassword,
                  autofillHints: const [AutofillHints.newPassword],
                  // The register route rejects anything under 6; validating the
                  // same floor here keeps the user out of a pointless round-trip.
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Password must be at least 6 characters'
                      : null,
                  suffixIcon: IconButton(
                    tooltip: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: CScholarTapTarget.minimum * 0.42,
                      color: CScholarColors.textMuted,
                    ),
                  ),
                );
                final confirmField = NeumorphField(
                  controller: _confirmPasswordController,
                  label: 'Confirm Password',
                  hintText: '••••••••',
                  prefixIcon: Icons.lock_outline,
                  obscureText: _obscureConfirm,
                  autofillHints: const [AutofillHints.newPassword],
                  validator: (v) => (v == null || v.length < 6)
                      ? 'Confirm your password'
                      : null,
                  suffixIcon: IconButton(
                    tooltip: _obscureConfirm
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: CScholarTapTarget.minimum * 0.42,
                      color: CScholarColors.textMuted,
                    ),
                  ),
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
                  child: Text(
                    'Already have an account?',
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
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Sign In',
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

  // --------------------------------------------------------------- mobile
  //
  // Two steps, one screen: the controllers live here, so stepping back keeps
  // everything typed, while each step validates only its own fields before
  // letting the user move on.

  void _nextStep() {
    final valid = _stepOneKey.currentState?.validate() ?? false;
    if (!valid) return;
    selectionHaptic();
    setState(() {
      _step = 1;
      // A stale submit error belongs to the previous attempt, not this step.
      _error = null;
    });
    _scrollToTop();
  }

  void _previousStep() {
    if (_step == 0) {
      context.go('/login');
      return;
    }
    selectionHaptic();
    setState(() {
      _step -= 1;
      _error = null;
    });
    _scrollToTop();
  }

  void _scrollToTop() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) _scrollController.jumpTo(0);
    });
  }

  Future<void> _submitMobile() async {
    final valid = _stepTwoKey.currentState?.validate() ?? false;
    if (!valid) return;
    await _submit();
  }

  Widget _mobileBody(BuildContext context) {
    // Watched at the screen (not inside step 1) so switching steps does not
    // dispose this autoDispose provider and refetch the list on the way back.
    final programs = ref.watch(programsProvider);

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (didPop) return;
        _previousStep();
      },
      child: MobileAuthShell(
        title: 'Create account',
        showBack: true,
        onBack: _previousStep,
        scrollController: _scrollController,
        footer: MobileAuthFooter(
          leading: 'Already have an account?',
          action: 'Sign in',
          onAction: () => context.go('/login'),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            MobileAuthStepProgress(step: _step),
            AnimatedSize(
              duration: CScholarDurations.normal,
              curve: CScholarCurves.standard,
              alignment: Alignment.topCenter,
              child: AnimatedSwitcher(
                duration: CScholarDurations.normal,
                switchInCurve: CScholarCurves.entrance,
                switchOutCurve: CScholarCurves.entrance,
                transitionBuilder: (child, animation) => FadeTransition(
                  opacity: animation,
                  child: SlideTransition(
                    position: Tween<Offset>(
                      begin: const Offset(0, 0.03),
                      end: Offset.zero,
                    ).animate(animation),
                    child: child,
                  ),
                ),
                child: _step == 0
                    ? _mobileStepOne(context, programs)
                    : _mobileStepTwo(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _mobileStepOne(
    BuildContext context,
    AsyncValue<List<Program>> programs,
  ) {
    final t = CScholarMobileTheme.of(context);

    return Column(
      key: const ValueKey<int>(0),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('YOUR DETAILS', style: t.eyebrow),
        const SizedBox(height: 7),
        Text(
          'Tell us who you are.',
          style: t.manrope(
            28,
            FontWeight.w700,
            t.ink,
            height: 1.12,
            letterSpacing: -0.45,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          'Your name and student number, as they appear in CEIT records.',
          style: t.bodyMuted,
        ),
        const SizedBox(height: 18),
        Form(
          key: _stepOneKey,
          child: MobileAuthCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                MobileAuthField(
                  controller: _nameController,
                  label: 'Full name',
                  hint: 'Enter your full name',
                  icon: Icons.person_outline,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.name],
                  validator: (v) => (v == null || v.trim().isEmpty)
                      ? 'Enter your full name'
                      : null,
                ),
                const SizedBox(height: 16),
                MobileAuthField(
                  controller: _studentIdController,
                  label: 'Student ID',
                  hint: 'e.g. 2021-00001',
                  icon: Icons.badge_outlined,
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                programs.when(
                  data: (list) => list.isEmpty
                      ? Text('No programs available', style: t.bodyMuted)
                      : MobileAuthPicker<Program>(
                          label: 'Degree program',
                          hint: 'Select your degree program',
                          value: _selectedProgram,
                          valueLabel: _selectedProgram?.name,
                          icon: Icons.school_outlined,
                          pick: () => _pickProgram(context, list),
                          onChanged: (p) =>
                              setState(() => _selectedProgram = p),
                          validator: (v) =>
                              v == null ? 'Select your degree program' : null,
                        ),
                  loading: () =>
                      _programPlaceholder(t, 'Loading programs…', busy: true),
                  error: (err, _) => Text(
                    'Could not load programs. Check your connection and try '
                    'again.',
                    style: t.bodyMuted,
                  ),
                ),
                const SizedBox(height: 18),
                MobileAuthButton(
                  label: 'Continue',
                  trailing: Icons.chevron_right,
                  onPressed: _nextStep,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _mobileStepTwo(BuildContext context) {
    final t = CScholarMobileTheme.of(context);

    return Column(
      key: const ValueKey<int>(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text('SECURE YOUR ACCOUNT', style: t.eyebrow),
        const SizedBox(height: 7),
        Text(
          'Set your sign-in.',
          style: t.manrope(
            28,
            FontWeight.w700,
            t.ink,
            height: 1.12,
            letterSpacing: -0.45,
          ),
        ),
        const SizedBox(height: 7),
        Text(
          "Use your CSU email — it's what you'll sign in with.",
          style: t.bodyMuted,
        ),
        if ((_error ?? '').isNotEmpty) ...[
          const SizedBox(height: 16),
          MobileAuthError(message: _error!),
        ],
        const SizedBox(height: 18),
        Form(
          key: _stepTwoKey,
          child: MobileAuthCard(
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
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Please enter a valid institutional email'
                      : null,
                ),
                const SizedBox(height: 16),
                MobileAuthField(
                  controller: _passwordController,
                  label: 'Password',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscureText: _obscurePassword,
                  textInputAction: TextInputAction.next,
                  autofillHints: const [AutofillHints.newPassword],
                  // Same floor as the register route: 6 characters.
                  validator: (v) =>
                      (v == null || v.length < 6) ? 'Min 6 characters' : null,
                  suffix: MobileAuthSuffixButton(
                    icon: _obscurePassword
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    semanticLabel: _obscurePassword
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 16),
                MobileAuthField(
                  controller: _confirmPasswordController,
                  label: 'Confirm password',
                  hint: '••••••••',
                  icon: Icons.lock_outline,
                  obscureText: _obscureConfirm,
                  textInputAction: TextInputAction.done,
                  autofillHints: const [AutofillHints.newPassword],
                  onSubmitted: (_) => _submitMobile(),
                  validator: (v) {
                    if (v == null || v.length < 6) return 'Confirm password';
                    if (v != _passwordController.text) {
                      return 'Passwords do not match';
                    }
                    return null;
                  },
                  suffix: MobileAuthSuffixButton(
                    icon: _obscureConfirm
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    semanticLabel: _obscureConfirm
                        ? 'Show password'
                        : 'Hide password',
                    onPressed: () =>
                        setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 12),
                _passwordChips(t),
                const SizedBox(height: 18),
                Row(
                  children: [
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 120),
                      child: MobileAuthGhostButton(
                        label: 'Back',
                        onPressed: _isLoading ? null : _previousStep,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: MobileAuthButton(
                        label: 'Create account',
                        loading: _isLoading,
                        onPressed: _isLoading ? null : _submitMobile,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }

  /// Requirement chips that fill in as the two password fields agree.
  Widget _passwordChips(CScholarMobileTheme t) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        _passwordController,
        _confirmPasswordController,
      ]),
      builder: (context, _) {
        final longEnough = _passwordController.text.length >= 6;
        final matches =
            _confirmPasswordController.text.isNotEmpty &&
            _passwordController.text == _confirmPasswordController.text;
        return Wrap(
          spacing: 6,
          runSpacing: 6,
          children: [
            _chip(t, '6+ characters', longEnough),
            _chip(t, 'matches', matches),
          ],
        );
      },
    );
  }

  Widget _chip(CScholarMobileTheme t, String label, bool met) {
    return AnimatedContainer(
      duration: CScholarDurations.fast,
      curve: CScholarCurves.standard,
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: met ? t.green : t.mint,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (met) ...[
            Icon(Icons.check, size: 10, color: t.paper),
            const SizedBox(width: 3),
          ],
          Text(
            label,
            style: t.dmSans(8.5, FontWeight.w800, met ? t.paper : t.green),
          ),
        ],
      ),
    );
  }

  /// Placeholder well while GET /api/programs is in flight.
  Widget _programPlaceholder(
    CScholarMobileTheme t,
    String message, {
    bool busy = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          'DEGREE PROGRAM',
          style: t.dmSans(
            10,
            FontWeight.w800,
            t.green2,
            height: 1.2,
            letterSpacing: 1.15,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(minHeight: 50),
          padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 12),
          decoration: BoxDecoration(
            color: t.surfaceSoft,
            borderRadius: BorderRadius.circular(15),
          ),
          child: Row(
            children: [
              Icon(Icons.school_outlined, size: 18, color: t.muted),
              const SizedBox(width: 10),
              if (busy) ...[
                SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(t.green),
                  ),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Text(
                  message,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: t.dmSans(13, FontWeight.w400, t.muted),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<Program?> _pickProgram(BuildContext context, List<Program> programs) {
    final t = CScholarMobileTheme.of(context);
    return showModalBottomSheet<Program>(
      context: context,
      isScrollControlled: true,
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
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxHeight: MediaQuery.sizeOf(ctx).height * 0.72,
            ),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 10, 20, 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _sheetHandle(sheet),
                  const SizedBox(height: 18),
                  Text(
                    'Degree program',
                    style: sheet.manrope(18, FontWeight.w700, sheet.ink),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose the program you are enrolled in.',
                    style: sheet.bodyMuted,
                  ),
                  const SizedBox(height: 14),
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.only(bottom: 4),
                      itemCount: programs.length,
                      // A real gap between cards, so each program reads as its
                      // own object instead of one long list.
                      separatorBuilder: (_, _) => const SizedBox(height: 10),
                      itemBuilder: (_, index) {
                        final program = programs[index];
                        final selected = program.id == _selectedProgram?.id;
                        return GestureDetector(
                          onTap: () => Navigator.pop(ctx, program),
                          child: AnimatedContainer(
                            duration: CScholarDurations.fast,
                            curve: CScholarCurves.standard,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 15,
                              vertical: 14,
                            ),
                            decoration: BoxDecoration(
                              color: selected ? sheet.mint : sheet.surfaceSoft,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: selected
                                    ? sheet.green.withValues(alpha: 0.45)
                                    : sheet.line,
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        program.name,
                                        style: sheet.dmSans(
                                          13.5,
                                          FontWeight.w600,
                                          sheet.ink,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        program.code,
                                        style: sheet.dmSans(
                                          11,
                                          FontWeight.w400,
                                          sheet.muted,
                                          letterSpacing: 0.4,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                if (selected) ...[
                                  const SizedBox(width: 10),
                                  Icon(
                                    Icons.check_circle,
                                    size: 18,
                                    color: sheet.green,
                                  ),
                                ],
                              ],
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _showMobileSuccessSheet(String email) async {
    final t = CScholarMobileTheme.of(context);
    await showModalBottomSheet<void>(
      context: context,
      isDismissible: false,
      enableDrag: false,
      isScrollControlled: true,
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
                _sheetHandle(sheet),
                const SizedBox(height: 18),
                Center(
                  child: Container(
                    // tile-exempt: success glyph, not an icon tile.
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: sheet.mint,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      size: 28,
                      color: sheet.green,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Account created',
                  textAlign: TextAlign.center,
                  style: sheet.manrope(18, FontWeight.w700, sheet.ink),
                ),
                const SizedBox(height: 8),
                Text(
                  _successCopy(email),
                  textAlign: TextAlign.center,
                  style: sheet.bodyMuted,
                ),
                const SizedBox(height: 20),
                MobileAuthButton(
                  label: 'Continue to sign in',
                  onPressed: () => Navigator.pop(ctx),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _sheetHandle(CScholarMobileTheme t) {
    return Center(
      child: Container(
        width: 42,
        height: 4,
        decoration: BoxDecoration(
          color: t.line,
          borderRadius: BorderRadius.circular(4),
        ),
      ),
    );
  }
}
