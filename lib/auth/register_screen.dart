import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../providers/auth_provider.dart";
import "../utils/app_routes.dart";
import "../utils/password_validator.dart";
import "../theme/app_colors.dart";
import "../theme/app_typography.dart";
import "../widgets/app_logo.dart";
import "../widgets/app_background.dart";
import "../widgets/bouncy_tap.dart";
import "../l10n/app_localizations.dart";

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  final _firstFocus = FocusNode();
  final _lastFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  final _confirmPasswordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void initState() {
    super.initState();
    _firstFocus.addListener(() => setState(() {}));
    _lastFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
    _confirmPasswordFocus.addListener(() => setState(() {}));

    // Listeners for realtime checklist and matching updates
    _firstNameController.addListener(() => setState(() {}));
    _lastNameController.addListener(() => setState(() {}));
    _emailController.addListener(() => setState(() {}));
    _passwordController.addListener(() => setState(() {}));
    _confirmPasswordController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _firstFocus.dispose();
    _lastFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignUp() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (authProvider.errorMessage != null && authProvider.errorMessage!.isNotEmpty) {
      // Chỉ hiện SnackBar khi có lỗi thật sự từ hệ thống, không hiện khi người dùng tự tắt popup
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleEmailSignUp() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    // Do NOT silently trim password: whitespace policy must be verified as-is
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.pleaseEnterFullName),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final validation = PasswordValidator.validate(password);
    if (!validation.isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(validation.errors.first),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.passwordsDoNotMatch),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signUp(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );

    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(context.l10n.registerSuccess),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? context.l10n.registerFailure),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  Widget _buildFieldLabel(String label) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.only(left: 4, bottom: 6),
        child: Text(
          label,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.ink,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  Widget _buildChecklistItem(String title, bool isMet) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isMet ? AppColors.success : Colors.transparent,
              border: Border.all(
                color: isMet ? AppColors.success : AppColors.inkSoft.withValues(alpha: 0.5),
                width: 1.5,
              ),
            ),
            child: isMet
                ? const Icon(
                    Icons.check,
                    size: 12,
                    color: Colors.white,
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                color: isMet ? AppColors.success : AppColors.inkSoft,
                fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordChecklist(PasswordValidationResult validation) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(top: 10, bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: validation.isValid
              ? AppColors.success.withValues(alpha: 0.3)
              : AppColors.borderLight,
        ),
        boxShadow: AppColors.shadowSoft,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildChecklistItem(context.l10n.ruleLength, validation.hasLength),
          _buildChecklistItem(context.l10n.ruleUppercase, validation.hasUppercase),
          _buildChecklistItem(context.l10n.ruleLowercase, validation.hasLowercase),
          _buildChecklistItem(context.l10n.ruleDigit, validation.hasDigit),
          _buildChecklistItem(context.l10n.ruleSpecial, validation.hasSpecialChar),
          _buildChecklistItem(context.l10n.ruleNoWhitespace, validation.hasNoWhitespace),
          _buildChecklistItem(context.l10n.ruleNotCommon, validation.isNotCommon),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;
    final passwordValidation = PasswordValidator.validate(password);
    final isPasswordMatch = password.isNotEmpty && password == confirmPassword;

    final hasNames = _firstNameController.text.trim().isNotEmpty &&
        _lastNameController.text.trim().isNotEmpty;
    final hasEmail = _emailController.text.trim().isNotEmpty;

    // Register button is enabled ONLY when all rules + matching + required fields pass
    final isFormValid = passwordValidation.isValid &&
        isPasswordMatch &&
        hasNames &&
        hasEmail;

    return Scaffold(
      backgroundColor: AppColors.cream,
      body: AppBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              physics: const BouncingScrollPhysics(),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 20),

                  // ── Logo ──────────────────────────────────────────────────
                  const AppLogo(size: 60),
                  const SizedBox(height: 16),

                  Text(
                    context.l10n.registerTitle,
                    style: AppTypography.headlineLarge.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    context.l10n.registerSubtitle,
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.inkSoft),
                  ),

                  const SizedBox(height: 28),

                  // ── Google Sign Up Button ─────────────────────────────────
                  BouncyTap(
                    onTap: isLoading ? null : _handleGoogleSignUp,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.border),
                        boxShadow: AppColors.shadowSoft,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGoogleIcon(),
                          const SizedBox(width: 12),
                          Text(
                            context.l10n.continueWithGoogle,
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Divider ───────────────────────────────────────────────
                  Row(
                    children: [
                      const Expanded(child: Divider(color: AppColors.divider)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          context.l10n.orDivider,
                          style: AppTypography.bodySmall.copyWith(color: AppColors.inkSoft),
                        ),
                      ),
                      const Expanded(child: Divider(color: AppColors.divider)),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── First Name & Last Name ────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          controller: _firstNameController,
                          focusNode: _firstFocus,
                          hintText: context.l10n.firstNameLabel,
                          icon: Icons.person_outline_rounded,
                          enabled: !isLoading,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildInputField(
                          controller: _lastNameController,
                          focusNode: _lastFocus,
                          hintText: context.l10n.lastNameLabel,
                          icon: Icons.badge_outlined,
                          enabled: !isLoading,
                          textCapitalization: TextCapitalization.words,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  // ── Email ─────────────────────────────────────────────────
                  _buildInputField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    hintText: context.l10n.emailLabel,
                    icon: Icons.email_outlined,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                  ),
                  const SizedBox(height: 14),

                  // ── Password Field with Label ─────────────────────────────
                  _buildFieldLabel(context.l10n.passwordLabel),
                  _buildInputField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    hintText: context.l10n.enterPassword,
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    enabled: !isLoading,
                    suffixIcon: BouncyTap(
                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),

                  // ── Realtime Checklist 7 Rules ────────────────────────────
                  if (_passwordFocus.hasFocus || password.isNotEmpty)
                    _buildPasswordChecklist(passwordValidation),

                  const SizedBox(height: 14),

                  // ── Confirm Password Field with Label ─────────────────────
                  _buildFieldLabel(context.l10n.confirmPasswordLabel),
                  _buildInputField(
                    controller: _confirmPasswordController,
                    focusNode: _confirmPasswordFocus,
                    hintText: context.l10n.enterConfirmPassword,
                    icon: Icons.lock_reset_rounded,
                    obscureText: _obscureConfirmPassword,
                    enabled: !isLoading,
                    suffixIcon: BouncyTap(
                      onTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      child: Icon(
                        _obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),

                  // ── Password Confirmation Status Text ─────────────────────
                  if (confirmPassword.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8, left: 6),
                      child: Row(
                        children: [
                          Icon(
                            isPasswordMatch ? Icons.check_circle_rounded : Icons.cancel_rounded,
                            size: 16,
                            color: isPasswordMatch ? AppColors.success : AppColors.error,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            isPasswordMatch ? context.l10n.ruleMatch : "Passwords do not match",
                            style: AppTypography.bodySmall.copyWith(
                              color: isPasswordMatch ? AppColors.success : AppColors.error,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),

                  const SizedBox(height: 24),

                  // ── Submit Button (Disabled when invalid) ──────────────────
                  AnimatedOpacity(
                    duration: const Duration(milliseconds: 200),
                    opacity: isFormValid && !isLoading ? 1.0 : 0.45,
                    child: BouncyTap(
                      onTap: (isFormValid && !isLoading) ? _handleEmailSignUp : null,
                      child: Container(
                        width: double.infinity,
                        height: 54,
                        decoration: BoxDecoration(
                          gradient: AppColors.coralGradient,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: isFormValid && !isLoading ? AppColors.shadowBtn : [],
                        ),
                        child: Center(
                          child: isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : Text(
                                  context.l10n.registerButton,
                                  style: AppTypography.titleLarge.copyWith(
                                    color: Colors.white,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Switch to Login ───────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "${context.l10n.alreadyHaveAccount} ",
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.inkSoft),
                      ),
                      BouncyTap(
                        onTap: isLoading
                            ? null
                            : () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                        child: Text(
                          context.l10n.signInNow,
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.coralDeep,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required IconData icon,
    bool obscureText = false,
    bool enabled = true,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    Widget? suffixIcon,
  }) {
    final isFocused = focusNode.hasFocus;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isFocused ? AppColors.coral : Colors.transparent,
          width: 2,
        ),
        boxShadow: AppColors.shadowSoft,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: isFocused ? AppColors.coral : AppColors.inkSoft,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              obscureText: obscureText,
              enabled: enabled,
              keyboardType: keyboardType,
              textCapitalization: textCapitalization,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.inkSoft),
                border: InputBorder.none,
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          if (suffixIcon != null) suffixIcon,
        ],
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return CustomPaint(
      size: const Size(20, 20),
      painter: _GoogleIconPainter(),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;
    final w = size.width;
    final h = size.height;

    // Red
    paint.color = const Color(0xFFEA4335);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.5)
        ..lineTo(w * 0.5, 0)
        ..arcToPoint(Offset(w, h * 0.5), radius: Radius.circular(w * 0.5), clockwise: true)
        ..close(),
      paint,
    );

    // Blue
    paint.color = const Color(0xFF4285F4);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.5)
        ..lineTo(w, h * 0.5)
        ..arcToPoint(Offset(w * 0.5, h), radius: Radius.circular(w * 0.5), clockwise: true)
        ..close(),
      paint,
    );

    // Yellow
    paint.color = const Color(0xFFFBBC05);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.5)
        ..lineTo(w * 0.5, h)
        ..arcToPoint(Offset(0, h * 0.5), radius: Radius.circular(w * 0.5), clockwise: true)
        ..close(),
      paint,
    );

    // Green
    paint.color = const Color(0xFF34A853);
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.5, h * 0.5)
        ..lineTo(0, h * 0.5)
        ..arcToPoint(Offset(w * 0.5, 0), radius: Radius.circular(w * 0.5), clockwise: true)
        ..close(),
      paint,
    );

    // Center circle
    paint.color = Colors.white;
    canvas.drawCircle(Offset(w * 0.5, h * 0.5), w * 0.3, paint);

    // Blue horizontal bar
    paint.color = const Color(0xFF4285F4);
    canvas.drawRect(
      Rect.fromLTWH(w * 0.45, h * 0.4, w * 0.55, h * 0.2),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
