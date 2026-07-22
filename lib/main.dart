import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/services/auth_provider.dart';
import 'core/theme/app_theme.dart';
import 'modules/auth/pages/login_page.dart';
import 'modules/dashboard/pages/dashboard_page.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(
    ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: const LobsenseMobileApp(),
    ),
  );
}

class LobsenseMobileApp extends StatelessWidget {
  const LobsenseMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Lobsense Mobile',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          if (auth.isAuthenticated) {
            return const MobileDashboardPage();
          }
          return const LoginPage();
        },
      ),
    );
  }
}
