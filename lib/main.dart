import 'package:flutter/material.dart';
import 'core/state/app_state.dart';
import 'core/theme/app_theme.dart';
import 'features/splash/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppStateModel().init();
  runApp(const ThailiApp());
}

class ThailiApp extends StatelessWidget {
  const ThailiApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppStateModel(),
      builder: (context, _) {
        final appState = AppStateModel();
        return MaterialApp(
          title: 'Thaili',
          debugShowCheckedModeBanner: false,
          theme: AppTheme.lightTheme,         // Light mode (default)
          darkTheme: AppTheme.darkTheme,      // Dark mode (system-triggered)
          themeMode: appState.themeMode,
          home: SplashScreen(isReturningUser: appState.isOnboarded),
        );
      },
    );
  }
}
