import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/rooms/data/rooms_repository.dart';
import 'features/settings/settings_controller.dart';
import 'firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (error) {
    // يظهر التطبيق إن لم تتهيأ Firebase، مع طباعة تنبيه واضح.
    debugPrint('⚠️  تعذّر تهيئة Firebase: $error');
  }

  // بيانات التنسيق المحلية (التواريخ والأوقات بالعربية)
  await initializeDateFormatting('ar', null);

  final prefs = await SharedPreferences.getInstance();

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => SettingsController(prefs),
        ),
        Provider<AuthRepository>(
          create: (_) => AuthRepository(),
        ),
        Provider<RoomsRepository>(
          create: (_) => RoomsRepository(),
        ),
        StreamProvider<User?>(
          initialData: FirebaseAuth.instance.currentUser,
          create: (context) =>
              context.read<AuthRepository>().authStateChanges(),
        ),
      ],
      child: const CinemaApp(),
    ),
  );
}
