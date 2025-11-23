import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:food_point/models/restaurant.dart';
import 'package:url_launcher/url_launcher.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

  void _openMaps() {
    if (restaurant.locationGeo != null) {
      final lat = restaurant.locationGeo!.latitude;
      final lng = restaurant.locationGeo!.longitude;

      final url = Uri.parse(
          "https://www.google.com/maps/search/?api=1&query=$lat,$lng");

      launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      // Si no hay geopoint, intenta con el string "lat,lon"
      final parts = restaurant.location.split(",");
      if (parts.length == 2) {
        final url = Uri.parse(
            "https://www.google.com/maps/search/?api=1&query=${parts[0]},${parts[1]}");

        launchUrl(url, mode: LaunchMode.externalApplication);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    Uint8List? logoBytes;
    if (restaurant.logoBase64 != null && restaurant.logoBase64!.isNotEmpty) {
      try {
        logoBytes = base64Decode(restaurant.logoBase64!.split(',').last);
      } catch (_) {}
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(restaurant.nombre),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// IMAGEN
            ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: logoBytes != null
                  ? Image.memory(
                      logoBytes,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      height: 200,
                      width: double.infinity,
                      color: Colors.grey[300],
                      child: const Icon(Icons.store, size: 100),
                    ),
            ),

            const SizedBox(height: 20),

            /// NOMBRE
            Text(
              restaurant.nombre,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            /// UBICACIÓN
            Row(
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    restaurant.locationGeo != null
                        ? "${restaurant.locationGeo!.latitude}, ${restaurant.locationGeo!.longitude}"
                        : (restaurant.location.isNotEmpty
                            ? restaurant.location
                            : "Ubicación no disponible"),
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),

            /// BOTÓN PARA ABRIR MAPS
            TextButton.icon(
              onPressed: _openMaps,
              icon: const Icon(Icons.map),
              label: const Text("Abrir en Google Maps"),
            ),

            const SizedBox(height: 10),

            /// DISTANCIA
            Row(
              children: [
                const Icon(Icons.directions_walk, size: 20),
                const SizedBox(width: 5),
                Text(
                  "${restaurant.distanciaKm.toStringAsFixed(2)} km",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 10),

            /// RATING
            Row(
              children: [
                const Icon(Icons.star, size: 20, color: Colors.amber),
                const SizedBox(width: 5),
                Text(
                  restaurant.rating.toStringAsFixed(1),
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// HORARIO
            const Text(
              "Horario:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              restaurant.horario.isNotEmpty
                  ? restaurant.horario
                  : "No especificado",
              style: const TextStyle(fontSize: 16),
            ),

            const SizedBox(height: 20),

            /// DESCRIPCIÓN
            const Text(
              "Descripción:",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            Text(
              restaurant.descripcion ?? "Sin descripción.",
              style: const TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
