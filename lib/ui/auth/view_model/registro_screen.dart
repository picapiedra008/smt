import 'package:flutter/material.dart';
import '../widgets/register_header.dart';
import '../widgets/register_form.dart';
import '../widgets/register_button.dart';

class RegisterScreen extends StatelessWidget {
  const RegisterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
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
                const RegisterForm(),
                const SizedBox(height: 24),
                const RegisterButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
