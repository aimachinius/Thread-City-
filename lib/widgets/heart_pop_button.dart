import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'bouncy_tap.dart';

/// Animated Heart Reaction Button with Burst Micro-interaction
/// Replicates the heart pop effect from threads_redesign.html
class HeartPopButton extends StatefulWidget {
  final bool isLiked;
  final int count;
  final VoidCallback onTap;
  final double iconSize;

  const HeartPopButton({
    super.key,
    required this.isLiked,
    required this.count,
    required this.onTap,
    this.iconSize = 22,
  });

  @override
  State<HeartPopButton> createState() => _HeartPopButtonState();
}

class _HeartPopButtonState extends State<HeartPopButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _popController;
  late Animation<double> _popScale;
  late Animation<double> _burstScale;
  late Animation<double> _burstOpacity;
  late Animation<double> _burstTranslateY;

  @override
  void initState() {
    super.initState();
    _popController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    );

    // Main button bounce
    _popScale = TweenSequence<double>([
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.0, end: 1.35)
            .chain(CurveTween(curve: Curves.easeOut)),
        weight: 40,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 1.35, end: 0.9)
            .chain(CurveTween(curve: Curves.easeInOut)),
        weight: 30,
      ),
      TweenSequenceItem(
        tween: Tween<double>(begin: 0.9, end: 1.0)
            .chain(CurveTween(curve: Curves.easeOutBack)),
        weight: 30,
      ),
    ]).animate(_popController);

    // Burst floating particle
    _burstScale = Tween<double>(begin: 0.3, end: 1.25).animate(
      CurvedAnimation(
        parent: _popController,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
      ),
    );

    _burstOpacity = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _popController,
        curve: const Interval(0.4, 1.0, curve: Curves.easeIn),
      ),
    );

    _burstTranslateY = Tween<double>(begin: 0.0, end: -24.0).animate(
      CurvedAnimation(
        parent: _popController,
        curve: Curves.easeOutCubic,
      ),
    );
  }

  @override
  void dispose() {
    _popController.dispose();
    super.dispose();
  }

  void _handleTap() {
    if (!widget.isLiked) {
      _popController.forward(from: 0.0);
    }
    widget.onTap();
  }

  @override
  Widget build(BuildContext context) {
    const activeColor = AppColors.heart;
    const inactiveColor = AppColors.inkSoft;

    return BouncyTap(
      onTap: _handleTap,
      scaleDown: 0.90,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.centerLeft,
          children: [
            // Bursting heart overlay
            AnimatedBuilder(
              animation: _popController,
              builder: (context, child) {
                if (!_popController.isAnimating) return const SizedBox.shrink();
                return Positioned(
                  top: _burstTranslateY.value,
                  left: 0,
                  child: Opacity(
                    opacity: _burstOpacity.value,
                    child: Transform.scale(
                      scale: _burstScale.value,
                      child: Icon(
                        Icons.favorite_rounded,
                        size: widget.iconSize,
                        color: activeColor,
                      ),
                    ),
                  ),
                );
              },
            ),

            // Base button row
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _popScale,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _popController.isAnimating ? _popScale.value : 1.0,
                      child: child,
                    );
                  },
                  child: Icon(
                    widget.isLiked
                        ? Icons.favorite_rounded
                        : Icons.favorite_border_rounded,
                    size: widget.iconSize,
                    color: widget.isLiked ? activeColor : inactiveColor,
                  ),
                ),
                if (widget.count > 0) ...[
                  const SizedBox(width: 5),
                  AnimatedDefaultTextStyle(
                    duration: const Duration(milliseconds: 200),
                    style: AppTypography.labelMedium.copyWith(
                      color: widget.isLiked ? activeColor : inactiveColor,
                      fontWeight: FontWeight.w700,
                    ),
                    child: Text('${widget.count}'),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
