import 'package:flutter/material.dart';

const Color orangePrimary = Color(0xFFFF6A00); // naranja similar
const Color softPeach = Color(0xFFF8ECE3); // fondo suave
const Color cardBorder = Color(0xFFFFA66B); // borde sutil
const double borderRadiusAll = 16.0;

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _formKey = GlobalKey<FormState>();

  final TextEditingController nombreController = TextEditingController();
  final TextEditingController correoController = TextEditingController();
  final TextEditingController telefonoController = TextEditingController();
  final TextEditingController passController = TextEditingController();
  final TextEditingController confirmPassController = TextEditingController();

  bool obscurePass = true;
  bool obscureConfirm = true;
  bool acepto = false;
  AccountType accountType = AccountType.regular;

  bool get isFormValid {
    return _formKey.currentState?.validate() == true && acepto;
  }

  @override
  void dispose() {
    nombreController.dispose();
    correoController.dispose();
    telefonoController.dispose();
    passController.dispose();
    confirmPassController.dispose();
    super.dispose();
  }

  void _trySubmit() {
    final valid = _formKey.currentState?.validate() ?? false;
    if (!valid || !acepto) {
      setState(() {}); // para refrescar el botón deshabilitado
      return;
    }

    // Aquí solo mostramos un dialogo con los datos (frontend funcional).
    // Si quieres integrar Firebase, revisa la sección al final.
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Cuenta creada'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Nombre: ${nombreController.text}'),
            Text('Correo: ${correoController.text}'),
            Text('Teléfono: ${telefonoController.text}'),
            Text(
              'Tipo de cuenta: ${accountType == AccountType.regular ? "Usuario regular" : "Propietario de restaurante"}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Color(0xFFBDBDBD)),
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: cardBorder.withOpacity(0.6)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: orangePrimary),
      ),
      suffixIcon: suffix,
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.sizeOf(context).width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: isMobile ? double.infinity : 420,
              ),
              child: Column(
                children: [
                  // Icono circular naranja arriba
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: orangePrimary,
                    ),
                    child: const Icon(
                      Icons.restaurant,
                      color: Colors.white,
                      size: 32,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Sabores de Cochabamba',
                    style: TextStyle(
                      color: orangePrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Únete a nuestra comunidad gastronómica',
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                  const SizedBox(height: 18),

                  // Card principal
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(borderRadiusAll),
                      border: Border.all(color: cardBorder.withOpacity(0.6)),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.03),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 18,
                      vertical: 18,
                    ),
                    child: Form(
                      key: _formKey,
                      onChanged: () => setState(() {}),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Center(
                            child: Text(
                              'Crear Cuenta',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[800],
                              ),
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Nombre completo
                          const Text(
                            'Nombre Completo',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: nombreController,
                            decoration: _inputDecoration('Tu nombre completo'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Ingrese su nombre';
                              if (v.trim().length < 3)
                                return 'Nombre muy corto';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Correo
                          const Text(
                            'Correo Electrónico',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: correoController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration('tu@email.com'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Ingrese su correo';
                              final emailRegex = RegExp(r'^[^@]+@[^@]+\.[^@]+');
                              if (!emailRegex.hasMatch(v.trim()))
                                return 'Correo inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Teléfono
                          const Text(
                            'Teléfono',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: telefonoController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration('+591 7-1234567'),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty)
                                return 'Ingrese su teléfono';
                              if (v.trim().length < 6)
                                return 'Teléfono inválido';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Contraseña
                          const Text(
                            'Contraseña',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: passController,
                            obscureText: obscurePass,
                            decoration: _inputDecoration(
                              'Mínimo 6 caracteres',
                              suffix: IconButton(
                                icon: Icon(
                                  obscurePass
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () =>
                                    setState(() => obscurePass = !obscurePass),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Ingrese una contraseña';
                              if (v.length < 6) return 'Mínimo 6 caracteres';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Confirmar contraseña
                          const Text(
                            'Confirmar Contraseña',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: confirmPassController,
                            obscureText: obscureConfirm,
                            decoration: _inputDecoration(
                              'Confirma tu contraseña',
                              suffix: IconButton(
                                icon: Icon(
                                  obscureConfirm
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                ),
                                onPressed: () => setState(
                                  () => obscureConfirm = !obscureConfirm,
                                ),
                              ),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty)
                                return 'Confirme su contraseña';
                              if (v != passController.text)
                                return 'Las contraseñas no coinciden';
                              return null;
                            },
                          ),
                          const SizedBox(height: 12),

                          // Tipo de cuenta (checkbox estilo)
                          const Text(
                            'Tipo de Cuenta',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Checkbox(
                                value: accountType == AccountType.owner,
                                onChanged: (val) {
                                  setState(() {
                                    accountType = val == true
                                        ? AccountType.owner
                                        : AccountType.regular;
                                  });
                                },
                                activeColor: orangePrimary,
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      accountType = AccountType.owner;
                                    });
                                  },
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: const [
                                      Text(
                                        'Soy propietario de un restaurante',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                      SizedBox(height: 2),
                                      Text(
                                        'Cuenta de usuario regular',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),

                          // Acepto términos
                          Row(
                            children: [
                              Checkbox(
                                value: acepto,
                                onChanged: (v) =>
                                    setState(() => acepto = v ?? false),
                                activeColor: orangePrimary,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Wrap(
                                  children: [
                                    const Text('Acepto los '),
                                    GestureDetector(
                                      onTap: () {
                                        // mostrar términos
                                        showDialog(
                                          context: context,
                                          builder: (_) => AlertDialog(
                                            title: const Text(
                                              'Términos y condiciones',
                                            ),
                                            content: const SingleChildScrollView(
                                              child: Text(
                                                'Aquí van los términos y condiciones...',
                                              ),
                                            ),
                                            actions: [
                                              TextButton(
                                                onPressed: () =>
                                                    Navigator.pop(context),
                                                child: const Text('Cerrar'),
                                              ),
                                            ],
                                          ),
                                        );
                                      },
                                      child: Text(
                                        'términos y condiciones',
                                        style: TextStyle(
                                          color: orangePrimary,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 12),

                          // Botón Crear Cuenta
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: isFormValid ? _trySubmit : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: orangePrimary,
                                disabledBackgroundColor: orangePrimary
                                    .withOpacity(0.4),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 14,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: const Text(
                                'Crear Cuenta',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 12),
                          Center(
                            child: GestureDetector(
                              onTap: () {
                                // navegar a login (ejemplo)
                              },
                              child: RichText(
                                text: TextSpan(
                                  text: '¿Ya tienes cuenta? ',
                                  style: TextStyle(color: Colors.grey[700]),
                                  children: [
                                    TextSpan(
                                      text: 'Inicia sesión aquí',
                                      style: TextStyle(
                                        color: orangePrimary,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
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

enum AccountType { regular, owner }
