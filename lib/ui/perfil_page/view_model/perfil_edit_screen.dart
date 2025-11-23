import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_point/data/services/auth_service.dart';
import 'package:food_point/domain/models/user_model.dart';
import 'package:food_point/ui/core/themes/app_theme.dart';
import 'package:food_point/ui/core/ui/custom_message_banner.dart';
import 'package:food_point/ui/perfil_page/view_model/widgets/custom_input_field.dart';
import 'package:food_point/ui/perfil_page/view_model/widgets/custom_password_field.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EditProfilePage extends StatefulWidget {
  const EditProfilePage({super.key});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  UserModel? user;
  bool esGoogle = false;
  File? avatarFile;
  String? mensaje;
  bool esError = false;
  final _formKey = GlobalKey<FormState>();
  final ImagePicker picker = ImagePicker();

  // Controllers de perfil
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();

  // Controllers de contraseña
  final TextEditingController _currentPasswordController =
      TextEditingController();
  final TextEditingController _newPasswordController = TextEditingController();
  final TextEditingController _confirmPasswordController =
      TextEditingController();

  // Estados de visibilidad
  bool obscureCurrent = true;
  bool obscureNew = true;
  bool obscureConfirm = true;

  @override
  void initState() {
    super.initState();
    cargarUsuario();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // ===================== CARGAR USUARIO =====================
  Future<void> cargarUsuario() async {
    final data = await _getUsuario();
    if (data == null) return;

    setState(() {
      user = UserModel(
        nombre: data['nombre'],
        email: data['email'],
        telefono: data['telefono'],
        foto: data['foto'],
        miembroDesde: data['miembroDesde'],
      );

      _nameController.text = user!.nombre;
      _emailController.text = user!.email;
      _phoneController.text = user!.telefono;
      _locationController.text = user!.miembroDesde;
    });
  }

  Future<Map<String, dynamic>?> _getUsuario() async {
    final firebaseUser = AuthService.instance.currentUser;
    if (firebaseUser == null) return null;

    // Detectar método de login
    if (firebaseUser.providerData.any((p) => p.providerId == 'google.com')) {
      esGoogle = true;
    } else {
      esGoogle = false;
    }

    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(firebaseUser.uid)
        .get();

    if (!doc.exists) {
      return {
        'nombre': firebaseUser.displayName ?? 'Sin nombre',
        'email': firebaseUser.email ?? 'Sin email',
        'telefono': firebaseUser.phoneNumber ?? 'Sin teléfono',
        'foto': firebaseUser.photoURL ?? '',
        'miembroDesde': _formatearFecha(firebaseUser.metadata.creationTime),
      };
    }

    final data = doc.data()!;
    return {
      'nombre': data['name'] ?? 'Sin nombre',
      'email': data['email'] ?? 'Sin email',
      'telefono': data['phoneNumber'] ?? 'Sin teléfono',
      'foto': data['photoUrl'] ?? '',
      'miembroDesde': _formatearFecha(
        (data['createdAt'] as Timestamp).toDate(),
      ),
    };
  }

  static String _formatearFecha(DateTime? fecha) {
    if (fecha == null) return "Desconocido";
    const meses = [
      "Enero",
      "Febrero",
      "Marzo",
      "Abril",
      "Mayo",
      "Junio",
      "Julio",
      "Agosto",
      "Septiembre",
      "Octubre",
      "Noviembre",
      "Diciembre",
    ];
    return "${meses[fecha.month - 1]} ${fecha.year}";
  }

  // ===================== PICK IMAGE =====================
  Future<void> pickImage() async {
    final XFile? picked = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (picked != null) {
      setState(() {
        avatarFile = File(picked.path);
      });
    }
  }

  Color getColorFromName(String name) {
    final index = name.codeUnitAt(0) % avatarColors.length;
    return avatarColors[index];
  }

  String _getInitials(String name) {
    final parts = name.split(' ');
    if (parts.length == 1) {
      return parts[0][0].toUpperCase();
    } else {
      return (parts[0][0] + parts[1][0]).toUpperCase();
    }
  }

  final List<Color> avatarColors = [
    Colors.blue,
    Colors.green,
    Colors.purple,
    Colors.teal,
    Colors.indigo,
    Colors.brown,
  ];
  // ===================== GUARDAR DATOS =====================
  Future<void> saveProfile() async {
    if (user == null) return;
    if (!_formKey.currentState!.validate()) return;

    final userRef = FirebaseFirestore.instance
        .collection('users')
        .doc(AuthService.instance.currentUser!.uid);

    String message = "";
    bool isError = false;

    try {
      final userAuth = AuthService.instance.currentUser!;
      final newName = _nameController.text.trim();
      final newPhone = _phoneController.text.trim();
      final newEmail = _emailController.text.trim();
      final currentPassword = _currentPasswordController.text.trim();
      final newPassword = _newPasswordController.text.trim();
      final confirmPassword = _confirmPasswordController.text.trim();

      // -----------------------------
      //  FOTO
      // -----------------------------
      String? base64Image;
      if (avatarFile != null) {
        final bytes = await avatarFile!.readAsBytes();
        base64Image = base64Encode(bytes);
      }

      // -----------------------------
      //  ACTUALIZAR FIRESTORE
      // -----------------------------
      final updatedData = {
        'name': newName,
        'phoneNumber': newPhone,
        'photoUrl': base64Image ?? user!.foto,
      };

      await userRef.set(updatedData, SetOptions(merge: true));

      // -----------------------------
      //  SI NO ES GOOGLE, ACTUALIZAR EMAIL Y CONTRASEÑA
      // -----------------------------
      if (!esGoogle) {
        // ⚠️ Si quiere actualizar email o contraseña → reautenticación obligatoria
        final wantsToUpdateEmail = (newEmail != user!.email);
        final wantsToUpdatePassword =
            newPassword.isNotEmpty || confirmPassword.isNotEmpty;

        if ((wantsToUpdateEmail || wantsToUpdatePassword) &&
            currentPassword.isEmpty) {
          throw Exception(
            "Debe ingresar su contraseña actual para realizar cambios de seguridad.",
          );
        }

        // 🔐 Coincidencia de contraseñas nuevas
        if (wantsToUpdatePassword && newPassword != confirmPassword) {
          throw Exception("Las contraseñas nuevas no coinciden.");
        }

        // 🔐 Reautenticar si es necesario
        if (wantsToUpdateEmail || wantsToUpdatePassword) {
          try {
            final cred = EmailAuthProvider.credential(
              email: userAuth.email!,
              password: currentPassword,
            );
            await userAuth.reauthenticateWithCredential(cred);
          } on FirebaseAuthException catch (e) {
            print("estaentrando");
            print(e);
            if (e.code == 'invalid-credential') {
              throw Exception("La contraseña actual es incorrecta.");
            } else {
              throw Exception("Error al validar tu identidad: ${e.message}");
            }
          }
        }

        // 📧 Actualizar email si cambió
        if (wantsToUpdateEmail) {
          await userRef.update({'email': newEmail});
        }

        // 🔑 Actualizar contraseña si se ingresó una nueva
        if (wantsToUpdatePassword) {
          await userAuth.updatePassword(newPassword);
        }
      }

      // 🔵 Si todo OK
      message = "Perfil actualizado correctamente";
      isError = false;
    } catch (e) {
      // 🔴 Error general
      message = e.toString().replaceFirst("Exception:", "").trim();
      isError = true;
    }

    // -----------------------------
    //  MOSTRAR MENSAJE
    // -----------------------------
    setState(() {
      mensaje = message;
      esError = isError;
    });

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) setState(() => mensaje = null);
    });
  }

  ImageProvider? getImageProvider(dynamic foto, File? avatarFile) {
    if (avatarFile != null) return FileImage(avatarFile);
    if (foto == null) return null;

    if (foto is String) {
      foto = foto.trim();
      if (foto.isEmpty) return null;
      if (foto.startsWith('http')) return NetworkImage(foto);
      try {
        return MemoryImage(base64Decode(foto));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  // ===================== UI =====================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Editar perfil"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  children: [
                    const SizedBox(height: 12),
                    // ===== AVATAR =====
                    Center(
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          GestureDetector(
                            onTap: pickImage,
                            child: Container(
                              width: 140,
                              height: 140,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: Colors.grey[200],
                                border: Border.all(
                                  color: const Color(0xFFFF6A00),
                                  width: 1,
                                ),
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Color(
                                  getColorFromName(user!.nombre).value |
                                      0xFF000000,
                                ),
                                backgroundImage: getImageProvider(
                                  user!.foto,
                                  avatarFile,
                                ),
                                child:
                                    (avatarFile == null && user?.foto == null ||
                                        user!.foto!.trim().isEmpty)
                                    ? Text(
                                        _getInitials(user!.nombre),
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 50,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      )
                                    : null,
                              ),
                            ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: GestureDetector(
                              onTap: pickImage,
                              child: Container(
                                padding: const EdgeInsets.all(6),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: AppTheme.primaryColor,
                                    width: 1,
                                  ),
                                ),
                                child: Icon(
                                  Icons.edit,
                                  size: 18,
                                  color: AppTheme.primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Nombre
                    CustomInputField(
                      label: "Nombre*",
                      controller: _nameController,
                      icon: Icons.person,
                      enabled: !esGoogle,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return "El nombre es obligatorio";
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Email
                    CustomInputField(
                      label: "Correo electrónico*",
                      controller: _emailController,
                      icon: Icons.email,
                      keyboardType: TextInputType.emailAddress,
                      enabled: false,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty)
                          return "El correo es obligatorio";
                        if (!RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        ).hasMatch(value.trim()))
                          return "Correo no válido";
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Teléfono
                    CustomInputField(
                      label: "Teléfono",
                      controller: _phoneController,
                      icon: Icons.phone,
                      keyboardType: TextInputType.phone,
                    ),
                    const SizedBox(height: 16),

                    // Miembro desde
                    CustomInputField(
                      label: "Miembro desde",
                      controller: _locationController,
                      icon: Icons.calendar_today,
                      enabled: false,
                    ),
                    const SizedBox(height: 20),

                    // Contraseñas solo email/password
                    if (!esGoogle) ...[
                      CustomPasswordField(
                        label: "Contraseña actual",
                        controller: _currentPasswordController,
                        obscure: obscureCurrent,
                        onToggle: () =>
                            setState(() => obscureCurrent = !obscureCurrent),
                      ),
                      const SizedBox(height: 16),
                      CustomPasswordField(
                        label: "Nueva contraseña",
                        controller: _newPasswordController,
                        obscure: obscureNew,
                        onToggle: () =>
                            setState(() => obscureNew = !obscureNew),
                      ),
                      const SizedBox(height: 16),
                      CustomPasswordField(
                        label: "Confirmar nueva contraseña",
                        controller: _confirmPasswordController,
                        obscure: obscureConfirm,
                        onToggle: () =>
                            setState(() => obscureConfirm = !obscureConfirm),
                      ),
                      const SizedBox(height: 20),
                    ],
                    if (mensaje != null)
                      CustomMessageBanner(message: mensaje!, isError: esError),
                    const SizedBox(height: 20),
                    // Guardar
                    Center(
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                        ),
                        onPressed: saveProfile,
                        child: const Text("Guardar"),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}
