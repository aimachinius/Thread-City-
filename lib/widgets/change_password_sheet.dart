import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../utils/password_validator.dart';
import 'bouncy_tap.dart';
import '../l10n/app_localizations.dart';

void showChangePasswordSheet(BuildContext context) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => const ChangePasswordSheet(),
  );
}

class ChangePasswordSheet extends StatefulWidget {
  const ChangePasswordSheet({super.key});

  @override
  State<ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<ChangePasswordSheet> {
  final TextEditingController _currentPasswordController = TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();

  final FocusNode _currentFocus = FocusNode();
  final FocusNode _newFocus = FocusNode();
  final FocusNode _confirmFocus = FocusNode();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;

  bool _isSubmitting = false;
  bool _isSuccess = false;
  String? _localError;

  @override
  void initState() {
    super.initState();
    _currentPasswordController.addListener(_onFieldChanged);
    _newPasswordController.addListener(_onFieldChanged);
    _confirmPasswordController.addListener(_onFieldChanged);
    _currentFocus.addListener(() => setState(() {}));
    _newFocus.addListener(() => setState(() {}));
    _confirmFocus.addListener(() => setState(() {}));
  }

  void _onFieldChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    _currentFocus.dispose();
    _newFocus.dispose();
    _confirmFocus.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (currentPassword.isEmpty) {
      setState(() => _localError = context.l10n.pleaseEnterCurrentPassword);
      return;
    }

    if (currentPassword == newPassword) {
      setState(() => _localError = context.l10n.passwordCannotMatchOld);
      return;
    }

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
    final success = await authProvider.changePassword(
      currentPassword: currentPassword,
      newPassword: newPassword,
    );

    if (!mounted) return;

    if (success) {
      setState(() {
        _isSubmitting = false;
        _isSuccess = true;
      });
    } else {
      setState(() {
        _isSubmitting = false;
        _localError = authProvider.errorMessage ?? context.l10n.changePasswordFailure;
      });
    }
  }

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
                decoration: isSatisfied ? TextDecoration.none : null,
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
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final currentPassword = _currentPasswordController.text;
    final newPassword = _newPasswordController.text;
    final confirmPassword = _confirmPasswordController.text;

    final validation = PasswordValidator.validate(newPassword);
    final isMatch = confirmPassword.isNotEmpty && newPassword == confirmPassword;
    final isDifferent = currentPassword.isNotEmpty && newPassword.isNotEmpty && currentPassword != newPassword;

    final isFormValid = currentPassword.isNotEmpty &&
        validation.isValid &&
        isMatch &&
        isDifferent &&
        !_isSubmitting;

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

              if (_isSuccess) ...[
                // ── Success State ─────────────────────────────────────────
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
                  context.l10n.changePasswordSuccess,
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  context.l10n.changePasswordSuccessSub,
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
                        context.l10n.done,
                        style: GoogleFonts.quicksand(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                // ── Form State ────────────────────────────────────────────
                Container(
                  width: 58,
                  height: 58,
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
                      size: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  context.l10n.changePasswordTitle,
                  style: GoogleFonts.quicksand(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  context.l10n.changePasswordSubtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.quicksand(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.inkSoft,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 20),

                // Error Message
                if (_localError != null)
                  Container(
                    width: double.infinity,
                    margin: const EdgeInsets.only(bottom: 14),
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

                // 1. Current Password
                _buildPasswordField(
                  controller: _currentPasswordController,
                  focusNode: _currentFocus,
                  label: context.l10n.currentPasswordLabel,
                  hintText: context.l10n.currentPasswordLabel,
                  obscureText: _obscureCurrent,
                  onToggleObscure: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  enabled: !_isSubmitting,
                ),
                const SizedBox(height: 14),

                // 2. New Password
                _buildPasswordField(
                  controller: _newPasswordController,
                  focusNode: _newFocus,
                  label: context.l10n.newPasswordLabel,
                  hintText: context.l10n.newPasswordLabel,
                  obscureText: _obscureNew,
                  onToggleObscure: () => setState(() => _obscureNew = !_obscureNew),
                  enabled: !_isSubmitting,
                ),

                // Realtime Checklist 7 Rules
                if (_newFocus.hasFocus || newPassword.isNotEmpty)
                  _buildPasswordChecklist(validation),

                if (currentPassword.isNotEmpty && newPassword.isNotEmpty && currentPassword == newPassword)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, left: 4),
                    child: Row(
                      children: [
                        const Icon(Icons.cancel_rounded, size: 15, color: AppColors.error),
                        const SizedBox(width: 6),
                        Text(
                          context.l10n.passwordCannotMatchOld,
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 14),

                // 3. Confirm New Password
                _buildPasswordField(
                  controller: _confirmPasswordController,
                  focusNode: _confirmFocus,
                  label: context.l10n.confirmNewPasswordLabel,
                  hintText: context.l10n.confirmNewPasswordLabel,
                  obscureText: _obscureConfirm,
                  onToggleObscure: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  enabled: !_isSubmitting,
                ),

                // Match Status Text
                if (confirmPassword.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 8, left: 6),
                    child: Row(
                      children: [
                        Icon(
                          isMatch ? Icons.check_circle_rounded : Icons.cancel_rounded,
                          size: 16,
                          color: isMatch ? AppColors.success : AppColors.error,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isMatch ? context.l10n.ruleMatch : context.l10n.ruleMatchFail,
                          style: AppTypography.bodySmall.copyWith(
                            color: isMatch ? AppColors.success : AppColors.error,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 24),

                // Submit Button
                AnimatedOpacity(
                  duration: const Duration(milliseconds: 200),
                  opacity: isFormValid ? 1.0 : 0.45,
                  child: BouncyTap(
                    onTap: isFormValid ? _handleSubmit : null,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: AppColors.coralGradient,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: isFormValid ? AppColors.shadowBtn : [],
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
                                context.l10n.saveNewPasswordButton,
                                style: GoogleFonts.quicksand(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
