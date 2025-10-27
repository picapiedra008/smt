import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:food_point/ui/auth/view_model/login_screen.dart';
import 'firebase_options.dart';
import 'package:food_point/ui/core/themes/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool firebaseConnected = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseConnected = true;
  } catch (e) {
    // If initialization fails we set connected=false and allow the app to run
    firebaseConnected = false;
  }
  runApp(MyApp(firebaseConnected: firebaseConnected));
}

class MyApp extends StatelessWidget {
  final bool firebaseConnected;

  const MyApp({super.key, required this.firebaseConnected});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi App',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // usa el modo del dispositivo
      home: LoginScreen(),
    );
  }
}
