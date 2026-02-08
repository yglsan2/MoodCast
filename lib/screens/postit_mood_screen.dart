import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/emotions.dart';
import '../services/calendar_postit_service.dart';
import '../services/storage_service.dart';
import '../theme/app_colors.dart';
import '../widgets/gradient_app_bar.dart';
import '../widgets/feel_good_card.dart';

/// Permet d'ajouter un rappel émotionnel ou un mini-conseil dans l'agenda (Google, Outlook, ICS).
class PostitMoodScreen extends StatefulWidget {
  const PostitMoodScreen({super.key});

  @override
  State<PostitMoodScreen> createState() => _PostitMoodScreenState();
}

class _PostitMoodScreenState extends State<PostitMoodScreen> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  DateTime _eventDate = DateTime.now();
  TimeOfDay _eventTime = const TimeOfDay(hour: 12, minute: 0);
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSuggestedContent();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadSuggestedContent() async {
    final moodCasts = await StorageService.getMoodCasts();
    moodCasts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    if (mounted) {
      if (moodCasts.isNotEmpty) {
        final last = moodCasts.first;
        final shortText = last.podcastText.length > 120
            ? '${last.podcastText.substring(0, 117)}...'
            : last.podcastText;
        _titleController.text = 'MoodCast – ${Emotions.label(last.emotion)}';
        _descriptionController.text =
            'Ton mood du jour : ${Emotions.label(last.emotion)}.\n\n$shortText';
      } else {
        _titleController.text = 'MoodCast – Rappel bienveillant';
        _descriptionController.text =
            'Prends un moment pour toi. Respire. 💜\n\nConseil du jour : une pause de 2 minutes peut tout changer.';
      }
      setState(() => _loading = false);
    }
  }

  DateTime get _eventDateTime =>
      DateTime(_eventDate.year, _eventDate.month, _eventDate.day, _eventTime.hour, _eventTime.minute);

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _eventDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (date != null) setState(() => _eventDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _eventTime,
    );
    if (time != null) setState(() => _eventTime = time);
  }

  Future<void> _openGoogleCalendar() async {
    final uri = Uri.parse(
      CalendarPostitService.googleCalendarUrl(
        title: _titleController.text.trim().isEmpty ? 'MoodCast – Rappel' : _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        start: _eventDateTime,
      ),
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ouvre ton agenda Google pour enregistrer l\'événement.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _openOutlook() async {
    final uri = Uri.parse(
      CalendarPostitService.outlookUrl(
        title: _titleController.text.trim().isEmpty ? 'MoodCast – Rappel' : _titleController.text.trim(),
        description: _descriptionController.text.trim(),
        start: _eventDateTime,
      ),
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Ouvre Outlook pour enregistrer l\'événement.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _copyIcs() {
    final ics = CalendarPostitService.icsContent(
      title: _titleController.text.trim().isEmpty ? 'MoodCast – Rappel' : _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      start: _eventDateTime,
    );
    Clipboard.setData(ClipboardData(text: ics));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Événement copié en format ICS. Colle-le dans ton agenda (ex. Apple Calendar).'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  static String _formatDate(DateTime d) =>
      '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  static String _formatTime(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const GradientAppBar(
        title: '🟨 Post-it Mood',
        gradient: AppColors.gradientAccent,
      ),
      body: Container(
        color: AppColors.background,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                children: [
                  Text(
                    'Colle un rappel émotionnel ou un mini-conseil dans ton agenda. Un petit geste pour intégrer MoodCast dans ton quotidien.',
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
                          'Titre',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _titleController,
                          decoration: const InputDecoration(
                            hintText: 'MoodCast – Rappel bienveillant',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                          maxLines: 1,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Message ou conseil',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _descriptionController,
                          decoration: const InputDecoration(
                            hintText: 'Prends un moment pour toi...',
                            border: OutlineInputBorder(),
                            isDense: true,
                            alignLabelWithHint: true,
                          ),
                          maxLines: 4,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  FeelGoodCard(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Date et heure du rappel',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickDate,
                                icon: const Icon(Icons.calendar_today_rounded, size: 20),
                                label: Text(_formatDate(_eventDate)),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: _pickTime,
                                icon: const Icon(Icons.access_time_rounded, size: 20),
                                label: Text(_formatTime(_eventTime)),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    'Ajouter à mon agenda',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _openGoogleCalendar,
                    icon: const Icon(Icons.calendar_month_rounded, size: 22),
                    label: const Text('Google Calendar'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      backgroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _openOutlook,
                    icon: const Icon(Icons.email_rounded, size: 22),
                    label: const Text('Outlook'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  OutlinedButton.icon(
                    onPressed: _copyIcs,
                    icon: const Icon(Icons.copy_rounded, size: 22),
                    label: const Text('Copier (ICS) – Apple Calendar, etc.'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      foregroundColor: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
              ),
      ),
    );
  }
}
