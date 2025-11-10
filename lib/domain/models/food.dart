import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  final String id;
  final String nombre;
  final String? descripcion;
  final String imagen;
  final int restaurantes;
  final String tipo;
  final double rating;

  Food({
    required this.id,
    required this.nombre,
    required this.imagen,
    required this.restaurantes,
    required this.tipo,
    required this.rating,
    this.descripcion,
  });

  factory Food.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    return Food(
      id: doc.id,
      nombre: data['nombre'] ?? 'Sin nombre',
      descripcion: data['descripcion'],
      imagen: data['imagen'] ?? '',
      restaurantes: (data['restaurantes'] ?? 0) is int
          ? data['restaurantes'] as int
          : int.tryParse(data['restaurantes'].toString()) ?? 0,
      tipo: data['tipo'] ?? '',
      rating: (data['rating'] ?? 0.0) is num
          ? (data['rating'] as num).toDouble()
          : double.tryParse(data['rating'].toString()) ?? 0.0,
    );
  }
}
