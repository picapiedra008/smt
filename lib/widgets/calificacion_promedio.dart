import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CalificacionPromedio extends StatefulWidget {
  final String restaurantId;
  final double? size;
  final Color? color;

  const CalificacionPromedio({
    super.key,
    required this.restaurantId,
    this.size = 18,
    this.color = Colors.amber,
  });

  @override
  State<CalificacionPromedio> createState() => _CalificacionPromedioState();
}

class _CalificacionPromedioState extends State<CalificacionPromedio> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  double _calificacion = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadCalificacionPromedio();
  }

  Future<void> _loadCalificacionPromedio() async {
    try {
      final restaurantDoc = await _db
          .collection('restaurants')
          .doc(widget.restaurantId)
          .get();

      if (restaurantDoc.exists) {
        final data = restaurantDoc.data() as Map<String, dynamic>;
        
        // Si el restaurante ya tiene la calificación calculada, la usamos
        if (data.containsKey('calificacion') && data['calificacion'] != null) {
          if (mounted) {
            setState(() {
              _calificacion = (data['calificacion'] as num).toDouble();
              _isLoading = false;
            });
          }
          return;
        }
      }

      final ratingsSnapshot = await _db
          .collection('ratings')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .get();

      if (ratingsSnapshot.docs.isEmpty) {
        if (mounted) {
          setState(() {
            _calificacion = 0;
            _isLoading = false;
          });
        }
        return;
      }

      double total = 0;
      for (var doc in ratingsSnapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        total += (data['rate'] as int).toDouble();
      }
      
      final promedio = total / ratingsSnapshot.docs.length;
      
      if (mounted) {
        setState(() {
          _calificacion = double.parse(promedio.toStringAsFixed(1));
          _isLoading = false;
        });
      }

      // Actualizamos el restaurante con el promedio calculado para futuras consultas
      await _db
          .collection('restaurants')
          .doc(widget.restaurantId)
          .update({
            'calificacion': _calificacion,
            'totalRatings': ratingsSnapshot.docs.length,
          });

    } catch (e) {
      print('Error al cargar calificación promedio: $e');
      if (mounted) {
        setState(() {
          _calificacion = 0;
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.star,
          color: widget.color,
          size: widget.size,
        ),
        const SizedBox(width: 4),
        _isLoading
            ? SizedBox(
                width: 20,
                height: widget.size,
                child: const CircularProgressIndicator(strokeWidth: 2),
              )
            : Text(
                _calificacion > 0 ? _calificacion.toStringAsFixed(1) : "-",
                style: TextStyle(
                  fontSize: widget.size! * 0.8,
                  fontWeight: FontWeight.w500,
                ),
              ),
      ],
    );
  }
}