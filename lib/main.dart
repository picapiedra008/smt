import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:food_point/ui/auth/view_model/login_screen.dart';
import 'firebase_options.dart';
import 'package:food_point/ui/core/themes/app_theme.dart';

import 'package:food_point/ui/formularioRestaurante/view_model/formularioRestaurante.dart';
import 'package:food_point/ui/listarRestaurantes/view_model/listar_restaurantes_screen.dart';

import 'widgets/catalogo_platos.dart';


import 'firebase_options.dart';
import 'package:food_point/ui/auth/view_model/login_screen.dart';
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

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Platos de mi tierra',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.system, // usa el modo del dispositivo
      //home: RestaurantFormPage(restaurantId: "T21GraUMgRWLmQDj6kma",),
      //home:RestaurantesPage(),
      debugShowCheckedModeBanner: false,
      home: LoginScreen(firebaseConnected: firebaseConnected),
      /*home: firebaseConnected
      ? MyHomePage(title: 'Flutter Demo Home Page', firebaseConnected: firebaseConnected)
      : const _FirebaseErrorScreen(),*/
  );
  }
}

class MyHomePage extends StatefulWidget {
  final bool firebaseConnected;

  const MyHomePage({super.key, required this.title, required this.firebaseConnected});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Inicio'),
              Tab(text: 'Mis restaurantes'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            DishCatalogPage(),     // ← Lista mock primero
            RestaurantFormPage(),
          ],
        ),
      ),
    );
  }
}

class _FirebaseErrorScreen extends StatelessWidget {
  const _FirebaseErrorScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: const [
            Icon(Icons.error_outline, size: 56, color: Colors.red),
            SizedBox(height: 12),
            Text(
              'No se pudo iniciar Firebase.\nRevisa tu conexión y configuración.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
