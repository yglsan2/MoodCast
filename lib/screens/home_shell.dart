import 'dart:async';

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../services/alert_proche_service.dart';
import '../services/mood_safe_service.dart';
import 'mood_cast_screen.dart';
import 'settings_screen.dart';
import 'world_flow_screen.dart';
import 'journal_screen.dart';
import 'stats_screen.dart';
import 'more_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  Timer? _moodSafeTimer;
  bool _moodSafeTriggeredThisGesture = false;

  static const List<_TabItem> _tabs = [
    _TabItem(title: 'MoodCast', icon: Icons.mic_rounded, screen: MoodCastScreen()),
    _TabItem(title: 'WorldFlow', icon: Icons.public_rounded, screen: WorldFlowScreen()),
    _TabItem(title: 'Journal', icon: Icons.menu_book_rounded, screen: JournalScreen()),
    _TabItem(title: 'Stats', icon: Icons.insights_rounded, screen: StatsScreen()),
    _TabItem(title: 'Plus', icon: Icons.widgets_rounded, screen: const MoreScreen()),
  ];

  Future<void> _onAlerteProche(BuildContext context) async {
    final ok = await AlertProcheService.trigger();
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('SMS prêt à envoyer — il ne reste qu\'à appuyer sur Envoyer.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
          duration: const Duration(seconds: 3),
        ),
      );
    } else {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Alerte proche'),
          content: const Text(
            'Pour utiliser l\'alerte en un geste, enregistrez le numéro d\'un proche de confiance.\n\n'
            'Allez dans Plus → Paramètres → Alerte sécurité.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Plus tard'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Paramètres'),
            ),
          ],
        ),
      );
      if (go == true && context.mounted) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const SettingsScreen()),
        );
      }
    }
  }

  void _onMoodSafeLongPressStart() {
    _moodSafeTriggeredThisGesture = false;
    _moodSafeTimer?.cancel();
    _moodSafeTimer = Timer(const Duration(seconds: 2), () {
      _moodSafeTriggeredThisGesture = true;
      _moodSafeTimer = null;
      _triggerMoodSafe();
    });
  }

  void _onMoodSafeLongPressEnd(BuildContext context) {
    if (_moodSafeTriggeredThisGesture) {
      _moodSafeTriggeredThisGesture = false;
      return;
    }
    _moodSafeTimer?.cancel();
    _moodSafeTimer = null;
    _onAlerteProche(context);
  }

  Future<void> _triggerMoodSafe() async {
    final result = await MoodSafeService.trigger();
    if (!mounted) return;
    if (!result.success && result.remainingPhones.isEmpty) {
      final go = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('MoodSafe'),
          content: const Text(
            'Pour envoyer une alerte danger à vos proches, enregistrez au moins un contact de confiance.\n\n'
            'Plus → Paramètres → Alerte sécurité / MoodSafe.',
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Plus tard')),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Paramètres')),
          ],
        ),
      );
      if (go == true && mounted) {
        Navigator.push(context, MaterialPageRoute(builder: (_) => const SettingsScreen()));
      }
      return;
    }
    if (result.success) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Alerte danger — SMS prêt. Envoyez le message.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 4),
        ),
      );
    }
    if (result.remainingPhones.isNotEmpty && mounted) {
      _offerSendToOtherContacts(context, result.message, result.remainingPhones);
    }
  }

  void _offerSendToOtherContacts(
    BuildContext context,
    String message,
    List<String> remainingPhones,
  ) {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Envoyer à un autre proche ?'),
        content: Text(
          'Vous pouvez préparer le même message d\'alerte pour ${remainingPhones.length} autre(s) contact(s).',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Non'),
          ),
          ...remainingPhones.asMap().entries.map((e) {
            return FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await MoodSafeService.openSmsTo(e.value, message);
              },
              child: Text('Oui, contact ${e.key + 2}'),
            );
          }),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _moodSafeTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: AppColors.background,
        child: IndexedStack(
          index: _index,
          children: _tabs.map((t) => t.screen).toList(),
        ),
      ),
      floatingActionButton: GestureDetector(
        onTapDown: (_) => _onMoodSafeLongPressStart(),
        onTapUp: (_) => _onMoodSafeLongPressEnd(context),
        onTapCancel: () => _onMoodSafeLongPressEnd(context),
        child: Material(
          elevation: 6,
          borderRadius: BorderRadius.circular(16),
          color: AppColors.error,
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: () {},
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.emergency_rounded, size: 26, color: AppColors.textOnPrimary),
                  const SizedBox(width: 12),
                  Text(
                    'Alerte proche',
                    style: TextStyle(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: AppColors.cardBackground,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final t = _tabs[i];
                final selected = _index == i;
                return _NavItem(
                  icon: t.icon,
                  label: t.title,
                  selected: selected,
                  onTap: () => setState(() => _index = i),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            gradient: selected ? AppColors.gradientPrimary : null,
            color: selected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 26,
                color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
              ),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                  color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabItem {
  const _TabItem({required this.title, required this.icon, required this.screen});
  final String title;
  final IconData icon;
  final Widget screen;
}
