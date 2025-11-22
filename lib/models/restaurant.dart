import 'package:cloud_firestore/cloud_firestore.dart';

class Restaurant {
  final String nombre;
  final String location; // dirección / ubicación en texto
  final double distanciaKm;
  final double rating;
  final String horario; // ya en formato "08:00 - 22:00" o "No especificado"

  // Opcionales
  final String? descripcion;
  final String? logoBase64;
  final Map<String, dynamic>? rawOpeningHours; // por si quieres usar datos crudos

  Restaurant({
    required this.nombre,
    required this.location,
    required this.distanciaKm,
    required this.rating,
    required this.horario,
    this.descripcion,
    this.logoBase64,
    this.rawOpeningHours,
  });

  factory Restaurant.fromFirestore(DocumentSnapshot doc) {
    final d = (doc.data() as Map<String, dynamic>? ?? {});

    final nombre = (d['name'] ?? d['nombre'] ?? 'Sin nombre') as String;

    // 1) Location: puede venir como string "lat,lon", GeoPoint, o un mapa con address
    String locationStr = '';
    if (d['address'] != null && d['address'] is String) {
      locationStr = d['address'] as String;
    } else if (d['location'] != null) {
      final loc = d['location'];
      if (loc is String) {
        // ejemplo: "-17.4013, -66.1715" -> podrías formatearlo o resolver a dirección
        locationStr = loc;
      } else if (loc is GeoPoint) {
        locationStr = '${loc.latitude.toStringAsFixed(6)}, ${loc.longitude.toStringAsFixed(6)}';
      } else if (loc is Map && loc['address'] != null) {
        locationStr = loc['address'].toString();
      } else {
        locationStr = '';
      }
    } else {
      locationStr = '';
    }

    // Rating
    final rawRating = d['rating'] ?? 0;
    final rating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse(rawRating.toString()) ?? 0.0;

    // Distancia (si no la calculas en el cliente, deja 0)
    final rawDist = d['distanciaKm'] ?? d['distanceKm'] ?? 0;
    final distanciaKm = rawDist is num
        ? rawDist.toDouble()
        : double.tryParse(rawDist.toString()) ?? 0.0;

    // Descripción y logo
    final descripcion = d['description'] as String? ?? d['descripcion'] as String?;
    final logoBase64 = d['logoBase64'] as String?;

    // Parseo de openingHours: puede venir como mapa, lista, etc.
    String horarioStr = '';
    Map<String, dynamic>? rawOpening;
    try {
      final opening = d['openingHours'] ?? d['opening_hours'] ?? d['schedule'] ?? d['horario'];
      if (opening == null) {
        horarioStr = '';
      } else if (opening is String) {
        // si ya es una cadena legible
        horarioStr = opening;
      } else if (opening is Map<String, dynamic>) {
        rawOpening = opening;
        // si tiene keys como 'openingTime' y 'closingTime'
        final open = opening['openingTime'] ?? opening['open'] ?? opening['start'];
        final close = opening['closingTime'] ?? opening['close'] ?? opening['end'];
        if (open != null && close != null) {
          horarioStr = '${open.toString()} - ${close.toString()}';
        } else if (opening['0'] != null && opening['0'] is Map) {
          final first = Map<String, dynamic>.from(opening['0']);
          final o = first['openingTime'] ?? first['open'];
          final c = first['closingTime'] ?? first['close'];
          if (o != null && c != null) horarioStr = '${o.toString()} - ${c.toString()}';
        } else {
          // fallback: stringify
          horarioStr = opening.toString();
        }
      } else if (opening is List) {
        // toma el primer elemento y busca openingTime/closingTime
        if (opening.isNotEmpty && opening[0] is Map) {
          final first = Map<String, dynamic>.from(opening[0]);
          rawOpening = first;
          final o = first['openingTime'] ?? first['open'];
          final c = first['closingTime'] ?? first['close'];
          if (o != null && c != null) horarioStr = '${o.toString()} - ${c.toString()}';
          else horarioStr = first.toString();
        } else {
          horarioStr = opening.join(', ');
        }
      } else {
        horarioStr = opening.toString();
      }
    } catch (e) {
      horarioStr = '';
    }

    if (horarioStr.isEmpty) horarioStr = 'No especificado';

    return Restaurant(
      nombre: nombre,
      location: locationStr,
      distanciaKm: distanciaKm,
      rating: rating,
      horario: horarioStr,
      descripcion: descripcion,
      logoBase64: logoBase64,
      rawOpeningHours: rawOpening,
    );
  }
}
