import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../services/storage_service.dart';
import 'mood_sos_screen.dart';
import 'legal_screen.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';

/// IDs des conseils (pour le vote local).
const Map<String, String> _supportTipLabels = {
  'mood_sos': 'J\'ai besoin d\'encouragements',
  'respiration_444': 'Respiration 4-4-4',
  'coherence_365': 'Cohérence cardiaque (365)',
  'cinq_sens': 'Méthode des 5 sens',
  'jacobson': 'Relaxation Jacobson',
  'lieu_sur': 'Lieu sûr',
  'shuffle_cognitif': 'Shuffle cognitif',
  'hygiene_sommeil': 'Hygiène du sommeil',
};

/// Ressources et bienveillance : écoute, respiration, liens utiles.
class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  Map<String, int> _votes = {};

  @override
  void initState() {
    super.initState();
    _loadVotes();
  }

  Future<void> _loadVotes() async {
    final v = await StorageService.getSupportVotes();
    if (mounted) setState(() => _votes = v);
  }

  Future<void> _onVote(String tipId) async {
    await StorageService.incrementSupportVote(tipId);
    if (mounted) {
      setState(() => _votes[tipId] = (_votes[tipId] ?? 0) + 1);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Merci, ton avis nous aide.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  List<MapEntry<String, int>> get _topVotedTips {
    final list = _votes.entries.where((e) => e.value > 0).toList();
    list.sort((a, b) => b.value.compareTo(a.value));
    return list;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: '💜 Soutien',
        gradient: AppColors.gradientSecondary,
      ),
      body: Container(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            if (_topVotedTips.isNotEmpty) ...[
              _SectionTitle(title: 'Tes conseils les plus utiles'),
              FeelGoodCard(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _topVotedTips.map((e) {
                    final label = _supportTipLabels[e.key] ?? e.key;
                    return Chip(
                      avatar: CircleAvatar(
                        backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                        child: Text(
                          '${e.value}',
                          style: const TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                      label: Text(label),
                      backgroundColor: AppColors.surface,
                    );
                  }).toList(),
                ),
              ),
              const SizedBox(height: 20),
            ],
            FeelGoodCard(
              gradient: AppColors.gradientSecondary,
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vous n\'êtes pas seul(e)',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textOnPrimary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Ces ressources peuvent vous aider en cas de besoin. Prenez soin de vous.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const MoodSosScreen()),
                ),
                borderRadius: BorderRadius.circular(20),
                child: FeelGoodCard(
                  margin: EdgeInsets.zero,
                  gradient: AppColors.gradientPrimary,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.favorite_rounded, color: Colors.white, size: 36),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'J\'ai besoin d\'encouragements',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Un encouragement personnalisé ou un message à ton proche.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.white.withValues(alpha: 0.95),
                              ),
                            ),
                            const SizedBox(height: 10),
                            _VoteButton(
                              tipId: 'mood_sos',
                              count: _votes['mood_sos'] ?? 0,
                              onVote: _onVote,
                              light: true,
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.white.withValues(alpha: 0.9)),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle(title: 'Respiration'),
            FeelGoodCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Respiration 4-4-4',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Inspirez 4 secondes, retenez 4 secondes, expirez 4 secondes. Répétez 3 à 5 fois. '
                    'Cela aide à calmer le système nerveux et à recentrer l\'attention.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _VoteButton(tipId: 'respiration_444', count: _votes['respiration_444'] ?? 0, onVote: _onVote),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FeelGoodCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Cohérence cardiaque (méthode 365)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text('💓', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Technique de respiration rythmée, documentée en recherche (variabilité cardiaque, réduction du cortisol). '
                    'Protocole 365 : 3 fois par jour, 6 respirations par minute, 5 minutes par séance.',
                    style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    '• Inspire 5 secondes, expire 5 secondes (1 cycle = 10 s, 6 cycles = 1 min).',
                    style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '• Idéal : au réveil, avant déjeuner, en fin d\'après-midi. Les effets d\'une séance durent environ 4 à 6 h.',
                    style: TextStyle(fontSize: 14, height: 1.45, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  _VoteButton(tipId: 'coherence_365', count: _votes['coherence_365'] ?? 0, onVote: _onVote),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: 'Anti-stress et angoisse'),
            FeelGoodCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Méthode des 5 sens (ancrage)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text('🌸', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Quand l\'angoisse ou le stress montent, cette technique t\'ancrer dans le moment présent. '
                    'À faire mentalement ou à voix basse, en prenant ton temps :',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _NumberedStep(step: 1, text: '5 choses que tu VOIS (objets autour de toi)'),
                  _NumberedStep(step: 2, text: '4 choses que tu TOUCHES (le siège, le sol, tes mains)'),
                  _NumberedStep(step: 3, text: '3 choses que tu ENTENDS (sons proches ou lointains)'),
                  _NumberedStep(step: 4, text: '2 choses que tu SENS (odeurs)'),
                  _NumberedStep(step: 5, text: '1 chose que tu GOÛTES (un sip d\'eau, ta bouche)'),
                  const SizedBox(height: 8),
                  Text(
                    'En nommant concrètement chaque élément, tu ramènes ton attention dans l\'ici et maintenant et tu calmes le mental.',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _VoteButton(tipId: 'cinq_sens', count: _votes['cinq_sens'] ?? 0, onVote: _onVote),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FeelGoodCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Relaxation musculaire progressive (Jacobson)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text('🧘', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Technique reconnue en prise en charge de l\'anxiété : contracter puis relâcher chaque groupe musculaire pour repérer les tensions et induire la détente.',
                    style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Ordre classique : mains et avant-bras → bras → front → joues et mâchoire → cou et épaules → dos (si possible) → ventre → cuisses → mollets et pieds. '
                    'Pour chaque zone : contracte 5 à 10 secondes, puis relâche 20 à 30 secondes en ressentant la différence.',
                    style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  _VoteButton(tipId: 'jacobson', count: _votes['jacobson'] ?? 0, onVote: _onVote),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FeelGoodCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Lieu sûr (imagerie)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text('🏝️', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Technique utilisée en thérapie (stress, anxiété, préparation à des protocoles) : visualiser un endroit où tu te sens en sécurité et au calme (plage, forêt, chambre, souvenir réel ou imaginaire).',
                    style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Ferme les yeux, respire lentement, et détaille ce lieu (couleurs, sons, sensations). Reste-y mentalement 1 à 2 minutes. Tu peux y revenir dès que tu en as besoin.',
                    style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 14),
                  _VoteButton(tipId: 'lieu_sur', count: _votes['lieu_sur'] ?? 0, onVote: _onVote),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: 'S\'endormir'),
            FeelGoodCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Shuffle cognitif (tricot mental)',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text('🌙', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Pour éviter de ruminer au lit, occupe ton cerveau avec une tâche légère et répétitive qui ne demande pas d\'effort émotionnel :',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '• Choisis une catégorie (ex. : prénoms, pays, fruits, animaux, mots qui commencent par A…).',
                    style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• Énumère mentalement un mot par catégorie, sans te forcer. Pas besoin d\'être exhaustif ni rapide.',
                    style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '• Si tu perds le fil ou tu t\'endors, c\'est parfait. L\'objectif est de « décharger » la rumination.',
                    style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'En détournant l\'attention des pensées qui tournent, le shuffle cognitif favorise l\'endormissement sans effort.',
                    style: TextStyle(
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  _VoteButton(tipId: 'shuffle_cognitif', count: _votes['shuffle_cognitif'] ?? 0, onVote: _onVote),
                ],
              ),
            ),
            const SizedBox(height: 12),
            FeelGoodCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Hygiène du sommeil',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const SizedBox(width: 8),
                      Text('🛏️', style: Theme.of(context).textTheme.titleMedium),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Recommandations reconnues par les sociétés de sommeil et la Haute Autorité de santé pour favoriser un endormissement et un sommeil de qualité :',
                    style: TextStyle(fontSize: 14, height: 1.5, color: AppColors.textSecondary),
                  ),
                  const SizedBox(height: 10),
                  _Bullet(text: 'Horaires réguliers (se lever à heure fixe, même le week-end)'),
                  _Bullet(text: 'Chambre fraîche, calme et dédiée au sommeil'),
                  _Bullet(text: 'Éviter écrans et lumières vives 1 à 2 h avant le coucher'),
                  _Bullet(text: 'Limiter caféine et alcool en fin de journée'),
                  _Bullet(text: 'Activité physique dans la journée, pas en soirée tardive'),
                  _Bullet(text: 'Si tu ne t\'endors pas après 20 min, quitte le lit et reviens quand tu as sommeil'),
                  const SizedBox(height: 14),
                  _VoteButton(tipId: 'hygiene_sommeil', count: _votes['hygiene_sommeil'] ?? 0, onVote: _onVote),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: 'Écoute et aide'),
            _SupportTile(
              icon: Icons.phone_in_talk_rounded,
              title: 'SOS Amitié',
              subtitle: 'Écoute 24h/24, anonyme et gratuite',
              number: '09 72 39 40 50',
              gradient: AppColors.gradientSecondary,
            ),
            _SupportTile(
              icon: Icons.medical_services_rounded,
              title: 'Fil Santé Jeunes',
              subtitle: 'Écoute jeunes (12–25 ans)',
              number: '0 800 235 236',
              gradient: AppColors.gradientSecondary,
            ),
            _SupportTile(
              icon: Icons.psychology_rounded,
              title: 'Numéro national suicide (3114)',
              subtitle: 'Prévention du suicide, 24h/24',
              number: '3114',
              gradient: AppColors.gradientSecondary,
            ),
            const SizedBox(height: 16),
            _SectionTitle(title: 'Bienveillance'),
            FeelGoodCard(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Un pas à la fois',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Il est normal de ne pas aller bien parfois. Demander de l\'aide est un signe de courage. '
                    'Les émotions passent ; vous pouvez traverser ce moment. Prenez du temps pour vous, '
                    'entourez-vous de personnes bienveillantes si possible, et n\'hésitez pas à utiliser '
                    'les numéros ci-dessus si vous en avez besoin.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            _SectionTitle(title: 'Droits et mentions'),
            Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const LegalScreen()),
                ),
                borderRadius: BorderRadius.circular(20),
                child: FeelGoodCard(
                  margin: EdgeInsets.zero,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      const Icon(Icons.description_rounded, color: AppColors.primary, size: 28),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Mentions légales, CGU et droits',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.textPrimary,
                                  ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Exonération de responsabilité, RGPD, RGAA.',
                              style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Icon(Icons.arrow_forward_ios_rounded, size: 16, color: AppColors.textSecondary),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

class _VoteButton extends StatelessWidget {
  const _VoteButton({
    required this.tipId,
    required this.count,
    required this.onVote,
    this.light = false,
  });

  final String tipId;
  final int count;
  final Future<void> Function(String) onVote;
  final bool light;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: TextButton.icon(
        onPressed: () => onVote(tipId),
        icon: Icon(
          Icons.thumb_up_outlined,
          size: 18,
          color: light ? Colors.white.withValues(alpha: 0.9) : AppColors.primary,
        ),
        label: Text(
          count > 0 ? "Ça m'a aidé ($count)" : "Ça m'a aidé",
          style: TextStyle(
            fontSize: 13,
            color: light ? Colors.white.withValues(alpha: 0.9) : AppColors.primary,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _Bullet extends StatelessWidget {
  const _Bullet({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              fontSize: 14,
              height: 1.5,
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.5,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NumberedStep extends StatelessWidget {
  const _NumberedStep({required this.step, required this.text});

  final int step;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(11),
            ),
            alignment: Alignment.center,
            child: Text(
              '$step',
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 14,
                height: 1.4,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
      ),
    );
  }
}

class _SupportTile extends StatelessWidget {
  const _SupportTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.number,
    required this.gradient,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String number;
  final Gradient gradient;

  Future<void> _copyNumber(BuildContext context) async {
    final clean = number.replaceAll(' ', '');
    await Clipboard.setData(ClipboardData(text: clean));
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Numéro copié : $clean'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppColors.primary,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
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
              ),
              child: Icon(icon, color: AppColors.textOnPrimary, size: 26),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    number,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.primary,
                          letterSpacing: 1,
                        ),
                  ),
                ],
              ),
            ),
            FilledButton.tonal(
              onPressed: () => _copyNumber(context),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary.withValues(alpha: 0.12),
                foregroundColor: AppColors.primary,
              ),
              child: const Text('Copier'),
            ),
          ],
        ),
      ),
    );
  }
}
