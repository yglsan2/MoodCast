import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Carte arrondie, ombre douce, option dégradé — effet « carte tactile ».
class FeelGoodCard extends StatelessWidget {
  const FeelGoodCard({
    super.key,
    required this.child,
    this.gradient,
    this.padding = const EdgeInsets.all(20),
    this.margin,
  });

  final Widget child;
  final Gradient? gradient;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    final isGradient = gradient != null;
    return Container(
      margin: margin ?? const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: gradient,
        color: isGradient ? null : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isGradient
              ? Colors.white.withValues(alpha: 0.42)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: padding,
        child: child,
      ),
    );
  }
}
