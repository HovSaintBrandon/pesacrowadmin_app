import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/theme.dart';
import 'providers/auth_provider.dart';
import 'providers/deal_provider.dart';
import 'providers/fee_provider.dart';
import 'providers/blacklist_provider.dart';
import 'providers/dashboard_provider.dart';
import 'providers/mpesa_provider.dart';
import 'providers/disbursement_provider.dart';
import 'providers/admin_management_provider.dart';
import 'providers/user_provider.dart';
import 'providers/financials_provider.dart';
import 'providers/system_provider.dart';
import 'providers/announcement_provider.dart';
import 'screens/auth/login_page.dart';
import 'screens/shell/admin_shell.dart';
import 'services/api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ApiService().init();
  
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => DealProvider()),
        ChangeNotifierProvider(create: (_) => FeeProvider()),
        ChangeNotifierProvider(create: (_) => BlacklistProvider()),
        ChangeNotifierProvider(create: (_) => DashboardProvider()),
        ChangeNotifierProvider(create: (_) => MpesaProvider()),
        ChangeNotifierProvider(create: (_) => DisbursementProvider()),
        ChangeNotifierProvider(create: (_) => AdminManagementProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => FinancialsProvider()),
        ChangeNotifierProvider(create: (_) => SystemProvider()),
        ChangeNotifierProvider(create: (_) => AnnouncementProvider()),
      ],
      child: const PesaCrowAdminApp(),
    ),
  );
}

class PesaCrowAdminApp extends StatelessWidget {
  const PesaCrowAdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'PesaCrow Admin',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const AuthGate(),
    );
  }
}

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    if (!auth.isInitialized) {
      Future.microtask(() => auth.loadPersistedAuth());
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Image.asset(
                'assets/mpesacrowlogo.png',
                height: 120,
              ),
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
            ],
          ),
        ),
      );
    }

    return auth.isAuthenticated
        ? const AdminShell()
        : const LoginPage();
  }
}
