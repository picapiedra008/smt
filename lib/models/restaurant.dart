import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String nombre;

  // Si es un string, igual lo seguimos guardando aquí
  final String location;

  // Nuevo: soporte real para GeoPoint
  final GeoPoint? locationGeo;

  final double distanciaKm;
  final double rating;
  final String horario;

  // Opcionales
  final String? descripcion;
  final String? logoBase64;
  final Map<String, dynamic>? rawOpeningHours;

  Restaurant({
    required this.nombre,
    required this.location,
    required this.distanciaKm,
    required this.rating,
    required this.horario,
    this.descripcion,
    this.logoBase64,
    this.rawOpeningHours,
    this.locationGeo, // <-- NUEVO
  });

  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>? ?? {});

    final nombre = (d['name'] ?? d['nombre'] ?? 'Sin nombre') as String;

    // ================================
    // 1) Manejar ubicación: GeoPoint o String
    // ================================
    String locationStr = '';
    GeoPoint? locationGeo;

    if (d['location'] != null) {
      final loc = d['location'];

      if (loc is GeoPoint) {
        locationGeo = loc;
        locationStr =
            '${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)}';
      } else if (loc is String) {
        locationStr = loc;
      } else if (loc is Map && loc['address'] != null) {
        locationStr = loc['address'].toString();
      }
    }

    // Si no había nada, deja vacío
    locationStr = locationStr.isNotEmpty ? locationStr : '';

    // ================================
    // 2) Rating
    // ================================
    final rawRating = d['rating'] ?? 0;
    final rating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse(rawRating.toString()) ?? 0.0;

    // ================================
    // 3) Distancia
    // ================================
    final rawDist = d['distanciaKm'] ?? d['distanceKm'] ?? 0;
    final distanciaKm = rawDist is num
        ? rawDist.toDouble()
        : double.tryParse(rawDist.toString()) ?? 0.0;

    // ================================
    // 4) Descripción y logo
    // ================================
    final descripcion = d['description'] as String? ?? d['descripcion'] as String?;
    final logoBase64 = d['logoBase64'] as String?;

    // ================================
    // 5) Horario
    // ================================
    String horarioStr = '';
    Map<String, dynamic>? rawOpening;

    try {
      final opening = d['openingHours'] ??
          d['opening_hours'] ??
          d['schedule'] ??
          d['horario'];

      if (opening == null) {
        horarioStr = '';
      } else if (opening is String) {
        horarioStr = opening;
      } else if (opening is Map<String, dynamic>) {
        rawOpening = opening;

        final open = opening['openingTime'] ??
            opening['open'] ??
            opening['start'];

        final close = opening['closingTime'] ??
            opening['close'] ??
            opening['end'];

        if (open != null && close != null) {
          horarioStr = "$open - $close";
        } else {
          horarioStr = opening.toString();
        }
      } else if (opening is List) {
        if (opening.isNotEmpty && opening[0] is Map) {
          final first = Map<String, dynamic>.from(opening[0]);
          rawOpening = first;

          final o = first['openingTime'] ?? first['open'];
          final c = first['closingTime'] ?? first['close'];

          if (o != null && c != null) {
            horarioStr = "$o - $c";
          } else {
            horarioStr = first.toString();
          }
        }
      }
    } catch (_) {
      horarioStr = '';
    }

    if (horarioStr.isEmpty) horarioStr = 'No especificado';

    return Restaurant(
      nombre: nombre,
      location: locationStr,
      locationGeo: locationGeo, // 🟢 YA DEVUELVE GEOPUNTOS
      distanciaKm: distanciaKm,
      rating: rating,
      horario: horarioStr,
      descripcion: descripcion,
      logoBase64: logoBase64,
      rawOpeningHours: rawOpening,
    );
  }
}
