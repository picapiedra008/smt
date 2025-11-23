import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:food_point/ui/perfil_page/view_model/widgets/custom_password_field.dart';

class ChangePasswordPage extends StatefulWidget {
  const ChangePasswordPage({super.key});

  @override
  State<ChangePasswordPage> createState() => _ChangePasswordPageState();
}

class _ChangePasswordPageState extends State<ChangePasswordPage> {
  final TextEditingController _oldPass = TextEditingController();
  final TextEditingController _newPass = TextEditingController();
  final TextEditingController _confirmPass = TextEditingController();

  bool loading = false;

  // Estados de visibilidad
  bool obscureOld = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  Future<void> changePassword() async {
    if (_newPass.text.trim() != _confirmPass.text.trim()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Las contraseñas no coinciden")),
      );
      return;
    }

    setState(() => loading = true);

    try {
      final user = FirebaseAuth.instance.currentUser!;
      final cred = EmailAuthProvider.credential(
        email: user.email!,
        password: _oldPass.text.trim(),
      );

      // Reautenticación
      await user.reauthenticateWithCredential(cred);

      // Actualizar contraseña
      await user.updatePassword(_newPass.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Contraseña actualizada con éxito")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Error: $e")));
    }

    setState(() => loading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Cambiar contraseña")),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            CustomPasswordField(
              label: "Contraseña actual",
              controller: _oldPass,
              obscure: obscureOld,
              onToggle: () {
                setState(() => obscureOld = !obscureOld);
              },
            ),
            const SizedBox(height: 16),

            CustomPasswordField(
              label: "Nueva contraseña",
              controller: _newPass,
              obscure: obscureNew,
              onToggle: () {
                setState(() => obscureNew = !obscureNew);
              },
            ),
            const SizedBox(height: 16),

            CustomPasswordField(
              label: "Confirmar nueva contraseña",
              controller: _confirmPass,
              obscure: obscureConfirm,
              onToggle: () {
                setState(() => obscureConfirm = !obscureConfirm);
              },
            ),

            const SizedBox(height: 20),

            ElevatedButton(
              onPressed: loading ? null : changePassword,
              child: loading
                  ? const CircularProgressIndicator()
                  : const Text("Actualizar contraseña"),
            ),
          ],
        ),
      ),
    );
  }
}
