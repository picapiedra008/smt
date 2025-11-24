import 'package:cloud_firestore/cloud_firestore.dart';

class Dish {
  final String id;
  final String nombre;
  final String? descripcion;
  final String imagenUrl;
  final String? imagenBase64; 
  final String tipo;
  final int restaurantes;
  final double rating;
  final String restaurantId;

  Dish({
    required this.id,
    required this.nombre,
    this.descripcion,
    required this.imagenUrl,
    this.imagenBase64,
    required this.tipo,
    required this.restaurantes,
    required this.rating,
    required this.restaurantId,
  });

  factory Dish.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>? ?? {});

    return Dish(
      id: doc.id,

      // ← primero buscamos 'name' porque tu BD lo usa
      nombre: (d['name'] ?? d['nombre'] ?? 'Sin nombre') as String,

      descripcion: (d['descripcion'] ?? d['description']) as String?,

      imagenUrl: (d['imagen'] ?? d['imageUrl'] ?? d['image'] ?? '') as String,
      imagenBase64: d['imagenBase64'] as String?,

      tipo: (d['tipo'] ?? d['category'] ?? '') as String,

      restaurantes: (d['restaurantes'] ?? d['restaurantsCount'] ?? 0) is int
          ? (d['restaurantes'] ?? d['restaurantsCount'] ?? 0)
          : int.tryParse((d['restaurantes'] ?? '0').toString()) ?? 0,

      rating: (d['rating'] ?? 0).toDouble(),

      restaurantId: (d['restaurantId'] ?? '') as String,
    );
  }
}
