import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'screens/home_screen.dart';
import 'screens/onboarding_screen.dart';
import 'services/user_service.dart';
import 'providers/garante_auth_provider.dart';
import 'providers/group_chat_provider.dart';
import 'app_constants.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Inizializza localizzazione italiana per le date
  await initializeDateFormatting('it_IT', null);

  // Load environment variables
  try {
    await dotenv.load(fileName: ".env");
  } catch (e) {
    debugPrint('Error loading .env file: $e');
  }
  
  // Inizializza Supabase
  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL'] ?? '',
    anonKey: dotenv.env['SUPABASE_ANON_KEY'] ?? '',
  );
  
  runApp(
    // AVVOLGI PandaLexApp con MultiProvider
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => GaranteAuthProvider()),
        ChangeNotifierProvider(create: (_) => GroupChatProvider()),
      ],
      child: const PandaLexApp(),
    ),
  );
}

class PandaLexApp extends StatelessWidget {
  const PandaLexApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'P.An.D.A Lex',
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('it', 'IT'),
      ],
      locale: const Locale('it', 'IT'),
      theme: ThemeData(
        primarySwatch: Colors.blue,
        primaryColor: AppConstants.blueNcs,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppConstants.blueNcs,
          elevation: 0,
          centerTitle: true,
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: AppConstants.blueNcs,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
            ),
          ),
        ),
      ),
      home: FutureBuilder<bool>(
        future: UserService().hasCompletedOnboarding(),
        builder: (context, snapshot) {
          // Mentre sta caricando, mostra un container trasparente (usa lo splash nativo)
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Container(color: Colors.white);
          }

          // Controlla se l'onboarding è completato
          final hasCompletedOnboarding = snapshot.data ?? false;
          return hasCompletedOnboarding ? const HomeScreen() : const OnboardingScreen();
        },
      ),
      debugShowCheckedModeBanner: false,
    );
  }
}