import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../models/emotions.dart';
import '../models/mood_cast.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';

/// Format de date en français (nécessite initializeDateFormatting('fr_FR') dans main).
String _formatDate(DateTime d) {
  try {
    return DateFormat('dd MMM yyyy • HH:mm', 'fr_FR').format(d);
  } catch (_) {
    return DateFormat('dd/MM/yyyy HH:mm').format(d);
  }
}

class JournalScreen extends StatefulWidget {
  const JournalScreen({super.key});

  @override
  State<JournalScreen> createState() => _JournalScreenState();
}

class _JournalScreenState extends State<JournalScreen> {
  List<MoodCast> _list = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final list = await StorageService.getMoodCasts();
    list.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (mounted) {
      setState(() {
        _list = list;
        _loading = false;
      });
    }
  }

  static String _emotionEmoji(String e) {
    const m = {
      'joie': '😊', 'sérénité': '😌', 'enthousiasme': '🤩', 'gratitude': '🙏',
      'stress': '😰', 'anxiété': '😟', 'fatigue': '😴', 'motivation': '💪',
      'tristesse': '😢', 'mélancolie': '🌧️', 'colere': '😠', 'irritation': '😤',
      'doute': '🤔', 'espoir': '🌟', 'amour': '❤️',
    };
    return m[e] ?? '😐';
  }

  Future<void> _confirmDelete(MoodCast item) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Supprimer'),
        content: const Text('Voulez-vous vraiment supprimer ce MoodCast ?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Supprimer')),
        ],
      ),
    );
    if (ok == true) {
      await StorageService.deleteMoodCast(item.id);
      _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: GradientAppBar(
        title: '📖 Mon Journal',
        gradient: AppColors.gradientSecondary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
            tooltip: 'Actualiser',
          ),
        ],
      ),
      body: Container(
        color: Colors.transparent,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : _list.isEmpty
                ? _buildEmptyState()
                : RefreshIndicator(
                    onRefresh: _load,
                    color: AppColors.primary,
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                      itemCount: _list.length,
                      itemBuilder: (context, i) {
                        final item = _list[i];
                        return _buildJournalCard(item);
                      },
                    ),
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: FeelGoodCard(
        margin: const EdgeInsets.symmetric(horizontal: 24),
        gradient: AppColors.gradientCalm,
        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('📔', style: TextStyle(fontSize: 44, height: 1)),
            const SizedBox(height: 12),
            Text(
              'Ton journal t’attend',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                    letterSpacing: -0.2,
                  ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Chaque MoodCast que tu enregistres dans l’onglet 🎙️ MoodCast apparaît ici, avec la date et l’humeur. C’est ton fil personnel de bienveillance.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 14, height: 1.5),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            Text(
              '👉 Onglet « MoodCast », tout à gauche en bas.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.primary,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildJournalCard(MoodCast item) {
    final color = AppColors.emotionColor(item.emotion);
    return FeelGoodCard(
      margin: const EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              context: context,
              backgroundColor: Colors.transparent,
              builder: (ctx) => Container(
                padding: const EdgeInsets.all(24),
                decoration: const BoxDecoration(
                  color: AppColors.cardBackground,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Text(
                            Emotions.label(item.emotion),
                            style: TextStyle(color: color, fontWeight: FontWeight.w600),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          _formatDate(item.timestamp),
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(item.podcastText, style: const TextStyle(fontSize: 15, height: 1.5)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        TextButton.icon(
                          onPressed: () {
                            Clipboard.setData(ClipboardData(text: item.podcastText));
                            Navigator.pop(ctx);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Avis copié dans le presse-papiers'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.copy_rounded, size: 18),
                          label: const Text('Copier l\'avis'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Center(
                    child: Text(_emotionEmoji(item.emotion), style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        Emotions.label(item.emotion),
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: color,
                          fontSize: 16,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatDate(item.timestamp),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  onPressed: () => _confirmDelete(item),
                  tooltip: 'Supprimer',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
