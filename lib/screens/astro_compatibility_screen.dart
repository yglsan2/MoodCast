import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/horoscope_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';

/// Compare la compatibilité émotionnelle / astro entre deux profils (dates de naissance).
class AstroCompatibilityScreen extends StatefulWidget {
  const AstroCompatibilityScreen({super.key});

  @override
  State<AstroCompatibilityScreen> createState() => _AstroCompatibilityScreenState();
}

class _AstroCompatibilityScreenState extends State<AstroCompatibilityScreen> {
  DateTime? _date1;
  DateTime? _date2;
  bool _loading = true;
  int? _score;
  String? _message;

  @override
  void initState() {
    super.initState();
    _loadMyDate();
  }

  Future<void> _loadMyDate() async {
    final date = await StorageService.getBirthDate();
    if (mounted) {
      setState(() {
        _date1 = date;
        _loading = false;
      });
    }
  }

  Future<void> _pickDate1() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date1 ?? DateTime(2000, 6, 15),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) {
      setState(() => _date1 = date);
      await StorageService.setBirthDate(date);
    }
  }

  Future<void> _pickDate2() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _date2 ?? DateTime(1995, 3, 10),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (date != null) setState(() => _date2 = date);
  }

  void _compare() {
    if (_date1 == null || _date2 == null) return;
    final score = HoroscopeService.compatibilityScore(_date1!, _date2!);
    final message = HoroscopeService.compatibilityMessage(_date1!, _date2!);
    setState(() {
      _score = score;
      _message = message;
    });
  }

  static String _formatDate(DateTime d) => DateFormat('dd/MM/yyyy').format(d);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: '💕 AstroCompatibilité',
        gradient: AppColors.gradientPrimary,
      ),
      body: Container(
        color: AppColors.background,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  Text(
                    'Compare ta compatibilité émotionnelle et astrologique avec un proche, un crush ou ton partenaire.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.45,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  FeelGoodCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Toi',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _pickDate1,
                          icon: const Icon(Icons.cake_rounded, size: 20),
                          label: Text(
                            _date1 != null ? 'Né(e) le ${_formatDate(_date1!)}' : 'Choisir ma date de naissance',
                          ),
                        ),
                        if (_date1 != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${HoroscopeService.getSignForDate(_date1!).symbol} ${HoroscopeService.getSignForDate(_date1!).name} · ${HoroscopeService.getChineseZodiacForDate(_date1!).animal} ${HoroscopeService.getChineseZodiacForDate(_date1!).element}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FeelGoodCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Proche · crush · partenaire',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _pickDate2,
                          icon: const Icon(Icons.favorite_rounded, size: 20),
                          label: Text(
                            _date2 != null ? 'Né(e) le ${_formatDate(_date2!)}' : 'Choisir sa date de naissance',
                          ),
                        ),
                        if (_date2 != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: Text(
                              '${HoroscopeService.getSignForDate(_date2!).symbol} ${HoroscopeService.getSignForDate(_date2!).name} · ${HoroscopeService.getChineseZodiacForDate(_date2!).animal} ${HoroscopeService.getChineseZodiacForDate(_date2!).element}',
                              style: TextStyle(
                                fontSize: 13,
                                color: AppColors.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: (_date1 != null && _date2 != null) ? _compare : null,
                    icon: const Icon(Icons.auto_awesome_rounded, size: 22),
                    label: const Text('Voir notre compatibilité'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                  if (_score != null && _message != null) ...[
                    const SizedBox(height: 28),
                    FeelGoodCard(
                      gradient: _score! >= 65
                          ? AppColors.gradientPrimary
                          : _score! >= 50
                              ? AppColors.gradientSecondary
                              : AppColors.gradientAccent,
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Text(
                            '$_score %',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              height: 1,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Compatibilité MoodCast',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.95),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _message!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }
}
