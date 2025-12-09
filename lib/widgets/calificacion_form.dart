import 'package:flutter/material.dart';
import 'package:Sabores_de_mi_Tierra/data/services/auth_service.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalificacionForm extends StatefulWidget {
  final String restaurantId;
  final VoidCallback? onRatingSubmitted; // Callback para notificar cambios

  const CalificacionForm({
    super.key,
    required this.restaurantId,
    this.onRatingSubmitted,
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
          Icon(
            Icons.check_circle,
            color: Colors.green,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '¡Calificado!',
            style: TextStyle(
              color: Colors.green,
              fontSize: 14,
            ),
          ),
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
      
      // Notificar que se completó una calificación
      widget.onRatingSubmitted?.call();
      
    } catch (e) {
      setState(() {
        _isSubmitting = false;
      });
      _showErrorDialog('Error al enviar calificación: $e');
    }
  }

  Future<void> _submitRating(String userId, int rating) async {
    try {
      // 1. Primero, obtener la calificación existente del usuario
      final ratingsQuery = await _db
          .collection('ratings')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      String ratingId;
      final bool isNewRating = ratingsQuery.docs.isEmpty;
      final int? previousRating;

      if (isNewRating) {
        ratingId = _db.collection('ratings').doc().id;
        previousRating = null;
      } else {
        ratingId = ratingsQuery.docs.first.id;
        final data = ratingsQuery.docs.first.data() as Map<String, dynamic>;
        previousRating = data['rate'] as int?;
      }

      // 2. Actualizar/crear la calificación del usuario
      final batch = _db.batch();
      
      final ratingRef = _db.collection('ratings').doc(ratingId);
      
      if (isNewRating) {
        batch.set(ratingRef, {
          'restaurantId': widget.restaurantId,
          'userId': userId,
          'rate': rating,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        batch.update(ratingRef, {
          'rate': rating,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 3. Obtener todas las calificaciones para calcular el nuevo promedio
      final allRatings = await _db
          .collection('ratings')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .get();

      if (allRatings.docs.isEmpty) {
        // No debería pasar si acabamos de crear una
        batch.update(
          _db.collection('restaurants').doc(widget.restaurantId),
          {
            'average_rate': 0.0,
            'total_ratings': 0,
            'last_updated': FieldValue.serverTimestamp(),
          },
        );
      } else {
        // Calcular el nuevo promedio
        double total = 0;
        int count = 0;
        
        for (var doc in allRatings.docs) {
          final data = doc.data() as Map<String, dynamic>;
          if (doc.id == ratingId) {
            // Usar la nueva calificación
            total += rating.toDouble();
          } else {
            total += (data['rate'] as int).toDouble();
          }
          count++;
        }

        // Ajustar si estamos actualizando una calificación existente
        if (previousRating != null && !isNewRating) {
          // Remover la calificación anterior del total si existe
          // Esto ya está cubierto porque estamos reemplazando en el loop
        }

        final average = total / count;
        final roundedAverage = double.parse(average.toStringAsFixed(1));

        // Actualizar el restaurante
        batch.update(
          _db.collection('restaurants').doc(widget.restaurantId),
          {
            'average_rate': roundedAverage,
            'total_ratings': count,
            'last_updated': FieldValue.serverTimestamp(),
          },
        );
      }

      // 4. Ejecutar el batch
      await batch.commit();

      // 5. Forzar una actualización inmediata (opcional)
      await _db.collection('restaurants')
          .doc(widget.restaurantId)
          .update({'force_refresh': FieldValue.serverTimestamp()});

    } catch (e) {
      print('Error en _submitRating: $e');
      rethrow;
    }
  }

  // Versión alternativa más simple sin transacción compleja
  Future<void> _submitRatingSimple(String userId, int rating) async {
    try {
      // 1. Guardar la calificación del usuario
      final ratingsQuery = await _db
          .collection('ratings')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .where('userId', isEqualTo: userId)
          .limit(1)
          .get();

      if (ratingsQuery.docs.isEmpty) {
        await _db.collection('ratings').add({
          'restaurantId': widget.restaurantId,
          'userId': userId,
          'rate': rating,
          'createdAt': FieldValue.serverTimestamp(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
      } else {
        await _db.collection('ratings')
            .doc(ratingsQuery.docs.first.id)
            .update({
          'rate': rating,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      // 2. Calcular y actualizar el promedio
      await _updateAverageRating();

    } catch (e) {
      print('Error en _submitRatingSimple: $e');
      rethrow;
    }
  }

  Future<void> _updateAverageRating() async {
    try {
      // Obtener todas las calificaciones
      final ratingsSnapshot = await _db
          .collection('ratings')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        await _db.collection('restaurants')
            .doc(widget.restaurantId)
            .update({
          'average_rate': 0.0,
          'total_ratings': 0,
        });
        return;
      }

      // Calcular promedio
      double total = 0;
      for (var doc in ratingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['rate'] as int).toDouble();
      }
      
      final average = total / ratingsSnapshot.docs.length;
      final roundedAverage = double.parse(average.toStringAsFixed(1));

      // Actualizar restaurante
      await _db.collection('restaurants')
          .doc(widget.restaurantId)
          .update({
        'average_rate': roundedAverage,
        'total_ratings': ratingsSnapshot.docs.length,
      });

    } catch (e) {
      print('Error en _updateAverageRating: $e');
      // No rethrow - queremos que la calificación individual se guarde
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
    WidgetsBinding.instance.addPostFrameCallback((_) {
      loadUserRating();
    });
  }
}