import "package:flutter/material.dart";
import "package:provider/provider.dart";
import "../providers/auth_provider.dart";
import "../utils/app_routes.dart";
import "../theme/app_colors.dart";
import "../theme/app_typography.dart";
import "../widgets/app_logo.dart";
import "../widgets/app_background.dart";
import "../widgets/bouncy_tap.dart";

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

  final _firstFocus = FocusNode();
  final _lastFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();

  bool _obscurePassword = true;
  bool _showEmailForm = true;

  @override
  void initState() {
    super.initState();
    _firstFocus.addListener(() => setState(() {}));
    _lastFocus.addListener(() => setState(() {}));
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _firstFocus.dispose();
    _lastFocus.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleGoogleSignUp() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? "Đăng ký Google thất bại"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleEmailSignUp() async {
    final firstName = _firstNameController.text.trim();
    final lastName = _lastNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (firstName.isEmpty || lastName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Vui lòng nhập họ và tên"),
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
      if (authProvider.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(authProvider.errorMessage!),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 4),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Đăng ký thành công!"),
            backgroundColor: AppColors.success,
          ),
        );
      }
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? "Có lỗi xảy ra"),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

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
                  const AppLogo(size: 68, isTilted: true, hasShadow: true),
                  const SizedBox(height: 20),

                  // ── Title ─────────────────────────────────────────────────
                  Text(
                    "Tạo tài khoản mới",
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Gia nhập cộng đồng Threads ngay hôm nay",
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.inkSoft),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 24),

                  // ── Google Signup Button (Quick) ──────────────────────────
                  BouncyTap(
                    onTap: isLoading ? null : _handleGoogleSignUp,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.ink.withOpacity(0.10), width: 1.5),
                        boxShadow: AppColors.shadowSoft,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGoogleIcon(),
                          const SizedBox(width: 12),
                          Text(
                            "Tiếp tục với Google",
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 18),

                  // ── Divider ───────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(child: Container(height: 1, color: AppColors.ink.withOpacity(0.12))),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text("hoặc bằng email", style: AppTypography.bodySmall.copyWith(color: AppColors.inkSoft)),
                      ),
                      Expanded(child: Container(height: 1, color: AppColors.ink.withOpacity(0.12))),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Names Row ─────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: _buildInputField(
                          controller: _firstNameController,
                          focusNode: _firstFocus,
                          hintText: "Họ",
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
                          hintText: "Tên",
                          icon: Icons.person_outline_rounded,
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
                    hintText: "Email",
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 14),

                  // ── Password ──────────────────────────────────────────────
                  _buildInputField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    hintText: "Mật khẩu",
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
                  const SizedBox(height: 22),

                  // ── Submit Button ─────────────────────────────────────────
                  BouncyTap(
                    onTap: isLoading ? null : _handleEmailSignUp,
                    child: Container(
                      width: double.infinity,
                      height: 54,
                      decoration: BoxDecoration(
                        gradient: AppColors.coralGradient,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: AppColors.shadowBtn,
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
                                "Đăng ký",
                                style: AppTypography.titleLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
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
                        "Đã có tài khoản? ",
                        style: AppTypography.bodyMedium.copyWith(color: AppColors.inkSoft),
                      ),
                      BouncyTap(
                        onTap: isLoading
                            ? null
                            : () => Navigator.pushReplacementNamed(context, AppRoutes.login),
                        child: Text(
                          "Đăng nhập",
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
              style: AppTypography.bodyLarge.copyWith(color: AppColors.ink),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.inkSoft),
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                fillColor: Colors.transparent,
                filled: false,
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          if (suffixIcon != null) suffixIcon,
        ],
      ),
    );
  }

  Widget _buildGoogleIcon() {
    return SizedBox(
      width: 20,
      height: 20,
      child: CustomPaint(
        painter: _GoogleIconPainter(),
      ),
    );
  }
}

class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final greenPaint = Paint()..color = const Color(0xFF34A853);

    canvas.drawRect(Rect.fromLTWH(w * 0.45, h * 0.38, w * 0.55, h * 0.24), bluePaint);

    final center = Offset(w / 2, h / 2);
    final radius = w / 2;
    final strokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.22;

    strokePaint.color = const Color(0xFF4285F4);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.8), -0.5, 1.2, false, strokePaint);

    strokePaint.color = const Color(0xFF34A853);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.8), 0.7, 1.5, false, strokePaint);

    strokePaint.color = const Color(0xFFFBBC05);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.8), 2.2, 1.3, false, strokePaint);

    strokePaint.color = const Color(0xFFEA4335);
    canvas.drawArc(Rect.fromCircle(center: center, radius: radius * 0.8), 3.5, 1.5, false, strokePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
