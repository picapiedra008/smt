import 'package:flutter/material.dart';
import 'package:food_point/data/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalificacionForm extends StatefulWidget {
  final String restaurantId;

  const CalificacionForm({
    super.key,
    required this.restaurantId,
  });

  @override
  State<CalificacionForm> createState() => _CalificacionFormState();
}

class _CalificacionFormState extends State<CalificacionForm> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  int _rating = 0;
  bool _isSubmitting = false;
  bool _hasRated = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Califica Nuestro Restaurante',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        
        // Estrellas de calificación
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(5, (index) {
            final starIndex = index + 1;
            return GestureDetector(
              onTap: () => _handleRating(starIndex),
              child: Icon(
                starIndex <= _rating ? Icons.star : Icons.star_border,
                size: 42,
                color: starIndex <= _rating ? Colors.amber : Colors.grey,
              ),
            );
          }),
        ),
        
        const SizedBox(height: 8),
        
        // Estado de la calificación
        _buildRatingStatus(),
      ],
    );
  }

  Widget _buildRatingStatus() {
    if (_isSubmitting) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: SizedBox(
          height: 20,
          width: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }

    if (_hasRated) {
      return Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
         
          const SizedBox(width: 4),
         
        ],
      );
    }

    return Text(
      _rating == 0 ? 'Toca una estrella para calificar' : 'Calificar con $_rating estrellas',
      style: TextStyle(
        color: _rating == 0 ? Colors.grey : Colors.orange[700],
        fontSize: 14,
      ),
    );
  }

  Future<void> _handleRating(int rating) async {
    final user = AuthService.instance.currentUser;
    
    // Verificar si el usuario está autenticado
    if (user == null) {
      _showLoginRequiredDialog();
      return;
    }

    setState(() {
      _rating = rating;
      _isSubmitting = true;
    });

    try {
      await _submitRating(user.uid, rating);
      
      setState(() {
        _isSubmitting = false;
        _hasRated = true;
      });

      _showSuccessMessage();
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showErrorDialog('Error al enviar calificación: $e');
    }
  }

  Future<void> _submitRating(String userId, int rating) async {
    // Verificar si ya existe una calificación del usuario para este restaurante
    final existingRating = await _db
        .collection('ratings')
        .where('restaurantId', isEqualTo: widget.restaurantId)
        .where('userId', isEqualTo: userId)
        .get();

    if (existingRating.docs.isNotEmpty) {
      // Actualizar calificación existente
      await _db
          .collection('ratings')
          .doc(existingRating.docs.first.id)
          .update({
        'rate': rating,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Crear nueva calificación
      await _db.collection('ratings').add({
        'restaurantId': widget.restaurantId,
        'userId': userId,
        'rate': rating,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }

    // Actualizar la calificación promedio en el restaurante
    await _updateRestaurantAverageRating();
  }

  Future<void> _updateRestaurantAverageRating() async {
    try {
      // Obtener todas las calificaciones del restaurante
      final ratingsSnapshot = await _db
          .collection('ratings')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .get();

      if (ratingsSnapshot.docs.isNotEmpty) {
        double total = 0;
        for (var doc in ratingsSnapshot.docs) {
          final data = doc.data() as Map<String, dynamic>;
          total += (data['rate'] as int).toDouble();
        }
        
        final averageRating = total / ratingsSnapshot.docs.length;
        
        // Actualizar el restaurante con el promedio
        await _db
            .collection('restaurants')
            .doc(widget.restaurantId)
            .update({
          'calificacion': double.parse(averageRating.toStringAsFixed(1)),
          'totalRatings': ratingsSnapshot.docs.length,
        });
      }
    } catch (e) {
      print('Error al actualizar calificación promedio: $e');
      // No mostramos error al usuario ya que la calificación individual sí se guardó
    }
  }

  void _showLoginRequiredDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Iniciar Sesión Requerido'),
          content: const Text(
            'Debes iniciar sesión para calificar restaurantes. '
            '¿Te gustaría ir a la página de inicio de sesión?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancelar'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                Navigator.pushReplacementNamed(context, '/login');
              },
              child: const Text('Iniciar Sesión'),
            ),
          ],
        );
      },
    );
  }

  void _showSuccessMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('¡Calificación enviada: $_rating estrellas!'),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Error'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('OK'),
            ),
          ],
        );
      },
    );
  }

  // Método opcional para cargar calificación existente del usuario
  Future<void> loadUserRating() async {
    final user = AuthService.instance.currentUser;
    if (user != null) {
      try {
        final existingRating = await _db
            .collection('ratings')
            .where('restaurantId', isEqualTo: widget.restaurantId)
            .where('userId', isEqualTo: user.uid)
            .get();

        if (existingRating.docs.isNotEmpty && mounted) {
          final data = existingRating.docs.first.data() as Map<String, dynamic>;
          setState(() {
            _rating = data['rate'] as int;
            _hasRated = true;
          });
        }
      } catch (e) {
        print('Error al cargar calificación existente: $e');
      }
    }
  }

  @override
  void initState() {
    super.initState();
    // Cargar calificación existente cuando el widget se inicializa
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadUserRating();
    });
  }
}