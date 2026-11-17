import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/password_validator.dart';
import 'bouncy_tap.dart';
import '../l10n/app_localizations.dart';

enum ForgotPasswordStep {
  email,
  otp,
  newPassword,
  success,
}

class ForgotPasswordSheet extends StatefulWidget {
  final String? initialEmail;

  const ForgotPasswordSheet({
    super.key,
    this.initialEmail,
  });

  @override
  State<ForgotPasswordSheet> createState() => _ForgotPasswordSheetState();
}

class _ForgotPasswordSheetState extends State<ForgotPasswordSheet> {
  ForgotPasswordStep _currentStep = ForgotPasswordStep.email;

  // Step 1: Email
  late final TextEditingController _emailController;
  final FocusNode _emailFocus = FocusNode();

  // Step 2: OTP (6 digits)
  final List<TextEditingController> _otpControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _otpFocusNodes =
      List.generate(6, (_) => FocusNode());
  Timer? _resendTimer;
  int _resendCountdown = 60;
  bool _canResend = false;

  // Step 3: New Password
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final FocusNode _newPasswordFocus = FocusNode();
  final FocusNode _confirmPasswordFocus = FocusNode();
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isSubmitting = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _emailController = TextEditingController(text: widget.initialEmail ?? '');
    _newPasswordController.addListener(_onPasswordChanged);
    _confirmPasswordController.addListener(_onPasswordChanged);
    _newPasswordFocus.addListener(() => setState(() {}));
    _confirmPasswordFocus.addListener(() => setState(() {}));
  }

  void _onPasswordChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _emailController.dispose();
    _emailFocus.dispose();
    for (final c in _otpControllers) {
      c.dispose();
    }
    for (final f in _otpFocusNodes) {
      f.dispose();
    }
    _resendTimer?.cancel();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _newPasswordFocus.dispose();
    _confirmPasswordFocus.dispose();
    super.dispose();
  }

  void _startResendTimer() {
    _resendTimer?.cancel();
    setState(() {
      _resendCountdown = 60;
      _canResend = false;
    });
    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_resendCountdown > 1) {
        setState(() => _resendCountdown--);
      } else {
        timer.cancel();
        setState(() => _canResend = true);
      }
    });
  }

  String get _enteredOtp =>
      _otpControllers.map((c) => c.text.trim()).join();

  // ── Step 1: Submit Email -> Request OTP ───────────────────────────────────
  Future<void> _handleSendOtp() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _localError = context.l10n.pleaseEnterEmail);
      return;
    }

    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email)) {
      setState(() => _localError = context.l10n.invalidEmailAddress);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _localError = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.sendForgotPasswordOtp(email);

    if (!mounted) return;

    if (success) {
      _startResendTimer();
      setState(() {
        _isSubmitting = false;
        _currentStep = ForgotPasswordStep.otp;
      });
      // Tự động focus vào ô OTP đầu tiên
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted && _otpFocusNodes.isNotEmpty) {
          _otpFocusNodes[0].requestFocus();
        }
      });
    } else {
      setState(() {
        _isSubmitting = false;
        _localError = authProvider.errorMessage ?? context.l10n.failedToSendOtp;
      });
    }
  }

  // ── Step 2: Verify OTP ───────────────────────────────────────────────────
  Future<void> _handleVerifyOtp() async {
    final otp = _enteredOtp;
    if (otp.length < 6) {
      setState(() => _localError = context.l10n.enterFullOtpCode);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _localError = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.verifyForgotPasswordOtp(
      _emailController.text.trim(),
      otp,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isSubmitting = false;
        _currentStep = ForgotPasswordStep.newPassword;
      });
      Future.delayed(const Duration(milliseconds: 300), () {
        if (mounted) _newPasswordFocus.requestFocus();
      });
    } else {
      setState(() {
        _isSubmitting = false;
        _localError = authProvider.errorMessage ?? context.l10n.incorrectOtpCode;
      });
    }
  }

  // ── Step 3: Reset Password with Verified OTP ─────────────────────────────
  Future<void> _handleResetPassword() async {
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final validation = PasswordValidator.validate(newPassword);
    if (!validation.isValid) {
      setState(() => _localError = validation.errors.first);
      return;
    }

    if (newPassword != confirmPassword) {
      setState(() => _localError = context.l10n.ruleMatchFail);
      return;
    }

    setState(() {
      _isSubmitting = true;
      _localError = null;
    });

    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.resetPasswordWithOtp(
      email: _emailController.text.trim(),
      otp: _enteredOtp,
      newPassword: newPassword,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isSubmitting = false;
        _currentStep = ForgotPasswordStep.success;
      });
    } else {
      setState(() {
        _isSubmitting = false;
        _localError = authProvider.errorMessage ?? context.l10n.failedToResetPassword;
      });
    }
  }

  // ── OTP Boxes Input Handler ──────────────────────────────────────────────
  Widget _buildOtpBoxes() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        final focusNode = _otpFocusNodes[index];
        final controller = _otpControllers[index];
        final isFocused = focusNode.hasFocus;
        final hasValue = controller.text.isNotEmpty;

        return SizedBox(
          width: 46,
          height: 54,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isFocused
                    ? AppColors.coral
                    : (hasValue ? AppColors.inkSoft : AppColors.border),
                width: isFocused ? 2.0 : 1.2,
              ),
              boxShadow: isFocused ? AppColors.shadowSoft : [],
            ),
            child: Center(
              child: KeyboardListener(
                focusNode: FocusNode(), // Dummy node for backspace handling
                onKeyEvent: (event) {
                  if (event is KeyDownEvent &&
                      event.logicalKey == LogicalKeyboardKey.backspace &&
                      controller.text.isEmpty &&
                      index > 0) {
                    _otpFocusNodes[index - 1].requestFocus();
                  }
                },
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  keyboardType: TextInputType.number,
                  textAlign: TextAlign.center,
                  maxLength: 1,
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                  decoration: const InputDecoration(
                    counterText: '',
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (value) {
                    // Paste nhiều số vào ô đầu tiên
                    if (value.length > 1) {
                      final digits = value.replaceAll(RegExp(r'\D'), '');
                      for (int i = 0; i < 6 && i < digits.length; i++) {
                        _otpControllers[i].text = digits[i];
                      }
                      if (digits.length >= 6) {
                        _otpFocusNodes[5].requestFocus();
                        _handleVerifyOtp();
                      } else {
                        _otpFocusNodes[digits.length].requestFocus();
                      }
                      return;
                    }

                    if (value.isNotEmpty) {
                      if (index < 5) {
                        _otpFocusNodes[index + 1].requestFocus();
                      } else {
                        focusNode.unfocus();
                        // Nếu đã điền đủ 6 số, tự động trigger xác nhận
                        if (_enteredOtp.length == 6) {
                          _handleVerifyOtp();
                        }
                      }
                    } else if (index > 0) {
                      _otpFocusNodes[index - 1].requestFocus();
                    }
                    setState(() {});
                  },
                ),
              ),
            ),
          ),
        );
      }),
    );
  }

  // ── Password 7 Rules Checklist ───────────────────────────────────────────
  Widget _buildChecklistItem(String title, bool isSatisfied) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSatisfied
                  ? AppColors.success.withValues(alpha: 0.15)
                  : Colors.grey.withValues(alpha: 0.12),
              border: Border.all(
                color: isSatisfied ? AppColors.success : Colors.grey.shade400,
                width: 1.5,
              ),
            ),
            child: isSatisfied
                ? const Icon(Icons.check, size: 12, color: AppColors.success)
                : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              title,
              style: AppTypography.bodySmall.copyWith(
                color: isSatisfied ? AppColors.ink : AppColors.inkSoft,
                fontWeight: isSatisfied ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPasswordChecklist(PasswordValidationResult validation) {
    final l10n = context.l10n;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(top: 8, bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
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
          _buildChecklistItem(l10n.ruleLength, validation.hasLength),
          _buildChecklistItem(l10n.ruleUppercase, validation.hasUppercase),
          _buildChecklistItem(l10n.ruleLowercase, validation.hasLowercase),
          _buildChecklistItem(l10n.ruleDigit, validation.hasDigit),
          _buildChecklistItem(l10n.ruleSpecial, validation.hasSpecialChar),
          _buildChecklistItem(l10n.ruleNoWhitespace, validation.hasNoWhitespace),
          _buildChecklistItem(l10n.ruleNotCommon, validation.isNotCommon),
        ],
      ),
    );
  }

  Widget _buildPasswordField({
    required TextEditingController controller,
    required FocusNode focusNode,
    required String hintText,
    required String label,
    required bool obscureText,
    required VoidCallback onToggleObscure,
    bool enabled = true,
  }) {
    final isFocused = focusNode.hasFocus;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 6),
          child: Text(
            label,
            style: GoogleFonts.quicksand(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: AppColors.ink,
            ),
          ),
        ),
        AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isFocused ? AppColors.coral : AppColors.border,
              width: isFocused ? 1.8 : 1.0,
            ),
            boxShadow: isFocused ? AppColors.shadowSoft : [],
          ),
          padding: const EdgeInsets.symmetric(horizontal: 14),
          child: Row(
            children: [
              Icon(
                Icons.lock_outline_rounded,
                size: 20,
                color: isFocused ? AppColors.coral : AppColors.inkSoft,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  controller: controller,
                  focusNode: focusNode,
                  obscureText: obscureText,
                  enabled: enabled,
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.ink,
                  ),
                  decoration: InputDecoration(
                    hintText: hintText,
                    hintStyle: GoogleFonts.quicksand(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textTertiary,
                    ),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              BouncyTap(
                onTap: onToggleObscure,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Icon(
                    obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                    size: 20,
                    color: AppColors.inkSoft,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 12,
        bottom: bottomInset > 0 ? bottomInset + 20 : 36,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOutCubic,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // ── Drag Handle ─────────────────────────────────────────────
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Error Message ───────────────────────────────────────────
              if (_localError != null)
                Container(
                  width: double.infinity,
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.error.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded, size: 18, color: AppColors.error),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _localError!,
                          style: GoogleFonts.quicksand(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

              // ── STEP 1: Input Email ─────────────────────────────────────
              if (_currentStep == ForgotPasswordStep.email) ...[
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: AppColors.coralGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.coral.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_reset_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.forgotPasswordTitle,
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.forgotPasswordEmailSub,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 22),

                // Email Input
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _emailFocus.hasFocus ? AppColors.coral : AppColors.border,
                      width: _emailFocus.hasFocus ? 1.8 : 1.0,
                    ),
                    boxShadow: _emailFocus.hasFocus ? AppColors.shadowSoft : [],
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  child: Row(
                    children: [
                      Icon(
                        Icons.email_outlined,
                        size: 20,
                        color: _emailFocus.hasFocus ? AppColors.coral : AppColors.inkSoft,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: _emailController,
                          focusNode: _emailFocus,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_isSubmitting,
                          style: GoogleFonts.quicksand(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppColors.ink,
                          ),
                          decoration: InputDecoration(
                            hintText: l10n.emailLabel,
                            hintStyle: GoogleFonts.quicksand(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textTertiary,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Send OTP Button
                BouncyTap(
                  onTap: _isSubmitting ? null : _handleSendOtp,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: _isSubmitting ? null : AppColors.coralGradient,
                      color: _isSubmitting ? AppColors.border : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isSubmitting ? null : AppColors.shadowBtn,
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              l10n.sendOtpButton,
                              style: GoogleFonts.quicksand(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
              ],

              // ── STEP 2: Input OTP ───────────────────────────────────────
              if (_currentStep == ForgotPasswordStep.otp) ...[
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: AppColors.coralGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.coral.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.pin_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.otpTitle,
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  l10n.otpSentToEmail(_emailController.text.trim()),
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                    height: 1.45,
                  ),
                ),
                const SizedBox(height: 24),

                // 6 Boxes OTP Input
                _buildOtpBoxes(),
                const SizedBox(height: 20),

                // Resend Timer & Button
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      l10n.noOtpReceived,
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.inkSoft,
                      ),
                    ),
                    if (!_canResend)
                      Text(
                        l10n.resendCountdown(_resendCountdown),
                        style: GoogleFonts.quicksand(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.coral,
                        ),
                      )
                    else
                      BouncyTap(
                        onTap: _isSubmitting ? null : _handleSendOtp,
                        child: Text(
                          l10n.resendOtp,
                          style: GoogleFonts.quicksand(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.coral,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 22),

                // Verify OTP Button
                BouncyTap(
                  onTap: (_isSubmitting || _enteredOtp.length < 6)
                      ? null
                      : _handleVerifyOtp,
                  child: Container(
                    width: double.infinity,
                    height: 52,
                    decoration: BoxDecoration(
                      gradient: (_isSubmitting || _enteredOtp.length < 6)
                          ? null
                          : AppColors.coralGradient,
                      color: (_isSubmitting || _enteredOtp.length < 6)
                          ? AppColors.border
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: (_isSubmitting || _enteredOtp.length < 6)
                          ? null
                          : AppColors.shadowBtn,
                    ),
                    child: Center(
                      child: _isSubmitting
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(
                              l10n.verifyOtpButton,
                              style: GoogleFonts.quicksand(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                BouncyTap(
                  onTap: () => setState(() => _currentStep = ForgotPasswordStep.email),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Text(
                      l10n.changeEmailAddress,
                      style: GoogleFonts.quicksand(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
              ],

              // ── STEP 3: Input New Password ──────────────────────────────
              if (_currentStep == ForgotPasswordStep.newPassword) ...[
                Container(
                  width: 62,
                  height: 62,
                  decoration: BoxDecoration(
                    gradient: AppColors.coralGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.coral.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.lock_open_rounded,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  l10n.newPasswordLabel,
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 20),

                // New Password Input
                _buildPasswordField(
                  controller: _newPasswordController,
                  focusNode: _newPasswordFocus,
                  label: l10n.newPasswordLabel,
                  hintText: l10n.newPasswordLabel,
                  obscureText: _obscureNew,
                  onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                  enabled: !_isSubmitting,
                ),

                // Realtime Checklist 7 Rules
                if (_newPasswordFocus.hasFocus || _newPasswordController.text.isNotEmpty)
                  _buildPasswordChecklist(
                    PasswordValidator.validate(_newPasswordController.text),
                  ),

                const SizedBox(height: 14),

                // Confirm Password Input
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmPasswordFocus,
                  label: l10n.confirmNewPasswordLabel,
                  hintText: l10n.confirmNewPasswordLabel,
                  obscureText: _obscureConfirm,
                  onToggleObscure: () =>
                      setState(() => _obscureConfirm = !_obscureConfirm),
                  enabled: !_isSubmitting,
                ),

                // Match Status Text
                if (_confirmPasswordController.text.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 6),
                    child: Row(
                      children: [
                        Icon(
                          _newPasswordController.text == _confirmPasswordController.text
                              ? Icons.check_circle_rounded
                              : Icons.cancel_rounded,
                          size: 16,
                          color: _newPasswordController.text == _confirmPasswordController.text
                              ? AppColors.success
                              : AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          _newPasswordController.text == _confirmPasswordController.text
                              ? l10n.ruleMatch
                              : l10n.ruleMatchFail,
                          style: AppTypography.bodySmall.copyWith(
                            color: _newPasswordController.text == _confirmPasswordController.text
                                ? AppColors.success
                                : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Submit Reset Password Button
                Builder(builder: (context) {
                  final validation =
                      PasswordValidator.validate(_newPasswordController.text);
                  final isMatch = _confirmPasswordController.text.isNotEmpty &&
                      _newPasswordController.text == _confirmPasswordController.text;
                  final isFormValid =
                      validation.isValid && isMatch && !_isSubmitting;

                  return BouncyTap(
                    onTap: isFormValid ? _handleResetPassword : null,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: isFormValid ? AppColors.coralGradient : null,
                        color: isFormValid ? null : AppColors.border,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isFormValid ? AppColors.shadowBtn : null,
                      ),
                      child: Center(
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              )
                            : Text(
                                l10n.saveNewPasswordButton,
                                style: GoogleFonts.quicksand(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  );
                }),
              ],

              // ── STEP 4: Success ─────────────────────────────────────────
              if (_currentStep == ForgotPasswordStep.success) ...[
                Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    gradient: AppColors.mintGradient,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.mint.withValues(alpha: 0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.check_circle_outline_rounded,
                      color: Colors.white,
                      size: 38,
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  l10n.resetPasswordSuccessTitle,
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  l10n.resetPasswordSuccessSub,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 26),
                BouncyTap(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    width: double.infinity,
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: AppColors.mintGradient,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: AppColors.shadowBtn,
                    ),
                    child: Center(
                      child: Text(
                        l10n.loginNowButton,
                        style: GoogleFonts.quicksand(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 12),

              // ── Cancel Button (Unless on success step) ───────────────────
              if (_currentStep != ForgotPasswordStep.success)
                BouncyTap(
                  onTap: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Text(
                      l10n.cancel,
                      style: GoogleFonts.quicksand(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

void showForgotPasswordSheet(BuildContext context, {String? initialEmail}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => ForgotPasswordSheet(initialEmail: initialEmail),
  );
}
