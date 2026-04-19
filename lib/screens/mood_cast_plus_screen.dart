import 'package:flutter/material.dart';

import '../services/premium_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/feel_good_card.dart';
import '../widgets/gradient_app_bar.dart';

/// Offre MoodCast+ : positionnement produit, essai, codes — prêt pour facturation stores.
class MoodCastPlusScreen extends StatefulWidget {
  const MoodCastPlusScreen({super.key});

  @override
  State<MoodCastPlusScreen> createState() => _MoodCastPlusScreenState();
}

class _MoodCastPlusScreenState extends State<MoodCastPlusScreen> {
  bool _loading = true;
  bool _premium = false;
  bool _lifetime = false;
  DateTime? _until;
  bool _trialConsumed = false;
  final _codeController = TextEditingController();
  String? _message;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() => _loading = true);
    final p = await PremiumService.isPremium();
    final u = await StorageService.getPremiumUntil();
    final l = await StorageService.isLifetimePremium();
    final t = await StorageService.hasConsumedFreeTrial();
    if (!mounted) return;
    setState(() {
      _premium = p;
      _until = u;
      _lifetime = l;
      _trialConsumed = t;
      _loading = false;
      _message = null;
    });
  }

  Future<void> _trial() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final err = await PremiumService.startFreeTrialIfEligible();
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      setState(() => _message = err);
    } else {
      setState(() => _message = 'Les 7 jours MoodCast+ sont activés. Profite des styles Poésie & Énergie et du plan hebdo approfondi.');
      await _refresh();
    }
  }

  Future<void> _redeem() async {
    setState(() {
      _busy = true;
      _message = null;
    });
    final err = await PremiumService.redeemCode(_codeController.text);
    if (!mounted) return;
    setState(() => _busy = false);
    if (err != null) {
      setState(() => _message = err);
    } else {
      _codeController.clear();
      setState(() => _message = 'Code appliqué. Merci de soutenir MoodCast.');
      await _refresh();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: const GradientAppBar(
        title: '✨ MoodCast+',
        gradient: AppColors.gradientAccent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (_premium) _buildActiveCard(),
                  if (!_premium) _buildPitchCard(),
                  const SizedBox(height: 16),
                  FeelGoodCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Pourquoi cette offre (analyse produit)',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          '• Les personnes qui cherchent du bien-être vocal veulent surtout de la continuité : '
                          'MoodCast+ verrouille des « bonus » qui rendent l’habitude plus riche (styles de texte, bilan hebdo plus profond).\n\n'
                          '• Le modèle le plus naturel ici est l’abonnement doux (4,99–6,99 €/mois) : marge récurrente, peu de friction une fois l’habitude prise.\n\n'
                          '• Les codes promo servent aux lancements Instagram/TikTok, partenariats coachs, ou ambassadrices — sans bricoler un prix par utilisateur.\n\n'
                          '• Quand tu brancheras App Store / Play : garde l’essai 7 jours + ces codes comme équivalent « coupon » côté serveur.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.45,
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!_lifetime && !_premium) ...[
                    FilledButton.icon(
                      onPressed: _busy || _trialConsumed ? null : _trial,
                      icon: const Icon(Icons.card_giftcard_rounded),
                      label: Text(_trialConsumed ? 'Essai déjà utilisé' : '7 jours offerts sur cet appareil'),
                    ),
                    if (_trialConsumed) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Tu peux encore activer un accès avec un code ci-dessous, ou attendre l’abonnement sur les stores.',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary.withValues(alpha: 0.9)),
                      ),
                    ],
                  ],
                  if (!_lifetime) ...[
                    const SizedBox(height: 20),
                    Text(
                      'Code promo',
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        hintText: 'Ex. MOODPLUS7, BIENVENUE30…',
                        border: OutlineInputBorder(),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: _busy ? null : _redeem,
                      icon: const Icon(Icons.key_rounded),
                      label: const Text('Activer le code'),
                    ),
                  ],
                  if (_message != null) ...[
                    const SizedBox(height: 16),
                    FeelGoodCard(
                      margin: EdgeInsets.zero,
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        _message!,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          color: _message!.contains('inconnu') || _message!.contains('déjà')
                              ? AppColors.error
                              : AppColors.success,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    'Prix indicatif après intégration stores : 4,99 € / mois (annulable). Rien n’est encore débité dans cette version.',
                    style: TextStyle(fontSize: 11, color: AppColors.textSecondary.withValues(alpha: 0.85)),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildActiveCard() {
    if (_lifetime) {
      return FeelGoodCard(
        gradient: AppColors.gradientPrimary,
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: AppColors.textOnPrimary, size: 36),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                'MoodCast+ illimité — merci infiniment pour ta confiance.',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      color: AppColors.textOnPrimary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ),
          ],
        ),
      );
    }
    final u = _until;
    final end = u != null
        ? '${u.day.toString().padLeft(2, '0')}/${u.month.toString().padLeft(2, '0')}/${u.year}'
        : '';
    return FeelGoodCard(
      gradient: AppColors.gradientPrimary,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          const Icon(Icons.auto_awesome, color: AppColors.textOnPrimary, size: 34),
          const SizedBox(width: 14),
          Expanded(
            child: Text(
              'MoodCast+ actif jusqu’au $end.',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: AppColors.textOnPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPitchCard() {
    return FeelGoodCard(
      gradient: AppColors.gradientAccent,
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ce que MoodCast+ débloque',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 14),
          _benefit(Icons.palette_rounded, 'Styles podcast « Poésie » & « Énergie » — textes plus travaillés.'),
          _benefit(Icons.auto_graph_rounded, 'Plan d’action hebdo personnalisé dans le résumé de semaine.'),
          _benefit(Icons.favorite_rounded, 'Soutient le développement : nouvelles voix, meilleure analyse, plus de douceur dans l’app.'),
        ],
      ),
    );
  }

  Widget _benefit(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, height: 1.4, color: AppColors.textSecondary),
            ),
          ),
        ],
      ),
    );
  }
}
