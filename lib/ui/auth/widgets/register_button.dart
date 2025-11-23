import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:food_point/data/services/auth_service.dart';
import 'package:food_point/ui/auth/view_model/login_screen.dart';
import 'package:food_point/ui/core/ui/custom_message_banner.dart';

class RegisterButton extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const RegisterButton({
    super.key,
    required this.formKey,
    required this.nombreController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  void _showBanner(BuildContext context, String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        elevation: 0,
        backgroundColor: Colors.transparent,
        behavior: SnackBarBehavior.floating,
        content: CustomMessageBanner(message: msg, isError: error),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: theme.colorScheme.primary,
          foregroundColor: theme.colorScheme.onPrimary,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onPressed: () async {
          if (!formKey.currentState!.validate()) {
            _showBanner(
              context,
              "Corrige los errores antes de continuar",
              error: true,
            );
            return;
          }

          final nombre = nombreController.text.trim();
          final email = emailController.text.trim();
          final password = passwordController.text.trim();

          try {
            await AuthService.instance.createUserWithEmailAndProfile(
              email: email,
              password: password,
              name: nombre,
            );

            _showBanner(context, "Cuenta creada con éxito 🎉");

            if (context.mounted) {
              await Future.delayed(const Duration(milliseconds: 600));

              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => LoginScreen(firebaseConnected: true),
                ),
              );
            }
          } on FirebaseAuthException catch (e) {
            print("coreaaslkdjf");
            print(e.code);
            if (e.code == 'email-already-in-use') {
              _showBanner(
                context,
                "Ya existe una cuenta con este correo",
                error: true,
              );
              return;
            }
            _showBanner(context, "Error: $e", error: true);
          }
        },
        child: Text(
          'Registrarse',
          style: theme.textTheme.titleMedium?.copyWith(
            color: theme.colorScheme.onPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}
