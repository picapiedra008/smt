import 'package:flutter/material.dart';

class RegisterForm extends StatefulWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController nombreController;
  final TextEditingController emailController;
  final TextEditingController passwordController;
  final TextEditingController confirmPasswordController;

  const RegisterForm({
    super.key,
    required this.formKey,
    required this.nombreController,
    required this.emailController,
    required this.passwordController,
    required this.confirmPasswordController,
  });

  @override
  State<RegisterForm> createState() => _RegisterFormState();
}

class _RegisterFormState extends State<RegisterForm> {
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  // Controla cuándo mostrar errores en cada campo
  bool _showNombreError = false;
  bool _showEmailError = false;
  bool _showPasswordError = false;
  bool _showConfirmError = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    InputDecoration _inputDecoration(
      String label,
      IconData icon, {
      Widget? suffixIcon,
    }) {
      return InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: suffixIcon,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: theme.colorScheme.primary, width: 2),
          borderRadius: BorderRadius.circular(12),
        ),
      );
    }

    String? _validateNombre(String? v) {
      if (v == null || v.isEmpty) return 'Ingrese su nombre';
      return null;
    }

    String? _validateEmail(String? v) {
      if (v == null || v.isEmpty) return 'Ingrese un correo electrónico';
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(v))
        return 'Correo no válido';
      return null;
    }

    String? _validatePassword(String? v) {
      if (v == null || v.isEmpty) return 'Ingrese una contraseña';
      if (v.length < 6) return 'La contraseña debe tener mínimo 6 caracteres';
      if (!RegExp(r'[0-9]').hasMatch(v))
        return 'Debe incluir al menos un número';
      if (!RegExp(r'[A-Za-z]').hasMatch(v))
        return 'Debe incluir al menos una letra';
      return null;
    }

    String? _validateConfirm(String? v) {
      if (v == null || v.isEmpty) return 'Repita su contraseña';
      if (v != widget.passwordController.text)
        return 'Las contraseñas no coinciden';
      return null;
    }

    return Form(
      key: widget.formKey,
      child: Column(
        children: [
          // Nombre
          TextFormField(
            controller: widget.nombreController,
            decoration: _inputDecoration('Nombre completo', Icons.person),
            autovalidateMode: _showNombreError
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            validator: _validateNombre,
            onChanged: (_) {
              setState(() => _showNombreError = true);
            },
          ),
          const SizedBox(height: 16),

          // Email
          TextFormField(
            controller: widget.emailController,
            decoration: _inputDecoration('Correo electrónico', Icons.email),
            keyboardType: TextInputType.emailAddress,
            autovalidateMode: _showEmailError
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            validator: _validateEmail,
            onChanged: (_) {
              setState(() => _showEmailError = true);
            },
          ),
          const SizedBox(height: 16),

          // Contraseña
          TextFormField(
            controller: widget.passwordController,
            decoration: _inputDecoration(
              'Contraseña',
              Icons.lock,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() => _obscurePassword = !_obscurePassword);
                },
              ),
            ),
            obscureText: _obscurePassword,
            autovalidateMode: _showPasswordError
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            validator: _validatePassword,
            onChanged: (_) {
              setState(() => _showPasswordError = true);
            },
          ),
          const SizedBox(height: 16),

          // Confirmar contraseña
          TextFormField(
            controller: widget.confirmPasswordController,
            decoration: _inputDecoration(
              'Confirmar contraseña',
              Icons.lock_outline,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                  color: Colors.grey,
                ),
                onPressed: () {
                  setState(() => _obscureConfirm = !_obscureConfirm);
                },
              ),
            ),
            obscureText: _obscureConfirm,
            autovalidateMode: _showConfirmError
                ? AutovalidateMode.always
                : AutovalidateMode.disabled,
            validator: _validateConfirm,
            onChanged: (_) {
              setState(() => _showConfirmError = true);
            },
          ),
        ],
      ),
    );
  }
}
