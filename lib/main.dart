import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:Sabores_de_mi_Tierra/data/services/auth_service.dart';
import 'package:Sabores_de_mi_Tierra/ui/auth/view_model/registro_screen.dart';
import 'package:Sabores_de_mi_Tierra/ui/formularioRestaurante/view_model/formularioRestaurante.dart';
import 'package:Sabores_de_mi_Tierra/ui/listaRestaurantesUsuario/view_model/lista_restaurantes_usuario_screen.dart';
import 'package:Sabores_de_mi_Tierra/ui/perfil_page/view_model/perfil_edit_screen.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'firebase_options.dart';
import 'package:Sabores_de_mi_Tierra/ui/core/themes/app_theme.dart';
import 'package:Sabores_de_mi_Tierra/ui/auth/view_model/login_screen.dart';

// importa las páginas
import 'package:Sabores_de_mi_Tierra/ui/home/view_model/home_screen.dart';
import 'widgets/catalogo_platos.dart';
import 'package:Sabores_de_mi_Tierra/ui/listar_restaurantes/view_model/listar_restaurantes_screen.dart';
import 'package:Sabores_de_mi_Tierra/ui/perfil_page/view_model/perfil_screen.dart';

// auth

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  bool firebaseConnected = false;

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await GoogleSignIn.instance.initialize();
    firebaseConnected = true;
  } catch (e) {
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
      themeMode: ThemeMode.system,
      debugShowCheckedModeBanner: false,
      home: firebaseConnected
          ? const _AuthGate()
          : const _FirebaseErrorScreen(),

      routes: {
        '/login': (context) =>
            LoginScreen(firebaseConnected: firebaseConnected),
        '/inicio': (context) => const HomeScreen(),
        '/registro': (context) => const RegisterScreen(),
        '/catalogo': (context) => const DishCatalogPage(),
        '/restaurantes': (context) => const SaboresApp(),
        '/perfil': (context) => PerfilPage(),
        '/perfil/edit': (context) => EditProfilePage(),
        '/perfil/restaurantes': (context) => const MisRestaurantesPage(),
        '/perfil/restaurantes/create': (context) => const RestaurantFormPage(),
        '/firebaseError': (context) => const _FirebaseErrorScreen(),
      },
      onGenerateRoute: (settings) {
        // Manejar rutas con parámetros
        if (settings.name!.startsWith('/perfil/restaurantes/edit/')) {
          final String id = settings.name!.split('/').last;
          return MaterialPageRoute(
            builder: (context) => RestaurantFormPage(restaurantId: id),
          );
        }
        return null;
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
      stream: AuthService.instance.authStateChanges,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        //if (snapshot.hasData) {
        return const HomeScreen(); // 🔥 Sesión activa → ir al inicio
        //}

        //return LoginScreen(firebaseConnected: true); // 🔥 No logueado → login
      },
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
