import 'package:flutter/material.dart';
import 'package:Sabores_de_mi_Tierra/ui/auth/widgets/register_button.dart';
import 'package:Sabores_de_mi_Tierra/ui/auth/widgets/register_form.dart';
import 'package:Sabores_de_mi_Tierra/ui/auth/widgets/register_header.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return WillPopScope(
      onWillPop: () async {
        // Redirigir a la ruta /perfil cuando se presione el botón de atrás
        Navigator.pushReplacementNamed(context, '/perfil');
        return false; // Evita el comportamiento por defecto
      },
      child: Scaffold(
        backgroundColor: theme.colorScheme.background,
        body: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const RegisterHeader(),
                  const SizedBox(height: 32),
                  RegisterForm(
                    formKey: _formKey,
                    nombreController: _nombreController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                  ),
                  const SizedBox(height: 32),
                  RegisterButton(
                    formKey: _formKey,
                    nombreController: _nombreController,
                    emailController: _emailController,
                    passwordController: _passwordController,
                    confirmPasswordController: _confirmPasswordController,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
