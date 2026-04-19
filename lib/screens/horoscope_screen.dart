import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';
import '../services/horoscope_service.dart';
import '../services/storage_service.dart';

class HoroscopeScreen extends StatefulWidget {
  const HoroscopeScreen({super.key});

  @override
  State<HoroscopeScreen> createState() => _HoroscopeScreenState();
}

class _HoroscopeScreenState extends State<HoroscopeScreen> with SingleTickerProviderStateMixin {
  DateTime? _birthDate;
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadBirthDate();
  }

  Future<void> _loadBirthDate() async {
    final date = await StorageService.getBirthDate();
    if (mounted) {
      setState(() => _birthDate = date);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ZodiacSign get _sign =>
      _birthDate != null
          ? HoroscopeService.getSignForDate(_birthDate!)
          : HoroscopeService.getSignForDate(DateTime.now());
  EuropeanDecan? get _decan =>
      _birthDate != null ? HoroscopeService.getDecanForDate(_birthDate!) : null;
  ChineseSign? get _chinese =>
      _birthDate != null ? HoroscopeService.getChineseZodiacForDate(_birthDate!) : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: '🔮 Horoscope',
        gradient: AppColors.gradientAccent,
      ),
      body: Container(
        color: AppColors.background,
        child: Column(
          children: [
            _buildBirthDateCard(),
            TabBar(
              controller: _tabController,
              labelColor: AppColors.primary,
              unselectedLabelColor: AppColors.textSecondary,
              indicatorColor: AppColors.primary,
              tabs: const [
                Tab(text: 'Jour'),
                Tab(text: 'Semaine'),
                Tab(text: 'Année'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDayTab(),
                  _buildTabPage(
                    euro: HoroscopeService.weeklyHoroscope(
                      _sign,
                      _startOfWeek(DateTime.now()),
                      decan: _decan,
                    ),
                    chinese: _chinese != null
                        ? HoroscopeService.weeklyHoroscopeChinese(
                            _chinese!,
                            _startOfWeek(DateTime.now()),
                          )
                        : null,
                  ),
                  _buildTabPage(
                    euro: HoroscopeService.yearlyHoroscope(
                      _sign,
                      DateTime.now().year,
                      decan: _decan,
                    ),
                    chinese: _chinese != null
                        ? HoroscopeService.yearlyHoroscopeChinese(
                            _chinese!,
                            DateTime.now().year,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  DateTime _startOfWeek(DateTime d) {
    return DateTime(d.year, d.month, d.day - (d.weekday - 1));
  }

  static const Map<String, String> _themeEmoji = {
    'amour': '❤️',
    'travail': '💼',
    'sante': '🌿',
    'chance': '🍀',
  };

  static const Map<String, String> _themeTitle = {
    'amour': 'Amour',
    'travail': 'Travail',
    'sante': 'Santé',
    'chance': 'Chance',
  };

  Widget _buildDayTab() {
    final now = DateTime.now();
    final euro = HoroscopeService.dailyHoroscope(_sign, now, decan: _decan);
    final chinese = _chinese != null
        ? HoroscopeService.dailyHoroscopeChinese(_chinese!, now)
        : null;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeelGoodCard(
            gradient: AppColors.gradientCalm,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_sign.symbol} ${_sign.name}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (_decan != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '· ${_decan!.decanNumber}ᵉ décan (${_decan!.ruler})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Général',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  euro,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          if (chinese != null) ...[
            const SizedBox(height: 12),
            FeelGoodCard(
              gradient: AppColors.gradientWarm,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_chinese!.animal} · ${_chinese!.element}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    chinese,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          Text(
            'Par thème',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 12),
          ...HoroscopeService.dailyThemes.map((theme) {
            final text = HoroscopeService.dailyHoroscopeByTheme(
              _sign,
              now,
              theme,
              decan: _decan,
            );
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: FeelGoodCard(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _themeEmoji[theme] ?? '✨',
                          style: const TextStyle(fontSize: 22),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _themeTitle[theme] ?? theme,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      text,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  static const List<String> _monthNames = [
    'Janvier', 'Février', 'Mars', 'Avril', 'Mai', 'Juin',
    'Juillet', 'Août', 'Septembre', 'Octobre', 'Novembre', 'Décembre',
  ];

  int _daysInMonth(int year, int month) {
    return DateTime(year, month + 1, 0).day;
  }

  Future<void> _applyBirthDate(DateTime date) async {
    if (date.isAfter(DateTime.now())) return;
    setState(() => _birthDate = date);
    await StorageService.setBirthDate(date);
  }

  Widget _buildBirthDateCard() {
    final now = DateTime.now();
    final initial = _birthDate ?? DateTime(now.year - 25, 6, 15);
    int day = initial.day;
    int month = initial.month;
    int year = initial.year;
    if (_birthDate != null) {
      day = _birthDate!.day;
      month = _birthDate!.month;
      year = _birthDate!.year;
    }
    final maxDay = _daysInMonth(year, month);
    if (day > maxDay) day = maxDay;

    return FeelGoodCard(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Date de naissance',
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Choisis le jour, le mois et l\'année — c\'est enregistré automatiquement.',
            style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: _birthDayDropdown(
                  value: day,
                  maxDay: maxDay,
                  year: year,
                  month: month,
                  onChanged: (d) => _applyBirthDate(DateTime(year, month, d!)),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _birthMonthDropdown(
                  value: month,
                  onChanged: (m) {
                    final d = day <= _daysInMonth(year, m!) ? day : _daysInMonth(year, m);
                    _applyBirthDate(DateTime(year, m, d));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 1,
                child: _birthYearDropdown(
                  value: year,
                  onChanged: (y) {
                    final d = day <= _daysInMonth(y!, month) ? day : _daysInMonth(y, month);
                    _applyBirthDate(DateTime(y, month, d));
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () async {
              final date = await showDatePicker(
                context: context,
                initialDate: _birthDate ?? DateTime(now.year - 25, 6, 15),
                firstDate: DateTime(1900),
                lastDate: now,
              );
              if (date != null) await _applyBirthDate(date);
            },
            icon: const Icon(Icons.calendar_month_rounded, size: 18),
            label: const Text('Ou ouvrir le calendrier'),
            style: TextButton.styleFrom(
              foregroundColor: AppColors.textSecondary,
            ),
          ),
          if (_birthDate != null) ...[
            const SizedBox(height: 12),
            _buildProfileLine(
              'Occidental',
              '${_sign.symbol} ${_sign.name} · ${_sign.element}'
                  '${_decan != null ? ' · ${_decan!.decanNumber}ᵉ décan (${_decan!.ruler})' : ''}',
            ),
            const SizedBox(height: 6),
            _buildProfileLine(
              'Chinois',
              '${_chinese!.animal} · ${_chinese!.element}',
            ),
          ],
        ],
      ),
    );
  }

  Widget _birthDayDropdown({
    required int value,
    required int maxDay,
    required int year,
    required int month,
    required ValueChanged<int?> onChanged,
  }) {
    final dayVal = value.clamp(1, maxDay);
    return DropdownButtonFormField<int>(
      key: ValueKey<String>('birth-day-$year-$month-$maxDay-$dayVal'),
      initialValue: dayVal,
      decoration: const InputDecoration(
        labelText: 'Jour',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: List.generate(maxDay, (i) => i + 1).map((d) => DropdownMenuItem(value: d, child: Text('$d'))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _birthMonthDropdown({
    required int value,
    required ValueChanged<int?> onChanged,
  }) {
    return DropdownButtonFormField<int>(
      key: ValueKey<String>('birth-month-$value'),
      initialValue: value,
      decoration: const InputDecoration(
        labelText: 'Mois',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: List.generate(12, (i) => i + 1).map((m) => DropdownMenuItem(
        value: m,
        child: Text(_monthNames[m - 1], overflow: TextOverflow.ellipsis),
      )).toList(),
      onChanged: onChanged,
    );
  }

  Widget _birthYearDropdown({
    required int value,
    required ValueChanged<int?> onChanged,
  }) {
    final now = DateTime.now();
    final years = List.generate(now.year - 1900 + 1, (i) => now.year - i);
    final yearVal = years.contains(value) ? value : now.year - 25;
    return DropdownButtonFormField<int>(
      key: ValueKey<String>('birth-year-$yearVal'),
      initialValue: yearVal,
      decoration: const InputDecoration(
        labelText: 'Année',
        isDense: true,
        contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      items: years.map((y) => DropdownMenuItem(value: y, child: Text('$y'))).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildProfileLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 82,
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppColors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTabPage({required String euro, String? chinese}) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          FeelGoodCard(
            gradient: AppColors.gradientCalm,
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      '${_sign.symbol} ${_sign.name}',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                    if (_decan != null) ...[
                      const SizedBox(width: 8),
                      Text(
                        '· ${_decan!.decanNumber}ᵉ décan (${_decan!.ruler})',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 14),
                Text(
                  euro,
                  style: TextStyle(
                    fontSize: 15,
                    height: 1.55,
                    color: Colors.white.withValues(alpha: 0.95),
                  ),
                ),
              ],
            ),
          ),
          if (chinese != null) ...[
            const SizedBox(height: 12),
            FeelGoodCard(
              gradient: AppColors.gradientWarm,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${_chinese!.animal} · ${_chinese!.element}',
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 14),
                  Text(
                    chinese,
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.55,
                      color: Colors.white.withValues(alpha: 0.95),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
