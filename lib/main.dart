import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'theme/app_theme.dart';
import 'screens/home_shell.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await initializeDateFormatting('fr_FR', null);
  } catch (e, st) {
    debugPrint('intl initializeDateFormatting: $e\n$st');
  }

  // Lancer l’UI tout de suite : ne pas bloquer sur les notifications (plugin natif,
  // permissions, alarmes exactes Android, etc.).
  runApp(const MoodCastApp());

  scheduleMicrotask(() async {
    try {
      await NotificationService.updateRoutineReminders();
    } catch (e, st) {
      debugPrint('NotificationService.updateRoutineReminders: $e\n$st');
    }
  });
}

class MoodCastApp extends StatelessWidget {
  const MoodCastApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MoodCast — bien-être vocal',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      home: const HomeShell(),
    );
  }
}
