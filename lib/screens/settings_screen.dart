import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';
import 'legal_screen.dart';
import 'mood_cast_plus_screen.dart';
import '../services/notification_service.dart';

/// Paramètres : confidentialité, préférences, à propos.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const String _keySoundEnabled = 'settings_sound_enabled';
  bool _soundEnabled = true;
  final _alertNameController = TextEditingController();
  final _alertPhoneController = TextEditingController();
  bool _moodSafeIncludeMood = false;
  final _moodSafeCodeController = TextEditingController();
  final _moodSafeFakeCodeController = TextEditingController();
  final _moodSafePhone2Controller = TextEditingController();
  final _moodSafePhone3Controller = TextEditingController();
  final _userNameController = TextEditingController();
  final _moodPulsePhoneController = TextEditingController();
  bool _routineReminderMorning = false;
  String _routineReminderMorningTime = '08:00';
  bool _routineReminderEvening = false;
  String _routineReminderEveningTime = '20:00';

  @override
  void initState() {
    super.initState();
    _loadPrefs();
  }

  @override
  void dispose() {
    _alertNameController.dispose();
    _alertPhoneController.dispose();
    _moodSafeCodeController.dispose();
    _moodSafeFakeCodeController.dispose();
    _moodSafePhone2Controller.dispose();
    _moodSafePhone3Controller.dispose();
    _userNameController.dispose();
    _moodPulsePhoneController.dispose();
    super.dispose();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final userName = await StorageService.getUserName();
    _userNameController.text = userName ?? '';
    final name = await StorageService.getAlertContactName();
    final phone = await StorageService.getAlertContactPhone();
    _alertNameController.text = name ?? '';
    _alertPhoneController.text = phone ?? '';
    _moodSafeIncludeMood = await StorageService.getMoodSafeIncludeMood();
    _moodSafeCodeController.text = await StorageService.getMoodSafeCode() ?? '';
    _moodSafeFakeCodeController.text = await StorageService.getMoodSafeFakeCode() ?? '';
    _moodSafePhone2Controller.text = await StorageService.getMoodSafePhone2() ?? '';
    _moodSafePhone3Controller.text = await StorageService.getMoodSafePhone3() ?? '';
    _moodPulsePhoneController.text = await StorageService.getMoodPulsePhone() ?? '';
    _routineReminderMorning = await StorageService.getRoutineReminderMorningEnabled();
    _routineReminderMorningTime = await StorageService.getRoutineReminderMorningTime();
    _routineReminderEvening = await StorageService.getRoutineReminderEveningEnabled();
    _routineReminderEveningTime = await StorageService.getRoutineReminderEveningTime();
    setState(() {
      _soundEnabled = prefs.getBool(_keySoundEnabled) ?? true;
    });
  }

  Future<void> _saveAlertContact() async {
    await StorageService.setAlertContact(
      name: _alertNameController.text.trim().isEmpty ? null : _alertNameController.text.trim(),
      phone: _alertPhoneController.text.trim().isEmpty ? null : _alertPhoneController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Proche à alerter enregistré.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _setSoundEnabled(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keySoundEnabled, value);
    setState(() => _soundEnabled = value);
  }

  Future<void> _saveMoodSafeOptions() async {
    final code = _moodSafeCodeController.text.trim();
    final fake = _moodSafeFakeCodeController.text.trim();
    await StorageService.setMoodSafeCode(code.isEmpty ? null : code);
    await StorageService.setMoodSafeFakeCode(fake.isEmpty ? null : fake);
    await StorageService.setMoodSafePhones(
      phone2: _moodSafePhone2Controller.text.trim(),
      phone3: _moodSafePhone3Controller.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Options MoodSafe enregistrées.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _saveMoodPulse() async {
    await StorageService.setMoodPulsePhone(
      _moodPulsePhoneController.text.trim().isEmpty
          ? null
          : _moodPulsePhoneController.text.trim(),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Contact MoodPulse enregistré.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _exportData(BuildContext context) async {
    try {
      final moodCasts = await StorageService.getMoodCasts();
      final payload = {
        'exportDate': DateTime.now().toIso8601String(),
        'application': 'MoodCast & WorldFlow',
        'moodCasts': moodCasts.map((e) => e.toJson()).toList(),
      };
      final dir = await getTemporaryDirectory();
      final name = 'moodcast_export_${DateTime.now().toIso8601String().replaceAll(':', '-').split('.').first}.json';
      final file = File('${dir.path}/$name');
      await file.writeAsString(const JsonEncoder.withIndent('  ').convert(payload));
      await Share.shareXFiles(
        [XFile(file.path)],
        subject: 'Export MoodCast (RGPD)',
        text: 'Export de mes données MoodCast – droit à la portabilité.',
      );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Export prêt : partagez ou enregistrez le fichier.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de l\'export : $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: '⚙️ Paramètres',
        gradient: AppColors.gradientSecondary,
      ),
      body: Container(
        color: AppColors.background,
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
          children: [
            Text(
              'Préférences',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 10),
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: ListTile(
                leading: Icon(Icons.workspace_premium_rounded, color: AppColors.primary),
                title: const Text('MoodCast+ & abonnement'),
                subtitle: const Text('Essai, codes promo, futur paiement sur les stores'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const MoodCastPlusScreen()),
                  );
                },
              ),
            ),
            const SizedBox(height: 8),
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: SwitchListTile(
                title: const Text('Son des podcasts'),
                subtitle: const Text('Lecture vocale des avis MoodCast'),
                value: _soundEnabled,
                onChanged: _setSoundEnabled,
                activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                activeThumbColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 8),
            FutureBuilder<bool>(
              future: StorageService.getRiskDaysReminderEnabled(),
              builder: (context, snap) {
                return FeelGoodCard(
                  margin: EdgeInsets.zero,
                  padding: EdgeInsets.zero,
                  child: SwitchListTile(
                    title: const Text('Rappel les jours à risque'),
                    subtitle: const Text('Te rappeler ton rituel les jours où tu es souvent en baisse (Stats)'),
                    value: snap.data ?? false,
                    onChanged: (v) async {
                      await StorageService.setRiskDaysReminderEnabled(v);
                      await NotificationService.updateRiskDaysReminders();
                      if (mounted) setState(() {});
                    },
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                    activeThumbColor: AppColors.primary,
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(20),
              child: TextField(
                controller: _userNameController,
                decoration: const InputDecoration(
                  labelText: 'Ton prénom (pour MoodRoutine)',
                  hintText: 'Ex. Marie',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                textCapitalization: TextCapitalization.words,
                onSubmitted: (_) async {
                  final messenger = ScaffoldMessenger.of(context);
                  await StorageService.setUserName(_userNameController.text.trim());
                  if (!mounted) return;
                  messenger.showSnackBar(
                    const SnackBar(content: Text('Prénom enregistré.'), behavior: SnackBarBehavior.floating),
                  );
                },
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Rappels MoodRoutine',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Reçois une notification pour ne pas oublier ton rituel matin ou soir.',
              style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Rappel rituel matin'),
                    subtitle: Text('À $_routineReminderMorningTime'),
                    value: _routineReminderMorning,
                    onChanged: (v) async {
                      await StorageService.setRoutineReminderMorningEnabled(v);
                      await NotificationService.updateRoutineReminders();
                      setState(() => _routineReminderMorning = v);
                    },
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                    activeThumbColor: AppColors.primary,
                  ),
                  ListTile(
                    title: const Text('Heure du rappel matin'),
                    trailing: TextButton(
                      onPressed: () async {
                        final parts = _routineReminderMorningTime.split(':');
                        final initial = TimeOfDay(
                          hour: parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8,
                          minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
                        );
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: initial,
                        );
                        if (picked != null) {
                          final time = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          await StorageService.setRoutineReminderMorningTime(time);
                          await NotificationService.updateRoutineReminders();
                          setState(() => _routineReminderMorningTime = time);
                        }
                      },
                      child: Text(_routineReminderMorningTime),
                    ),
                  ),
                  const Divider(height: 1),
                  SwitchListTile(
                    title: const Text('Rappel rituel soir'),
                    subtitle: Text('À $_routineReminderEveningTime'),
                    value: _routineReminderEvening,
                    onChanged: (v) async {
                      await StorageService.setRoutineReminderEveningEnabled(v);
                      await NotificationService.updateRoutineReminders();
                      setState(() => _routineReminderEvening = v);
                    },
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                    activeThumbColor: AppColors.primary,
                  ),
                  ListTile(
                    title: const Text('Heure du rappel soir'),
                    trailing: TextButton(
                      onPressed: () async {
                        final parts = _routineReminderEveningTime.split(':');
                        final initial = TimeOfDay(
                          hour: parts.isNotEmpty ? int.tryParse(parts[0]) ?? 20 : 20,
                          minute: parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0,
                        );
                        final picked = await showTimePicker(
                          context: context,
                          initialTime: initial,
                        );
                        if (picked != null) {
                          final time = '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';
                          await StorageService.setRoutineReminderEveningTime(time);
                          await NotificationService.updateRoutineReminders();
                          setState(() => _routineReminderEveningTime = time);
                        }
                      },
                      child: Text(_routineReminderEveningTime),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Alerte sécurité',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'En cas de danger, le bouton rouge « Alerte proche » (visible partout dans l\'app) ouvre directement un SMS à ce contact avec votre position. Un seul geste.',
              style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _alertNameController,
                    decoration: const InputDecoration(
                      labelText: 'Nom du proche (optionnel)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    textCapitalization: TextCapitalization.words,
                    onSubmitted: (_) => _saveAlertContact(),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _alertPhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone (ex. +33 6 12 34 56 78)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.phone,
                    onSubmitted: (_) => _saveAlertContact(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saveAlertContact,
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: const Text('Enregistrer'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'MoodSafe – Alerte danger',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'Maintenez le bouton « Alerte proche » 2 secondes pour envoyer un message d\'alerte danger à vos contacts de confiance (position + optionnel dernier mood). '
              'Contact 1 = celui ci-dessus. Vous pouvez ajouter 2 autres numéros ci-dessous.',
              style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SwitchListTile(
                    title: const Text('Inclure mon dernier mood dans l\'alerte'),
                    value: _moodSafeIncludeMood,
                    onChanged: (v) async {
                      await StorageService.setMoodSafeIncludeMood(v);
                      setState(() => _moodSafeIncludeMood = v);
                    },
                    activeTrackColor: AppColors.primary.withValues(alpha: 0.5),
                    activeThumbColor: AppColors.primary,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _moodSafeCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Code de désactivation (4 chiffres)',
                      hintText: 'ex. 4321',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    onSubmitted: (_) => _saveMoodSafeOptions(),
                  ),
                  TextField(
                    controller: _moodSafeFakeCodeController,
                    decoration: const InputDecoration(
                      labelText: 'Faux code (semble annuler mais alerte continue)',
                      hintText: 'ex. 4333',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.number,
                    maxLength: 4,
                    onSubmitted: (_) => _saveMoodSafeOptions(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _moodSafePhone2Controller,
                    decoration: const InputDecoration(
                      labelText: 'Contact 2 – Numéro (optionnel)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.phone,
                    onSubmitted: (_) => _saveMoodSafeOptions(),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _moodSafePhone3Controller,
                    decoration: const InputDecoration(
                      labelText: 'Contact 3 – Numéro (optionnel)',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.phone,
                    onSubmitted: (_) => _saveMoodSafeOptions(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saveMoodSafeOptions,
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: const Text('Enregistrer MoodSafe'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'MoodPulse – Prévenir un proche',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 6),
            Text(
              'En cas de journée difficile, tu peux envoyer en un tap un message à ce proche (partenaire, ami) pour lui dire que tu as besoin d\'écoute.',
              style: TextStyle(fontSize: 13, height: 1.4, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 10),
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _moodPulsePhoneController,
                    decoration: const InputDecoration(
                      labelText: 'Numéro du proche (MoodPulse)',
                      hintText: 'ex. +33 6 12 34 56 78',
                      border: OutlineInputBorder(),
                      isDense: true,
                    ),
                    keyboardType: TextInputType.phone,
                    onSubmitted: (_) => _saveMoodPulse(),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _saveMoodPulse,
                    icon: const Icon(Icons.save_rounded, size: 20),
                    label: const Text('Enregistrer'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Confidentialité et données',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 10),
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Vos données restent sur votre appareil',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'MoodCast enregistre vos MoodCasts (humeur, avis, date) uniquement sur votre téléphone ou ordinateur. '
                    'Aucune donnée n\'est envoyée à un serveur tiers sans votre accord. '
                    'Les fonctionnalités Horoscope, Biscuit chinois et prédictions sont calculées localement. '
                    'Pour vos droits (accès, rectification, effacement, RGPD, RGAA), voir les mentions légales ci-dessous.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Si vous utilisez l\'analyse de voix (MoodCast), l\'enregistrement peut être traité par un service configuré par l\'application (backend optionnel). Consultez les conditions d\'utilisation si vous vous connectez à un compte.',
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
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Mentions légales, CGU et droits',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Exonération de responsabilité, RGPD, RGAA, propriété intellectuelle.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const LegalScreen()),
                      );
                    },
                    icon: const Icon(Icons.description_rounded, size: 20),
                    label: const Text('Lire les mentions légales et droits'),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: () => _exportData(context),
                    icon: const Icon(Icons.download_rounded, size: 20),
                    label: const Text('Exporter mes données (portabilité RGPD)'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'À propos',
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
            ),
            const SizedBox(height: 10),
            FeelGoodCard(
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'MoodCast & WorldFlow',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                      ),
                      const Spacer(),
                      Text(
                        'v1.0.0',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Créé par DesertYGL · Gratuit avec pubs, option payante',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Application feel-good : enregistrement d\'humeur, journal, statistiques, horoscope européen et chinois, biscuit chinois. '
                    'Conçue pour vous accompagner au quotidien avec bienveillance.',
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
