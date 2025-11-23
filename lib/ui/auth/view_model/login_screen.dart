import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:food_point/data/services/auth_service.dart';
import 'package:food_point/ui/auth/view_model/registro_screen.dart';
import 'package:food_point/ui/home/view_model/home_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool firebaseConnected;

  const LoginScreen({super.key, required this.firebaseConnected});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscurePassword = true;

  bool _isLoadingEmail = false;
  bool _isLoadingGoogle = false;

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        // Redirigir a la ruta /inicio cuando se presione el botón de atrás
        Navigator.pushReplacementNamed(context, '/perfil');
        return false; // Evita el comportamiento por defecto (salir de la app)
      },
      child: Scaffold(
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
      ),
    );
  }

  // ---------- CABECERA -----------
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

  // ---------- TARJETA DE LOGIN -----------
  Widget _buildFormCard(BuildContext context, ThemeData theme) {
    final isDark = theme.brightness == Brightness.dark;

    // Color de borde según tema
    final borderColor = isDark ? Colors.white24 : Colors.black12;

    return Card(
      color:
          theme.cardTheme.color ?? (isDark ? Colors.grey[850] : Colors.white),
      elevation: theme.cardTheme.elevation ?? 5,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
        side: BorderSide(color: borderColor, width: 1.2), // <-- borde dinámico
      ),
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            Text(
              'Iniciar Sesión',
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
                fontSize: 22,
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
            _buildRegisterRow(context, theme),
          ],
        ),
      ),
    );
  }

  // ---------- CAMPOS -----------
  Widget _buildEmailField() {
    return TextField(
      controller: emailController,
      decoration: const InputDecoration(
        labelText: 'Correo Electrónico',
        prefixIcon: Icon(Icons.email, color: Colors.grey),
      ),
      keyboardType: TextInputType.emailAddress,
    );
  }

  Widget _buildPasswordField(ThemeData theme) {
    return TextField(
      controller: passwordController,
      obscureText: _obscurePassword,
      decoration: InputDecoration(
        labelText: 'Contraseña',
        prefixIcon: const Icon(Icons.lock, color: Colors.grey),
        suffixIcon: IconButton(
          icon: Icon(
            _obscurePassword ? Icons.visibility_off : Icons.visibility,
            color: Colors.grey,
          ),
          onPressed: () {
            setState(() {
              _obscurePassword = !_obscurePassword;
            });
          },
        ),
      ),
    );
  }

  // ---------- BOTÓN LOGIN EMAIL -----------
  Widget _buildLoginButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: _isLoadingEmail ? null : () => _loginWithEmail(context),
        child: _isLoadingEmail
            ? const CircularProgressIndicator(
                color: Colors.white,
                strokeWidth: 2,
              )
            : const Text("Iniciar Sesión"),
      ),
    );
  }

  Future<void> _loginWithEmail(BuildContext context) async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showError('Por favor ingresa tu correo y contraseña.');
      return;
    }

    setState(() => _isLoadingEmail = true);

    try {
      final userCredential = await AuthService.instance.signInWithEmail(
        email: email,
        password: password,
      );

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } on FirebaseAuthException catch (e) {
      String message = "Ocurrió un error inesperado.";

      switch (e.code) {
        case "user-not-found":
          message = "No existe una cuenta con este correo.";
          break;
        case "wrong-password":
          message = "La contraseña es incorrecta.";
          break;
        case "invalid-email":
          message = "El correo no es válido.";
          break;
        default:
          message = "Credenciales inválidas.";
          print("FirebaseAuthException: ${e.code} - ${e.message}");
      }

      _showError(message);
    } finally {
      if (mounted) setState(() => _isLoadingEmail = false);
    }
  }

  // ---------- BOTÓN GOOGLE -----------
  Widget _buildGoogleButton(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Fondo del botón según tema
    final backgroundColor = isDark ? Colors.grey[850] : Colors.white;

    // Borde según tema
    final borderColor = isDark ? Colors.white12 : Colors.black12;

    // Color del texto/loader
    final foregroundColor = isDark ? Colors.white : Colors.black87;

    return SizedBox(
      height: 50,
      width: double.infinity,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: backgroundColor,
          foregroundColor: foregroundColor,
          side: BorderSide(color: borderColor, width: 1.2),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
        ),
        icon: _isLoadingGoogle
            ? SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(foregroundColor),
                ),
              )
            : Image.asset('assets/img/google1.png', height: 30, width: 30),
        label: Text(
          _isLoadingGoogle ? "Conectando..." : "Continuar con Google",
        ),
        onPressed: _isLoadingGoogle ? null : () => _handleGoogleSignIn(context),
      ),
    );
  }

  Future<void> _handleGoogleSignIn(BuildContext context) async {
    setState(() => _isLoadingGoogle = true);

    try {
      final userCredential = await AuthService.instance.signInWithGoogle();

      if (userCredential == null) {
        _showError("No se pudo completar el inicio de sesión con Google.");
        return;
      }

      final user = userCredential.user;
      if (user == null) return;

      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);

      final doc = await userRef.get();

      if (!doc.exists) {
        await userRef.set({
          'name': user.displayName ?? 'Sin nombre',
          'email': user.email,
          'photoUrl': user.photoURL,
          'phoneNumber': user.phoneNumber,
          'role': 'owner',
          'createdAt': FieldValue.serverTimestamp(),
        });
      }

      if (!mounted) return;

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } catch (e) {
      _showError("Error al conectar con Google.");
    } finally {
      if (mounted) setState(() => _isLoadingGoogle = false);
    }
  }

  // ---------- REGISTRO -----------
  Widget _buildRegisterRow(BuildContext context, ThemeData theme) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("¿No tienes cuenta? "),
        GestureDetector(
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => RegisterScreen()),
          ),
          child: Text(
            "Regístrate aquí",
            style: TextStyle(
              color: theme.colorScheme.primary,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ---------- SNACKBAR DE ERRORES -----------
  void _showError(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        duration: const Duration(seconds: 3),
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.red.shade600,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.red.shade200.withOpacity(0.4),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline, color: Colors.white, size: 26),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
