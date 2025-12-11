import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';

import 'theme/theme_provider.dart';        
import 'screens/auth/login_screen.dart';
import 'widgets/bottom_nav_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Load .env BEFORE anything else
  await dotenv.load();

  // Initialize Firebase (using your firebase_options.dart)
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Run app WITH provider for dark mode
  runApp(
    ChangeNotifierProvider(
      create: (_) => ThemeProvider(),
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final themeProvider = Provider.of<ThemeProvider>(context);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'PropertyPulse',

      // Enable Theme Modes
      themeMode: themeProvider.currentMode,

      // LIGHT THEME
      theme: ThemeData(
        brightness: Brightness.light,
        primaryColor: const Color(0xFF1D3557),
        scaffoldBackgroundColor: const Color(0xFFF6F8FA),

        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1D3557),
          primary: const Color(0xFF1D3557),
        ),

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.grey),
          ),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF1D3557),
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 52),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),

      // DARK THEME
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.grey.shade900,
        primaryColor: Colors.white,

        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.grey.shade800,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.grey.shade600),
          ),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blueGrey.shade700,
            foregroundColor: Colors.white,
          ),
        ),
      ),

      //  Auth listener → auto redirect if logged in
      home: StreamBuilder<User?>(
        stream: FirebaseAuth.instance.authStateChanges(),
        builder: (context, snapshot) {
          // Not logged in → Show login
          if (!snapshot.hasData) {
            return const LoginScreen();
          }

          // Logged in → Show full app
          return const BottomNavScaffold();
        },
      ),
    );
  }
}