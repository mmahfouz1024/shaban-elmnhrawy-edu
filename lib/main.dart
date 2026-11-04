import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:google_fonts/google_fonts.dart';
import 'screens/animated_auth_screen.dart';
import 'screens/parent_portal_screen.dart';
import 'screens/student_portal_screen.dart';
import 'screens/teacher_dashboard_screen.dart';
import 'services/app_state.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ShabanElmnhrawyApp());
}

class ShabanElmnhrawyApp extends StatefulWidget {
  const ShabanElmnhrawyApp({super.key});

  @override
  State<ShabanElmnhrawyApp> createState() => _ShabanElmnhrawyAppState();
}

class _ShabanElmnhrawyAppState extends State<ShabanElmnhrawyApp> {
  final AppState _appState = AppState();

  @override
  void initState() {
    super.initState();
    _appState.addListener(() {
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'منصة الأستاذ شعبان المنهراوي التعليمية',
      debugShowCheckedModeBanner: false,
      locale: const Locale('ar', 'EG'),
      supportedLocales: const [
        Locale('ar', 'EG'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF4338CA), // Royal Indigo
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF4338CA),
          primary: const Color(0xFF4338CA),
          secondary: const Color(0xFFF59E0B), // Warm Gold Amber
          surface: Colors.white,
        ),
        fontFamily: GoogleFonts.cairo().fontFamily,
        scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      ),
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 450),
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        transitionBuilder: (child, animation) {
          return FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0.0, 0.04),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          );
        },
        child: _buildCurrentView(),
      ),
    );
  }

  Widget _buildCurrentView() {
    switch (_appState.currentUserRole) {
      case UserRole.guest:
        return AnimatedAuthScreen(
          key: const ValueKey('AuthScreen'),
          appState: _appState,
        );
      case UserRole.teacher:
        return TeacherDashboardScreen(
          key: const ValueKey('TeacherScreen'),
          appState: _appState,
        );
      case UserRole.student:
        return StudentPortalScreen(
          key: const ValueKey('StudentScreen'),
          appState: _appState,
        );
      case UserRole.parent:
        return ParentPortalScreen(
          key: const ValueKey('ParentScreen'),
          appState: _appState,
        );
    }
  }
}
