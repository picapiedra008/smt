import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String nombre;
  final String direccion;
  final double distanciaKm;
  final double rating;
  final String horario;

  // NUEVOS (opcionales, no rompen otra parte de tu app)
  final String? descripcion;
  final String? logoBase64;

  Restaurant({
    required this.nombre,
    required this.direccion,
    required this.distanciaKm,
    required this.rating,
    required this.horario,
    this.descripcion,
    this.logoBase64,
  });

  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>? ?? {});

    // En tu Firestore:
    // name: "hola3"
    // description: "el hola 3"
    // logoBase64: "...", location, openingHours...

    final nombre = (d['name'] ?? d['nombre'] ?? 'Sin nombre') as String;
    // como todavía no tienes un address separado, dejamos vacío
    final direccion = (d['address'] ?? d['direccion'] ?? '') as String;

    final rawRating = d['rating'] ?? 0;
    final rating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse(rawRating.toString()) ?? 0.0;

    final rawDist = d['distanciaKm'] ?? d['distanceKm'] ?? 0;
    final distanciaKm = rawDist is num
        ? rawDist.toDouble()
        : double.tryParse(rawDist.toString()) ?? 0.0;

    final horario = (d['horario'] ?? d['schedule'] ?? '') as String;

    final descripcion = d['description'] as String?;
    final logoBase64 = d['logoBase64'] as String?;

    return Restaurant(
      nombre: nombre,
      direccion: direccion,
      distanciaKm: distanciaKm,
      rating: rating,
      horario: horario,
      descripcion: descripcion,
      logoBase64: logoBase64,
    );
  }
}
