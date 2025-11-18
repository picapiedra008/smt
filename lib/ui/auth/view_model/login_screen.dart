import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_point/data/services/auth_service.dart';
import 'package:food_point/ui/auth/view_model/registro_screen.dart';
import 'package:food_point/ui/home/view_model/home_screen.dart';
import 'package:food_point/ui/listar_restaurantes/view_model/listar_restaurantes_screen.dart';

class LoginScreen extends StatelessWidget {
  final bool firebaseConnected;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  LoginScreen({super.key, required this.firebaseConnected});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 50),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(theme),
              const SizedBox(height: 30),
              _buildFormCard(context, theme),
              const SizedBox(height: 20),
              Text(
                '🌿 Tradición culinaria del valle cochabambino 🌿',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(ThemeData theme) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.restaurant_menu,
            color: theme.colorScheme.onPrimary,
            size: 40,
          ),
        ),
        const SizedBox(height: 15),
        Text(
          'Sabores de Cochabamba',
          style: theme.textTheme.titleLarge?.copyWith(
            color: theme.colorScheme.primary,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          'Descubre la gastronomía tradicional del valle',
          style: theme.textTheme.bodyMedium?.copyWith(
            color: theme.colorScheme.onBackground.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildFormCard(BuildContext context, ThemeData theme) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      color: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Text(
              'Iniciar Sesión',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 20),
            _buildEmailField(),
            const SizedBox(height: 15),
            _buildPasswordField(theme),
            const SizedBox(height: 20),
            _buildLoginButton(context),
            const SizedBox(height: 15),
            _buildGoogleButton(context),
            const SizedBox(height: 15),
            _buildDemoButton(context),
            const SizedBox(height: 15),
            _buildRegisterRow(context, theme),
          ],
        ),
      ),
    );
  }

  Widget _buildEmailField() {
    return TextField(
      controller: emailController,
      decoration: const InputDecoration(
        labelText: 'Correo Electrónico',
        hintText: 'tu@email.com',
      ),
    );
  }

  Widget _buildPasswordField(ThemeData theme) {
    return TextField(
      controller: passwordController,
      obscureText: true,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        hintText: 'Tu contraseña',
        suffixIcon: Icon(Icons.visibility, color: theme.colorScheme.primary),
      ),
    );
  }

  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () {
          // Aquí luego pondrás auth real con email/password
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RestaurantesPage()),
          );
        },
        child: const Text('Iniciar Sesión'),
      ),
    );
  }

  Widget _buildGoogleButton(BuildContext context) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
      icon: Image.asset('assets/img/google.png', height: 24, width: 24),
      label: const Text('Continuar con Google', style: TextStyle(fontSize: 16)),
      onPressed: () => _handleGoogleSignIn(context),
    );
  }

  Widget _buildDemoButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const HomeScreen()),
          );
        },
        icon: const Icon(Icons.person),
        label: const Text('Probar con cuenta demo'),
      ),
    );
  }

  Widget _buildRegisterRow(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text('¿No tienes cuenta? ', style: theme.textTheme.bodyMedium),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => RegisterScreen()),
            );
          },
          child: Text(
            'Regístrate aquí',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    try {
      final userCredential = await AuthService.instance.signInWithGoogle();

      if (userCredential != null) {
        final user = userCredential.user;
        print("Usuario logueado: $user");

        if (user != null) {
          final userRef = FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid);

          final doc = await userRef.get();

          // Guardar usuario la primera vez
          if (!doc.exists) {
            await userRef.set({
              'name': user.displayName ?? 'Sin nombre',
              'email': user.email,
              'photoUrl': user.photoURL,
              'phoneNumber': user.phoneNumber,
              'role': 'owner',
              'createdAt': FieldValue.serverTimestamp(),
            });
            print("Usuario guardado en Firestore");
          }

          // Redirigir a RestaurantesPage
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const RestaurantesPage()),
          );
        }
      } else {
        print("Inicio de sesión cancelado");
      }
    } catch (e) {
      print("Error en login con Google: $e");
      // Opcional: mostrar snackbar o alerta
    }
  }
}
