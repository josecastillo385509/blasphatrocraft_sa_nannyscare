import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'theme/app_theme.dart';
import 'services/storage_service.dart';
import 'services/security_service.dart';
import 'services/auth_service.dart';
import 'services/data_service.dart';
import 'services/cita_service.dart';
import 'services/notification_service.dart';
import 'services/resena_service.dart';
import 'services/reminder_service.dart';
import 'screens/splash_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('es_MX', null);

  final security = SecurityService();
  final storage = StorageService(security);
  await storage.init();

  final auth = AuthService(storage, security);
  await auth.loadSession();

  final notifications = NotificationService(storage);
  final data = DataService(storage);
  final citas = CitaService(storage, notifications);
  final resenas = ResenaService(storage);
  final reminders = ReminderService(storage, notifications);

  // HU9/HU14: genera los recordatorios de citas próximas al arrancar.
  await reminders.generarRecordatoriosPendientes();

  runApp(NanysCareApp(
    storage: storage,
    auth: auth,
    data: data,
    citas: citas,
    notifications: notifications,
    resenas: resenas,
    reminders: reminders,
  ));
}

class NanysCareApp extends StatelessWidget {
  final StorageService storage;
  final AuthService auth;
  final DataService data;
  final CitaService citas;
  final NotificationService notifications;
  final ResenaService resenas;
  final ReminderService reminders;

  const NanysCareApp({
    super.key,
    required this.storage,
    required this.auth,
    required this.data,
    required this.citas,
    required this.notifications,
    required this.resenas,
    required this.reminders,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<StorageService>.value(value: storage),
        ChangeNotifierProvider<AuthService>.value(value: auth),
        ChangeNotifierProvider<DataService>.value(value: data),
        ChangeNotifierProvider<CitaService>.value(value: citas),
        ChangeNotifierProvider<NotificationService>.value(value: notifications),
        ChangeNotifierProvider<ResenaService>.value(value: resenas),
        Provider<ReminderService>.value(value: reminders),
      ],
      child: MaterialApp(
        title: 'Nanys Care',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        supportedLocales: const [
          Locale('es', 'MX'),
          Locale('es'),
          Locale('en'),
        ],
        locale: const Locale('es', 'MX'),
        home: const SplashScreen(),
      ),
    );
  }
}
