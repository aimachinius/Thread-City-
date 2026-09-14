import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Soft ambient pastel glow background
/// Matches the radial gradient background from threads_redesign.html
class AppBackground extends StatelessWidget {
  final Widget child;

  const AppBackground({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Base solid cream color
        Container(color: AppColors.cream),

        // Peach radial glow at top-left
        Positioned(
          top: -60,
          left: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.peach.withOpacity(0.85),
                  AppColors.peach.withOpacity(0.0),
                ],
                radius: 0.65,
              ),
            ),
          ),
        ),

        // Mint radial glow at bottom-right
        Positioned(
          bottom: -60,
          right: -60,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  AppColors.mint.withOpacity(0.70),
                  AppColors.mint.withOpacity(0.0),
                ],
                radius: 0.65,
              ),
            ),
          ),
        ),

        // Foreground content
        Positioned.fill(child: child),
      ],
    );
  }
}
