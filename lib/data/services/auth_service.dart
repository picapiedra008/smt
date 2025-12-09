import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:http/http.dart' as http;

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Singleton de GoogleSignIn
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  /// Login con Google

  Future<UserCredential?> signInWithGoogle() async {
    await GoogleSignIn.instance.initialize();

    // Trigger the authentication flow
    final GoogleSignInAccount googleUser = await GoogleSignIn.instance
        .authenticate();

    if (googleUser == null) {
      return null;
    }
    // Obtain the auth details from the request
    final GoogleSignInAuthentication googleAuth = googleUser.authentication;

    // Create a new credential
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
    );

    // Once signed in, return the UserCredential
    return await FirebaseAuth.instance.signInWithCredential(credential);
  }

  /// Logout
  Future<void> signOut() async {
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  /// Email/password login
  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
      email: email,
      password: password,
    );
  }

  /// Crear usuario con email/password
  Future<UserCredential> createUserWithEmailAndProfile({
    required String email,
    required String password,
    required String name,
    String role = 'owner', // puedes cambiar rol por defecto
  }) async {
    // 1️⃣ Crear usuario en Firebase Auth
    UserCredential userCredential = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    User? user = userCredential.user;
    if (user != null) {
      final userRef = FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid);
      await userRef.set({
        'name': name,
        'email': email,
        'role': role,
        'photoUrl': null,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    return userCredential;
  }

  Future<void> updateEmailAndPassword({
    required String newEmail,
    required String currentPassword,
    String? newPassword,
  }) async {
    final user = _auth.currentUser!;
    final idToken = await user.getIdToken();

    // Reautenticación
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);

    // Actualizar email usando REST API
    if (newEmail != user.email) {
      final emailUrl = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:update?key=TU_API_KEY',
      );
      final emailResponse = await http.post(
        emailUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'email': newEmail,
          'returnSecureToken': true,
        }),
      );
      final emailData = jsonDecode(emailResponse.body);
      if (emailResponse.statusCode != 200) {
        throw Exception(
          "Error al actualizar email: ${emailData['error']['message']}",
        );
      }
    }

    // Actualizar contraseña si se pasó
    if (newPassword != null && newPassword.isNotEmpty) {
      final passUrl = Uri.parse(
        'https://identitytoolkit.googleapis.com/v1/accounts:update?key=TU_API_KEY',
      );
      final passResponse = await http.post(
        passUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
          'password': newPassword,
          'returnSecureToken': true,
        }),
      );
      final passData = jsonDecode(passResponse.body);
      if (passResponse.statusCode != 200) {
        throw Exception(
          "Error al actualizar contraseña: ${passData['error']['message']}",
        );
      }
    }
  }
}
