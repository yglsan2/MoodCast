import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Barre d’app avec dégradé et léger relief.
class GradientAppBar extends StatelessWidget implements PreferredSizeWidget {
  const GradientAppBar({
    super.key,
    required this.title,
    this.actions,
    this.gradient,
    this.bottom,
  });

  final String title;
  final List<Widget>? actions;
  final Gradient? gradient;
  final PreferredSizeWidget? bottom;

  static const _defaultGradient = AppColors.gradientPrimary;

  @override
  Size get preferredSize => Size.fromHeight(56 + (bottom?.preferredSize.height ?? 0));

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: gradient ?? _defaultGradient,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: AppBar(
        title: Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: AppColors.textOnPrimary,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
              ),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        actionsIconTheme: const IconThemeData(color: AppColors.textOnPrimary),
        actions: actions,
        bottom: bottom,
      ),
    );
  }
}
