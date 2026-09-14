import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../utils/app_routes.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../widgets/app_logo.dart';
import '../widgets/app_background.dart';
import '../widgets/bouncy_tap.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailFocus = FocusNode();
  final _passwordFocus = FocusNode();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _emailFocus.addListener(() => setState(() {}));
    _passwordFocus.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _emailFocus.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final authProvider = context.read<AuthProvider>();

    final success = await authProvider.signIn(
      email: _emailController.text.trim(),
      password: _passwordController.text.trim(),
    );

    if (success && mounted) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Đăng nhập thất bại'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  Future<void> _handleGoogleLogin() async {
    final authProvider = context.read<AuthProvider>();
    final success = await authProvider.signInWithGoogle();
    if (!mounted) return;
    if (success) {
      Navigator.pushReplacementNamed(context, AppRoutes.home);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage ?? 'Đăng nhập Google thất bại'),
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
                  const SizedBox(height: 24),

                  // ── Cute Tilted Blob Logo ──────────────────────────────────
                  const AppLogo(
                    size: 78,
                    isTilted: true,
                    hasShadow: true,
                  ),
                  const SizedBox(height: 26),

                  // ── Title & Subtitle ───────────────────────────────────────
                  Text(
                    'Chào mừng trở lại',
                    style: AppTypography.displayMedium.copyWith(
                      color: AppColors.ink,
                      fontWeight: FontWeight.w700,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Đăng nhập để tiếp tục hành trình của bạn',
                    style: AppTypography.bodyMedium.copyWith(
                      color: AppColors.inkSoft,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),

                  // ── Email Field ───────────────────────────────────────────
                  _buildInputField(
                    controller: _emailController,
                    focusNode: _emailFocus,
                    hintText: 'Email hoặc tên đăng nhập',
                    icon: Icons.mail_outline_rounded,
                    keyboardType: TextInputType.emailAddress,
                    enabled: !isLoading,
                  ),
                  const SizedBox(height: 16),

                  // ── Password Field ────────────────────────────────────────
                  _buildInputField(
                    controller: _passwordController,
                    focusNode: _passwordFocus,
                    hintText: 'Mật khẩu',
                    icon: Icons.lock_outline_rounded,
                    obscureText: _obscurePassword,
                    enabled: !isLoading,
                    suffixIcon: BouncyTap(
                      onTap: () => setState(() => _obscurePassword = !_obscurePassword),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        size: 20,
                        color: AppColors.inkSoft,
                      ),
                    ),
                  ),

                  // ── Forgot Password ───────────────────────────────────────
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 10, right: 4),
                      child: BouncyTap(
                        onTap: isLoading ? null : () {},
                        child: Text(
                          'Quên mật khẩu?',
                          style: AppTypography.titleSmall.copyWith(
                            color: AppColors.mintDeep,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 22),

                  // ── Primary Login Button ──────────────────────────────────
                  BouncyTap(
                    onTap: isLoading ? null : _handleLogin,
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
                                'Đăng nhập',
                                style: AppTypography.titleLarge.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── Divider ───────────────────────────────────────────────
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.ink.withOpacity(0.12),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        child: Text(
                          'hoặc',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.inkSoft,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: AppColors.ink.withOpacity(0.12),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // ── Google Sign In Button ─────────────────────────────────
                  BouncyTap(
                    onTap: isLoading ? null : _handleGoogleLogin,
                    child: Container(
                      width: double.infinity,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.ink.withOpacity(0.10),
                          width: 1.5,
                        ),
                        boxShadow: AppColors.shadowSoft,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildGoogleIcon(),
                          const SizedBox(width: 12),
                          Text(
                            'Tiếp tục với Google',
                            style: AppTypography.titleSmall.copyWith(
                              color: AppColors.ink,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // ── Switch to Register ────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Chưa có tài khoản? ',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.inkSoft,
                        ),
                      ),
                      BouncyTap(
                        onTap: isLoading
                            ? null
                            : () => Navigator.pushNamed(context, AppRoutes.register),
                        child: Text(
                          'Đăng ký',
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
              style: AppTypography.bodyLarge.copyWith(
                color: AppColors.ink,
              ),
              decoration: InputDecoration(
                hintText: hintText,
                hintStyle: AppTypography.bodyMedium.copyWith(
                  color: AppColors.inkSoft,
                ),
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

/// Custom painter for crisp, official Google 'G' colors
class _GoogleIconPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final redPaint = Paint()..color = const Color(0xFFEA4335);
    final bluePaint = Paint()..color = const Color(0xFF4285F4);
    final yellowPaint = Paint()..color = const Color(0xFFFBBC05);
    final greenPaint = Paint()..color = const Color(0xFF34A853);

    // Blue horizontal bar
    canvas.drawRect(
      Rect.fromLTWH(w * 0.45, h * 0.38, w * 0.55, h * 0.24),
      bluePaint,
    );

    // Surrounding arcs
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
