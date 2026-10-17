import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'screens/home_page.dart';
import 'screens/login_page.dart';
import 'screens/user_profile.dart';
import 'services/login_session_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('ko');

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late final Future<UserProfile?> _startupSession;

  @override
  void initState() {
    super.initState();
    _startupSession = LoginSessionService.restore();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: FutureBuilder<UserProfile?>(
        future: _startupSession,
        builder: (context, snapshot) {
          if (snapshot.connectionState !=
              ConnectionState.done) {
            return const Scaffold(
              body: Center(
                child: CircularProgressIndicator(),
              ),
            );
          }

          final profile = snapshot.data;

          if (profile == null) {
            return const LoginPage();
          }

          return HomeScreen(profile: profile);
        },
      ),
    );
  }
}