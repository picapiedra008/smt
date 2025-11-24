import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Sabores_de_mi_Tierra/domain/models/food.dart';
import 'package:Sabores_de_mi_Tierra/widgets/bottom_nav_var.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sabores de mi Tierra'),
        centerTitle: true,
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 0),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('foods').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los platos'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text('No hay platos registrados.'));
          }

          final docs = snapshot.data!.docs;
          final foods = docs.map((d) => Food.fromFirestore(d)).toList();

          // 🔥 Plato del día aleatorio pero estable por día
          final now = DateTime.now();
          final seed = now.year * 10000 + now.month * 100 + now.day;
          final random = Random(seed);
          final featured = foods[random.nextInt(foods.length)];

          final otrosPlatos = foods
              .where((food) => food.id != featured.id)
              .toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Recomendado hoy',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),

                // 🟥 Carta del "Plato del Día"
                _FeaturedFoodCard(food: featured),

                const SizedBox(height: 20),

                // Buscador (solo vista por ahora)
                TextField(
                  decoration: InputDecoration(
                    hintText: 'Buscar platos...',
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: theme.colorScheme.surface,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),

                const SizedBox(height: 20),
                Text(
                  'Catálogo de Platos',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),

                Column(
                  children: otrosPlatos
                      .map((food) => _CatalogFoodCard(food: food))
                      .toList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _FeaturedFoodCard extends StatelessWidget {
  final Food food;

  const _FeaturedFoodCard({required this.food});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FoodDetailScreen(food: food)),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 4,
        clipBehavior: Clip.antiAlias,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
          side: BorderSide(
            color: isDark ? Colors.grey.shade700 : Colors.grey.shade300,
            width: 1.5, // grosor del borde
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen + etiqueta
            Stack(
              children: [
                SizedBox(
                  height: 190,
                  width: double.infinity,
                  child: _buildFoodImage(
                    food.imagenBase64,
                    width: double.infinity,
                    height: 190,
                    fit: BoxFit.cover,
                  ),
                ),
                Positioned(
                  top: 12,
                  left: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.redAccent,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Plato del Día',
                      style: TextStyle(color: Colors.white, fontSize: 12),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(
                left: 16,
                right: 16,
                top: 12,
                bottom: 12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food.nombre,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (food.descripcion != null && food.descripcion!.isNotEmpty)
                    Text(
                      food.descripcion!,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 13,
                      ),
                    ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Icon(
                        Icons.store_mall_directory,
                        size: 16,
                        color: Colors.grey,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '1 restaurante',
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontSize: 12,
                        ),
                      ),
                      const Spacer(),
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        food.rating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CatalogFoodCard extends StatelessWidget {
  final Food food;

  const _CatalogFoodCard({required this.food});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: BorderRadius.circular(15),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => FoodDetailScreen(food: food)),
        );
      },
      child: Card(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
          side: BorderSide(
            color: isDark
                ? Colors.grey.shade700
                : Colors.grey.shade300, // borde visible en oscuro
            width: 1.2,
          ),
        ),
        margin: const EdgeInsets.symmetric(vertical: 8),
        elevation: 3,
        child: Container(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              // 📌 Imagen a la izquierda
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 120,
                  height: 120,
                  child: _buildFoodImage(food.imagenBase64, fit: BoxFit.cover),
                ),
              ),

              const SizedBox(width: 12),

              // 📌 Información del plato
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // 🌟 Fila con nombre a la izquierda y estrellas a la derecha
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Nombre del plato
                        Expanded(
                          child: Text(
                            food.nombre,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        // Estrellas + puntuación
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 3),
                            Text(
                              food.rating.toStringAsFixed(1),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Restaurante
                    const Text(
                      '1 restaurante',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),

                    const SizedBox(height: 8),

                    // Chip de tipo de comida
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      child: Wrap(
                        crossAxisAlignment: WrapCrossAlignment.center,
                        spacing: 4,
                        children: [
                          Text(
                            food.tipo,
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// 🆕 Pantalla de detalle del plato completamente corregida
class FoodDetailScreen extends StatelessWidget {
  final Food food;

  const FoodDetailScreen({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(food.nombre)),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            /// Imagen corregida → ahora usa imageBase64
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: _buildFoodImage(food.imagenBase64, fit: BoxFit.cover),
              ),
            ),

            const SizedBox(height: 16),

            /// Rating + restaurante al que pertenece
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber),
                const SizedBox(width: 4),
                Text(
                  food.rating.toStringAsFixed(1),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 20),

                /// Mostrar nombre del restaurante (consulta Firestore)
                const Icon(Icons.store_mall_directory, size: 20),
                const SizedBox(width: 6),

                StreamBuilder<DocumentSnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('restaurants')
                      .doc(food.restaurantId)
                      .snapshots(),
                  builder: (context, snap) {
                    if (!snap.hasData || !snap.data!.exists) {
                      return Text(
                        "Restaurante no disponible",
                        style: theme.textTheme.bodyMedium,
                      );
                    }

                    final data =
                        snap.data!.data() as Map<String, dynamic>? ?? {};
                    final nombreRest = data['name'] ?? "Restaurante";

                    return Text(nombreRest, style: theme.textTheme.bodyMedium);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            /// Tipo del plato
            Chip(
              label: Text(food.tipo),
              backgroundColor: Colors.orange.shade100,
              labelStyle: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14), // bordes redondeados
                side: const BorderSide(
                  color: Colors.orange, // color del borde
                  width: 1.5, // grosor del borde
                ),
              ),
            ),
            const SizedBox(height: 16),

            /// Descripción
            if (food.descripcion != null && food.descripcion!.isNotEmpty)
              Text(food.descripcion!, style: theme.textTheme.bodyMedium)
            else
              Text(
                'Sin descripción disponible.',
                style: theme.textTheme.bodyMedium!.copyWith(
                  color: Colors.grey.shade600,
                ),
              ),

            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}

/// ------------ Helpers para imagen (Base64 o URL) ------------

Widget _buildFoodImage(
  String imagen, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (imagen.isEmpty) {
    return _foodImagePlaceholder(width, height);
  }

  // 1) Intentar como Base64
  try {
    String base64String = imagen;

    // Si viene como 'data:image/png;base64,AAAA...'
    if (base64String.startsWith('data:image')) {
      base64String = base64String.split(',').last;
    }

    base64String = base64String.trim();

    // Ajustar padding (longitud múltiplo de 4)
    final remainder = base64String.length % 4;
    if (remainder != 0) {
      base64String = base64String.padRight(
        base64String.length + (4 - remainder),
        '=',
      );
    }

    final bytes = base64Decode(base64String);

    return Image.memory(bytes, width: width, height: height, fit: fit);
  } catch (e) {
    debugPrint('No es Base64 válido o falló decode: $e');
  }

  // 2) Si no era Base64, probar como URL normal
  return Image.network(
    imagen,
    width: width,
    height: height,
    fit: fit,
    errorBuilder: (context, error, stackTrace) {
      debugPrint('Error cargando imagen por URL: $error');
      return _foodImagePlaceholder(width, height);
    },
  );
}

Widget _foodImagePlaceholder(double? width, double? height) {
  return Container(
    width: width,
    height: height,
    color: Colors.grey[300],
    alignment: Alignment.center,
    child: const Icon(Icons.image_not_supported, color: Colors.grey, size: 40),
  );
}
