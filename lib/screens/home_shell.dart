import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../services/alert_proche_service.dart';
import '../services/mood_safe_service.dart';
import '../services/storage_service.dart';
import '../services/streak_service.dart';
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

  bool _showDailyTip = true;
  String? _userName;
  int _streak = 0;
  bool _tipDataLoaded = false;

  static const List<_TabItem> _tabs = [
    _TabItem(title: 'MoodCast', icon: Icons.mic_rounded, screen: MoodCastScreen()),
    _TabItem(title: 'WorldFlow', icon: Icons.public_rounded, screen: WorldFlowScreen()),
    _TabItem(title: 'Journal', icon: Icons.menu_book_rounded, screen: JournalScreen()),
    _TabItem(title: 'Stats', icon: Icons.insights_rounded, screen: StatsScreen()),
    _TabItem(title: 'Plus', icon: Icons.widgets_rounded, screen: MoreScreen()),
  ];

  static const List<String> _dailyTips = [
    '10 secondes de voix → un message doux rien que pour toi. Tu peux le réécouter quand tu veux.',
    'Ton journal garde chaque avis : comme un carnet de toi-même, mais avec de la voix.',
    'Les stats montrent tes tendances sans te noter : utile pour anticiper les journées plus dures.',
    'MoodRoutine (dans Plus) : 1 minute le matin ou le soir pour cadrer ton intention.',
    'WorldFlow : anonyme, pour te sentir moins seule face au monde — sans exposer ta vie.',
    'MoodShare & MoodSOS : parler à un proche ou demander un peu d’air quand ça serre.',
  ];

  @override
  void initState() {
    super.initState();
    _loadTipContext();
  }

  Future<void> _loadTipContext() async {
    final name = await StorageService.getUserName();
    final casts = await StorageService.getMoodCasts();
    final streak = StreakService.currentStreak(casts);
    if (!mounted) return;
    setState(() {
      _userName = name;
      _streak = streak;
      _tipDataLoaded = true;
    });
  }

  String get _dailyTipText {
    final i = DateTime.now().difference(DateTime(2020)).inDays.abs() % _dailyTips.length;
    return _dailyTips[i];
  }

  String get _greetingLine {
    final h = DateTime.now().hour;
    String hello;
    if (h < 12) {
      hello = 'Bonjour';
    } else if (h < 18) {
      hello = 'Bon après-midi';
    } else {
      hello = 'Bonsoir';
    }
    final name = _userName?.trim();
    if (name != null && name.isNotEmpty) {
      return '$hello, $name';
    }
    return '$hello !';
  }

  Future<void> _onAlerteProche(BuildContext context) async {
    final ok = await AlertProcheService.trigger();
    if (!context.mounted) return;
    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('SMS prêt à envoyer — il ne reste qu’à appuyer sur Envoyer.'),
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
            'Pour utiliser l’alerte en un geste, enregistrez le numéro d’un proche de confiance.\n\n'
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
          'Vous pouvez préparer le même message d’alerte pour ${remainingPhones.length} autre(s) contact(s).',
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
      body: Column(
        children: [
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(gradient: AppColors.scaffoldWash),
              child: IndexedStack(
                index: _index,
                children: _tabs.map((t) => t.screen).toList(),
              ),
            ),
          ),
          if (_showDailyTip && _tipDataLoaded)
            _DailyMotivationStrip(
              greeting: _greetingLine,
              streak: _streak,
              tip: _dailyTipText,
              onDismiss: () => setState(() => _showDailyTip = false),
              onGoMoodCast: () {
                HapticFeedback.selectionClick();
                setState(() => _index = 0);
              },
            ),
        ],
      ),
      floatingActionButton: Tooltip(
        message:
            'Appui rapide : SMS à ton proche d’alerte.\nMaintien 2 s : MoodSafe (danger) vers tes contacts de confiance.',
        waitDuration: const Duration(milliseconds: 400),
        child: Semantics(
          button: true,
          label: 'Alerte proche. Appui bref pour prévenir un proche, maintien deux secondes pour MoodSafe.',
          child: GestureDetector(
            onTapDown: (_) => _onMoodSafeLongPressStart(),
            onTapUp: (_) => _onMoodSafeLongPressEnd(context),
            onTapCancel: () => _onMoodSafeLongPressEnd(context),
            child: Material(
              elevation: 8,
              shadowColor: AppColors.error.withValues(alpha: 0.45),
              borderRadius: BorderRadius.circular(20),
              color: AppColors.error,
              child: InkWell(
                borderRadius: BorderRadius.circular(20),
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
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.2,
                        ),
                      ),
                    ],
                  ),
                ),
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
              color: Colors.black.withValues(alpha: 0.07),
              blurRadius: 24,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(_tabs.length, (i) {
                final t = _tabs[i];
                final selected = _index == i;
                return _NavItem(
                  icon: t.icon,
                  label: t.title,
                  selected: selected,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    setState(() => _index = i);
                  },
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}

class _DailyMotivationStrip extends StatelessWidget {
  const _DailyMotivationStrip({
    required this.greeting,
    required this.streak,
    required this.tip,
    required this.onDismiss,
    required this.onGoMoodCast,
  });

  final String greeting;
  final int streak;
  final String tip;
  final VoidCallback onDismiss;
  final VoidCallback onGoMoodCast;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.cardBackground,
      child: InkWell(
        onTap: onGoMoodCast,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 12, 6, 12),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  gradient: AppColors.gradientPrimary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.favorite_rounded, color: AppColors.textOnPrimary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'MoodCast',
                      style: TextStyle(
                        fontSize: 10,
                        letterSpacing: 1.2,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary.withValues(alpha: 0.85),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      greeting,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Écoute ton humeur · garde des messages bienveillants · repère tes tendances',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    if (streak >= 2) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Série : $streak jour${streak > 1 ? 's' : ''} — continue, tu crées une habitude qui te soutient.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.accentDeep,
                        ),
                      ),
                    ],
                    const SizedBox(height: 6),
                    Text(
                      tip,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Tape ici pour un MoodCast →',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded, size: 22),
                color: AppColors.textSecondary,
                onPressed: onDismiss,
                tooltip: 'Masquer pour aujourd’hui',
              ),
            ],
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
        borderRadius: BorderRadius.circular(18),
        child: AnimatedScale(
          scale: selected ? 1.04 : 1.0,
          duration: const Duration(milliseconds: 240),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              gradient: selected ? AppColors.gradientPrimary : null,
              color: selected ? null : Colors.transparent,
              borderRadius: BorderRadius.circular(18),
              boxShadow: selected
                  ? [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.28),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : null,
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
                    fontSize: 10,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                    color: selected ? AppColors.textOnPrimary : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
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
