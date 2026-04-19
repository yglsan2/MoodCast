import 'package:flutter/material.dart';

import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';
import 'horoscope_screen.dart';
import 'fortune_cookie_screen.dart';
import 'astro_compatibility_screen.dart';
import 'postit_mood_screen.dart';
import 'mood_share_screen.dart';
import 'mood_sos_screen.dart';
import 'mood_safe_screen.dart';
import 'mood_routine_screen.dart';
import 'weekly_summary_screen.dart';
import 'mood_sound_screen.dart';
import 'mood_pulse_screen.dart';
import 'support_screen.dart';
import 'sos_screen.dart';
import 'settings_screen.dart';
import 'mood_cast_plus_screen.dart';

class MoreScreen extends StatelessWidget {
  const MoreScreen({super.key});

  /// Affiche le bandeau "Résumé hebdo prêt" le dimanche si pas encore consulté cette semaine.
  static Future<bool> _shouldShowWeeklySummaryPrompt() async {
    final now = DateTime.now();
    if (now.weekday != DateTime.sunday) return false;
    final lastShown = await StorageService.getWeeklySummaryLastShown();
    final today = StorageService.todayString();
    return lastShown != today;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const GradientAppBar(
        title: '✨ Plus',
        gradient: AppColors.gradientPrimary,
      ),
      body: Container(
        color: Colors.transparent,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Pourquoi MoodCast te suit au quotidien',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  _ValueRow(icon: Icons.mic_rounded, text: 'Donner une forme douce à ce que tu ressens (voix → message).'),
                  const SizedBox(height: 8),
                  _ValueRow(icon: Icons.menu_book_rounded, text: 'Te souvenir que tes hauts et bas comptent — et les retrouver dans ton journal.'),
                  const SizedBox(height: 8),
                  _ValueRow(icon: Icons.shield_moon_rounded, text: 'Rituels, sécurité discrète (MoodSafe), soutien : une app pensée pour les journées chargées.'),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Padding(
              padding: const EdgeInsets.only(bottom: 12, left: 4),
              child: Text(
                'En dessous : astro, partage, sons apaisants, résumé de semaine — des bonus autour de ton cœur d’app (MoodCast & journal).',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: AppColors.textSecondary,
                      height: 1.45,
                      fontWeight: FontWeight.w500,
                    ),
              ),
            ),
            _Tile(
              icon: Icons.workspace_premium_rounded,
              title: 'MoodCast+',
              subtitle: 'Styles premium, plan hebdo — essai 7 jours & codes',
              gradient: AppColors.gradientAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MoodCastPlusScreen()),
                );
              },
            ),
            FutureBuilder<bool>(
              future: _shouldShowWeeklySummaryPrompt(),
              builder: (context, snap) {
                if (!snap.hasData || !snap.data!) return const SizedBox.shrink();
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: FeelGoodCard(
                    gradient: AppColors.gradientPrimary,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Text('📅', style: TextStyle(fontSize: 28)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Ton résumé de la semaine est prêt',
                                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.textOnPrimary,
                                    ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Text(
                          'Consulte ton bilan des 7 derniers jours.',
                          style: TextStyle(
                            fontSize: 14,
                            color: AppColors.textOnPrimary.withValues(alpha: 0.9),
                          ),
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const WeeklySummaryScreen()),
                            );
                          },
                          icon: const Icon(Icons.calendar_view_week_rounded, size: 20),
                          label: const Text('Voir mon résumé'),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.textOnPrimary,
                            foregroundColor: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            _Tile(
              icon: Icons.wb_sunny_rounded,
              title: 'MoodRoutine',
              subtitle: 'Rituel matin & soir – intention, micro-mood',
              gradient: AppColors.gradientSunrise,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MoodRoutineScreen()),
                );
              },
            ),
            _Tile(
              icon: Icons.auto_awesome_rounded,
              title: 'Horoscope',
              subtitle: 'Jour, semaine, année',
              gradient: AppColors.gradientAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const HoroscopeScreen()),
                );
              },
            ),
            _Tile(
              icon: Icons.cookie_rounded,
              title: 'Biscuit chinois',
              subtitle: 'Une fortune, un sourire, à partager',
              gradient: AppColors.gradientAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const FortuneCookieScreen()),
                );
              },
            ),
            _Tile(
              icon: Icons.people_rounded,
              title: 'AstroCompatibilité',
              subtitle: 'Compatibilité émotionnelle avec un proche',
              gradient: AppColors.gradientPrimary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const AstroCompatibilityScreen()),
                );
              },
            ),
            _Tile(
              icon: Icons.event_note_rounded,
              title: 'Post-it Mood',
              subtitle: 'Rappel émotionnel dans ton agenda',
              gradient: AppColors.gradientAccent,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const PostitMoodScreen()),
                );
              },
            ),
            _Tile(
              icon: Icons.share_rounded,
              title: 'MoodShare',
              subtitle: 'Partager son mood (proches ou anonyme)',
              gradient: AppColors.gradientPrimary,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MoodShareScreen()),
                );
              },
            ),
            _Tile(
              icon: Icons.favorite_rounded,
              title: 'MoodSOS',
              subtitle: 'J\'ai besoin d\'encouragements',
              gradient: AppColors.gradientSos,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MoodSosScreen()),
                );
              },
            ),
            _Tile(
              icon: Icons.shield_rounded,
              title: 'MoodSafe',
              subtitle: 'Alerte danger discrète – 2 s sur le bouton rouge',
              gradient: AppColors.gradientSos,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MoodSafeScreen()),
                );
              },
            ),
            _Tile(
              icon: Icons.calendar_view_week_rounded,
              title: 'Résumé hebdo',
              subtitle: 'Ta semaine en un coup d\'œil',
              gradient: AppColors.gradientPrimary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const WeeklySummaryScreen()),
              ),
            ),
            _Tile(
              icon: Icons.headphones_rounded,
              title: 'MoodSound',
              subtitle: 'Ambiances selon ton mood',
              gradient: AppColors.gradientSecondary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const MoodSoundScreen()),
              ),
            ),
            _Tile(
              icon: Icons.favorite_rounded,
              title: 'MoodPulse',
              subtitle: 'Prévenir un proche (journée difficile)',
              gradient: AppColors.gradientPrimary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => MoodPulseScreen()),
              ),
            ),
            _Tile(
              icon: Icons.favorite_outline_rounded,
              title: 'Soutien',
              subtitle: 'Ressources et bienveillance',
              gradient: AppColors.gradientSecondary,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SupportScreen()),
              ),
            ),
            _Tile(
              icon: Icons.security_rounded,
              title: 'Urgence SOS',
              subtitle: 'Aide immédiate',
              gradient: AppColors.gradientSos,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SosScreen()),
              ),
            ),
            _Tile(
              icon: Icons.settings_rounded,
              title: 'Paramètres',
              subtitle: 'Confidentialité et préférences',
              gradient: AppColors.gradientOcean,
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              ),
            ),
          ],
        ),
      ),
    );
  }

}

class _ValueRow extends StatelessWidget {
  const _ValueRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: AppColors.primary),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ),
      ],
    );
  }
}

class _Tile extends StatelessWidget {
  const _Tile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.gradient,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Gradient gradient;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: FeelGoodCard(
            margin: EdgeInsets.zero,
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    gradient: gradient,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Icon(icon, color: AppColors.textOnPrimary, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.chevron_right_rounded, color: AppColors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
