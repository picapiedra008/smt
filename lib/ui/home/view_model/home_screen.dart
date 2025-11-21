import 'dart:math';
import 'dart:convert';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:food_point/domain/models/food.dart';
import 'package:food_point/models/restaurant.dart';
import 'package:food_point/widgets/bottom_nav_var.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sabores de Cochabamba'),
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

          // Plato del día aleatorio pero estable por día
          final now = DateTime.now();
          final seed = now.year * 10000 + now.month * 100 + now.day;
          final random = Random(seed);
          final featured = foods[random.nextInt(foods.length)];

          final otrosPlatos =
              foods.where((food) => food.id != featured.id).toList();

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

                _FeaturedFoodCard(food: featured),

                const SizedBox(height: 20),

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

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FoodDetailScreen(food: food),
          ),
        );
      },
      borderRadius: BorderRadius.circular(18),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
                        horizontal: 10, vertical: 4),
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
                  left: 16, right: 16, top: 12, bottom: 12),
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
                  if (food.descripcion != null &&
                      food.descripcion!.isNotEmpty)
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
                      const Icon(Icons.store_mall_directory,
                          size: 16, color: Colors.grey),
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
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.all(10),
        leading: ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: _buildFoodImage(
            food.imagenBase64,
            width: 70,
            height: 70,
            fit: BoxFit.cover,
          ),
        ),
        title: Text(
          food.nombre,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            const Text('1 restaurante'),
            const SizedBox(height: 4),
            Row(
              children: [
                Chip(
                  label: Text(food.tipo),
                  backgroundColor: Colors.orange.shade100,
                  labelStyle: const TextStyle(
                    color: Colors.orange,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                const Icon(Icons.star, color: Colors.amber, size: 20),
                Text(
                  food.rating.toStringAsFixed(1),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ],
        ),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => FoodDetailScreen(food: food),
            ),
          );
        },
      ),
    );
  }
}

/// ------------ DETALLE DEL PLATO + LISTA DE RESTAURANTES ------------
class FoodDetailScreen extends StatelessWidget {
  final Food food;

  const FoodDetailScreen({super.key, required this.food});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(food.nombre),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen grande
            ClipRRect(
              borderRadius: BorderRadius.circular(18),
              child: SizedBox(
                height: 220,
                width: double.infinity,
                child: _buildFoodImage(
                  food.imagenBase64,
                  fit: BoxFit.cover,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Rating + restaurante propietario
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
                    final nombreRest = data['name'] ?? data['nombre'] ?? "Restaurante";

                    return Text(
                      nombreRest,
                      style: theme.textTheme.bodyMedium,
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Tipo
            Chip(
              label: Text(food.tipo),
              backgroundColor: Colors.orange.shade100,
              labelStyle: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 16),

            // Descripción
            if (food.descripcion != null && food.descripcion!.isNotEmpty)
              Text(
                food.descripcion!,
                style: theme.textTheme.bodyMedium,
              )
            else
              Text(
                'Sin descripción disponible.',
                style: theme.textTheme.bodyMedium!
                    .copyWith(color: Colors.grey.shade600),
              ),

            const SizedBox(height: 24),

            // ---------- NUEVA SECCIÓN: LISTA DE RESTAURANTES ----------
            Row(
              children: [
                const Icon(Icons.store_mall_directory_outlined,
                    color: Colors.white),
                const SizedBox(width: 8),
                Text(
                  'Restaurantes que ofrecen este plato',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),

            FutureBuilder<List<Restaurant>>(
              future: _fetchRestaurantsByFoodName(food.nombre),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 16),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                if (snap.hasError) {
                  return Text(
                    'Error al cargar restaurantes: ${snap.error}',
                    style: theme.textTheme.bodyMedium,
                  );
                }

                final rs = snap.data ?? [];
                if (rs.isEmpty) {
                  return Text(
                    'Aún no hay otros restaurantes que ofrezcan este plato.',
                    style: theme.textTheme.bodyMedium,
                  );
                }

                return Column(
                  children: rs
                      .map((r) => _RestaurantCard(restaurant: r))
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// ------------ CARD PARA CADA RESTAURANTE ------------
class _RestaurantCard extends StatelessWidget {
  final Restaurant restaurant;

  const _RestaurantCard({required this.restaurant});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: Colors.grey.shade900,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          // TODO: aquí luego puedes navegar al detalle del restaurante
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen del restaurante
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildRestaurantLogo(
                  restaurant.logoBase64,
                  width: 60,
                  height: 60,
                ),
              ),
              const SizedBox(width: 12),

              // Nombre + descripción (recortada)
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurant.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 4),
                    if (restaurant.descripcion != null &&
                        restaurant.descripcion!.isNotEmpty)
                      Text(
                        restaurant.descripcion!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                        ),
                      ),
                  ],
                ),
              ),

              const SizedBox(width: 8),

              // Rating a la derecha
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star, color: Colors.amber, size: 18),
                      const SizedBox(width: 4),
                      Text(
                        restaurant.rating.toStringAsFixed(1),
                        style: const TextStyle(color: Colors.white),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}


/// ------------ Helpers de imagen (Base64 o URL) ------------
Widget _buildFoodImage(
  String imagen, {
  double? width,
  double? height,
  BoxFit fit = BoxFit.cover,
}) {
  if (imagen.isEmpty) {
    return _foodImagePlaceholder(width, height);
  }

  try {
    String base64String = imagen;
    if (base64String.startsWith('data:image')) {
      base64String = base64String.split(',').last;
    }
    base64String = base64String.trim();

    final remainder = base64String.length % 4;
    if (remainder != 0) {
      base64String =
          base64String.padRight(base64String.length + (4 - remainder), '=');
    }

    final bytes = base64Decode(base64String);

    return Image.memory(
      bytes,
      width: width,
      height: height,
      fit: fit,
    );
  } catch (e) {
    debugPrint('No es Base64 válido o falló decode: $e');
  }

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
    child: const Icon(
      Icons.image_not_supported,
      color: Colors.grey,
      size: 40,
    ),
  );
}

Widget _buildRestaurantLogo(
  String? logoBase64, {
  double? width,
  double? height,
}) {
  if (logoBase64 == null || logoBase64.isEmpty) {
    return _foodImagePlaceholder(width, height);
  }
  // Reutilizamos la misma lógica de _buildFoodImage:
  return _buildFoodImage(
    logoBase64,
    width: width,
    height: height,
    fit: BoxFit.cover,
  );
}

/// ------------ LÓGICA PARA BUSCAR RESTAURANTES POR NOMBRE DE PLATO ------------
/// Busca todos los foods cuyo nombre (name/nombre) CONTENGA [foodName],
/// sin importar mayúsculas ni acentos, y devuelve la lista de restaurantes.
Future<List<Restaurant>> _fetchRestaurantsByFoodName(String foodName) async {
  final db = FirebaseFirestore.instance;
  final searchNorm = _normalizeText(foodName);

  final foodsSnap = await db.collection('foods').get();

  final filteredFoods = foodsSnap.docs.where((doc) {
    final data = doc.data() as Map<String, dynamic>;
    final rawName =
        (data['name'] ?? data['nombre'] ?? '').toString();
    final nameNorm = _normalizeText(rawName);
    return nameNorm.contains(searchNorm);
  }).toList();

  if (filteredFoods.isEmpty) return [];

  final ids = filteredFoods
      .map((d) => (d.data()['restaurantId'] ?? '') as String)
      .where((id) => id.isNotEmpty)
      .toSet()
      .toList();

  if (ids.isEmpty) return [];

  final List<Restaurant> restaurantes = [];
  const chunkSize = 10;

  for (var i = 0; i < ids.length; i += chunkSize) {
    final chunk = ids.sublist(
      i,
      i + chunkSize > ids.length ? ids.length : i + chunkSize,
    );

    final rsSnap = await db
        .collection('restaurants')
        .where(FieldPath.documentId, whereIn: chunk)
        .get();

    restaurantes.addAll(
      rsSnap.docs.map((doc) => Restaurant.fromFirestore(doc)).toList(),
    );
  }

  return restaurantes;
}

String _normalizeText(String input) {
  var s = input.toLowerCase();

  const accents = 'áàäâãéèëêíìïîóòöôõúùüûñ';
  const normal  = 'aaaaaeeeeiiiiooooouuuun';

  for (var i = 0; i < accents.length; i++) {
    s = s.replaceAll(accents[i], normal[i]);
  }

  return s;
}
