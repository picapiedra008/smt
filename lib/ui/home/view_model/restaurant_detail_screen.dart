import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:food_point/models/restaurant.dart';
import 'package:food_point/models/restaurant.dart';

class RestaurantDetailScreen extends StatelessWidget {
  final Restaurant restaurant;

  const RestaurantDetailScreen({super.key, required this.restaurant});

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
            // IMAGEN DEL RESTAURANTE
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

            Text(
              restaurant.nombre,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 10),

            // DIRECCIÓN
            Row(
              children: [
                const Icon(Icons.location_on, size: 20),
                const SizedBox(width: 5),
                Expanded(
                  child: Text(
                    restaurant.location.isNotEmpty
                        ? restaurant.location
                        : "Dirección no disponible",
                    style: const TextStyle(fontSize: 16),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // DISTANCIA
            Row(
              children: [
                const Icon(Icons.map, size: 20),
                const SizedBox(width: 5),
                Text(
                  "${restaurant.distanciaKm.toStringAsFixed(2)} km",
                  style: const TextStyle(fontSize: 16),
                ),
              ],
            ),

            const SizedBox(height: 10),

            // RATING
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

            // HORARIO
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

            // DESCRIPCIÓN
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
