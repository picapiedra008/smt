import 'dart:math';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Sabores_de_mi_Tierra/domain/models/food.dart';
import 'package:Sabores_de_mi_Tierra/models/restaurant.dart';
import 'package:Sabores_de_mi_Tierra/widgets/bottom_nav_var.dart';
import 'package:Sabores_de_mi_Tierra/ui/home/view_model/restaurant_detail_screen.dart';

/// Caché para no repetir queries de restaurantes por nombre de plato
final Map<String, Future<List<Restaurant>>> _restaurantsByFoodCache = {};

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  Future<List<Food>>? _foodsFuture;
  List<QueryDocumentSnapshot>? _lastDocs;

  void _updateFoodsFuture(List<QueryDocumentSnapshot> docs) {
    // Obtenemos solo la lista de IDs actuales
    final newIds = docs.map((d) => d.id).toList();

    // Si ya tenemos lastDocs y los IDs son iguales, no recalculamos
    if (_lastDocs != null) {
      final oldIds = _lastDocs!.map((d) => d.id).toList();

      if (_listsAreEqual(newIds, oldIds)) {
        return; // no vuelve a ejecutar _filterFoodsForToday
      }
    }

    // Si cambió la lista de docs, actualizamos future
    _lastDocs = List.from(docs);
    _foodsFuture = _filterFoodsForToday(docs);
  }

  bool _listsAreEqual(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

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

          // Actualizamos (o reutilizamos) el Future solo cuando cambian los docs
          _updateFoodsFuture(docs);

          return FutureBuilder<List<Food>>(
            future: _foodsFuture,
            builder: (context, fSnap) {
              if (fSnap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (fSnap.hasError) {
                return Center(
                  child: Text('Error al filtrar platos: ${fSnap.error}'),
                );
              }

              final foods = fSnap.data ?? [];

              if (foods.isEmpty) {
                return const Center(
                  child: Text('Hoy no hay platos disponibles.'),
                );
              }

              // Plato del día aleatorio pero estable por día
              final now = DateTime.now();
              final seed = now.year * 10000 + now.month * 100 + now.day;
              final random = Random(seed);
              final featured = foods[random.nextInt(foods.length)];

              // base del catálogo: todos menos el destacado
              final baseCatalog =
                  foods.where((food) => food.id != featured.id).toList();

              // aplicar filtro del buscador (en memoria)
              final catalogFoods =
                  _filterFoodsBySearch(baseCatalog, _searchQuery);

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

                    // 🔍 BUSCADOR (solo busca al tocar el botón o Enter)
                    TextField(
                      controller: _searchController,
                      onSubmitted: (value) {
                        setState(() {
                          _searchQuery = value;
                        });
                      },
                      decoration: InputDecoration(
                        hintText: 'Buscar platos...',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.search),
                          onPressed: () {
                            setState(() {
                              _searchQuery = _searchController.text;
                              // si está vacío, _filterFoodsBySearch devuelve todos
                            });
                          },
                        ),
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
                      children: catalogFoods
                          .map((food) => _CatalogFoodCard(food: food))
                          .toList(),
                    ),
                  ],
                ),
              );
            },
          );
        },
      ),
    );
  }
}

/// ----------- CARD DEL PLATO DESTACADO -----------
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

                      // contador dinámico de restaurantes
                      FutureBuilder<List<Restaurant>>(
                        future: _fetchRestaurantsByFoodName(food.nombre),
                        builder: (context, snapshot) {
                          if (!snapshot.hasData) {
                            return Text(
                              '— restaurantes',
                              style: TextStyle(
                                color: Colors.grey.shade700,
                                fontSize: 12,
                              ),
                            );
                          }

                          final count = snapshot.data!.length;
                          final label = count == 1
                              ? '1 restaurante'
                              : '$count restaurantes';

                          return Text(
                            label,
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 12,
                            ),
                          );
                        },
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

/// ----------- CARD DE CADA PLATO EN EL CATÁLOGO -----------
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

            // contador dinámico de restaurantes
            FutureBuilder<List<Restaurant>>(
              future: _fetchRestaurantsByFoodName(food.nombre),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Text('— restaurantes');
                }

                final count = snapshot.data!.length;
                final label =
                    count == 1 ? '1 restaurante' : '$count restaurantes';

                return Text(label);
              },
            ),

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
                    final nombreRest =
                        data['name'] ?? data['nombre'] ?? "Restaurante";

                    return Text(
                      nombreRest,
                      style: theme.textTheme.bodyMedium,
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            Chip(
              label: Text(food.tipo),
              backgroundColor: Colors.orange.shade100,
              labelStyle: const TextStyle(
                color: Colors.orange,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

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
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  RestaurantDetailScreen(restaurant: restaurant),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: _buildRestaurantLogo(
                  restaurant.logoBase64,
                  width: 60,
                  height: 60,
                ),
              ),
              const SizedBox(width: 12),
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
  return _buildFoodImage(
    logoBase64,
    width: width,
    height: height,
    fit: BoxFit.cover,
  );
}

/// ------------ BÚSQUEDA DE RESTAURANTES POR NOMBRE DE PLATO ------------
Future<List<Restaurant>> _fetchRestaurantsByFoodName(String foodName) {
  final db = FirebaseFirestore.instance;

  final searchNorm = _normalizeText(foodName);

  final cached = _restaurantsByFoodCache[searchNorm];
  if (cached != null) return cached;

  final future = () async {
    final todayIndex = DateTime.now().weekday % 7; // 0=domingo, 6=sábado
    final now = DateTime.now();
    final nowMinutes = now.hour * 60 + now.minute;

    final foodsSnap = await db.collection('foods').get();

    final Set<String> restaurantIds = {};

    for (final doc in foodsSnap.docs) {
      final data = doc.data() as Map<String, dynamic>;

      final rawName = (data['name'] ?? data['nombre'] ?? '').toString();
      final nameNorm = _normalizeText(rawName);
      if (!nameNorm.contains(searchNorm)) continue;

      final dishVisibility =
          (data['visibility'] ?? data['visibilidad'] ?? 'publico')
              .toString()
              .toLowerCase();
      if (dishVisibility == 'oculto') continue;

      final dishDays = data['days'];
      if (dishDays != null && dishDays is List) {
        if (todayIndex < 0 || todayIndex >= dishDays.length) continue;
        if (dishDays[todayIndex] == false) continue;
      }

      final restaurantId = data['restaurantId'] as String?;
      if (restaurantId == null || restaurantId.isEmpty) continue;

      restaurantIds.add(restaurantId);
    }

    if (restaurantIds.isEmpty) return <Restaurant>[];

    final List<Restaurant> restaurantes = [];
    const chunkSize = 10;
    final ids = restaurantIds.toList();

    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(
        i,
        i + chunkSize > ids.length ? ids.length : i + chunkSize,
      );

      final rsSnap = await db
          .collection('restaurants')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      for (final rDoc in rsSnap.docs) {
        final rData = rDoc.data() as Map<String, dynamic>? ?? {};

        final restVisibility =
            (rData['visibility'] ?? rData['visibilidad'] ?? 'publico')
                .toString()
                .toLowerCase();
        if (restVisibility == 'oculto') continue;

        Map<String, dynamic>? schedule;

        if (rData['openingHours'] is List &&
            (rData['openingHours'] as List).isNotEmpty) {
          final first = (rData['openingHours'] as List).first;
          if (first is Map<String, dynamic>) schedule = first;
        } else if (rData['openingHours'] is Map<String, dynamic>) {
          final first = (rData['openingHours'] as Map<String, dynamic>)['0'];
          if (first is Map<String, dynamic>) schedule = first;
        } else if (rData['0'] is Map<String, dynamic>) {
          schedule = rData['0'] as Map<String, dynamic>;
        }

        if (schedule != null) {
          final rDays = schedule['days'] as List<dynamic>?;
          if (rDays != null) {
            if (todayIndex < 0 || todayIndex >= rDays.length) continue;
            if (rDays[todayIndex] == false) continue;
          }

          final openingStr = schedule['openingTime'] as String?;
          final closingStr = schedule['closingTime'] as String?;

          if (openingStr != null && closingStr != null) {
            final openMinutes = _timeStringToMinutes(openingStr);
            final closeMinutes = _timeStringToMinutes(closingStr);

            if (openMinutes != null && closeMinutes != null) {
              final isOpenNow =
                  nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
              if (!isOpenNow) continue;
            }
          }
        }

        restaurantes.add(Restaurant.fromFirestore(rDoc));
      }
    }

    return restaurantes;
  }();

  _restaurantsByFoodCache[searchNorm] = future;
  return future;
}

String _normalizeText(String input) {
  var s = input.toLowerCase();

  const accents = 'áàäâãéèëêíìïîóòöôõúùüûñ';
  const normal = 'aaaaaeeeeiiiiooooouuuun';

  for (var i = 0; i < accents.length; i++) {
    s = s.replaceAll(accents[i], normal[i]);
  }

  return s;
}

/// Búsqueda en memoria (para el catálogo)
List<Food> _filterFoodsBySearch(List<Food> foods, String query) {
  final q = _normalizeText(query.trim());
  if (q.isEmpty) return foods;

  return foods.where((food) {
    final nameNorm = _normalizeText(food.nombre);
    final descNorm = _normalizeText(food.descripcion ?? '');
    return nameNorm.contains(q) || descNorm.contains(q);
  }).toList();
}

/// Filtra los platos para el día de hoy considerando:
/// - visibility del plato (publico/oculto)
/// - days[] del plato
/// - visibility del restaurante
/// - días del restaurante
/// - horario (openingTime - closingTime) del restaurante
Future<List<Food>> _filterFoodsForToday(
  List<QueryDocumentSnapshot> docs,
) async {
  final db = FirebaseFirestore.instance;

  final todayIndex = DateTime.now().weekday % 7; // 0=domingo, 6=sábado
  final now = DateTime.now();
  final nowMinutes = now.hour * 60 + now.minute;

  final List<Food> result = [];

  for (final d in docs) {
    final data = d.data() as Map<String, dynamic>;

    final dishVisibility =
        (data['visibility'] ?? data['visibilidad'] ?? 'publico')
            .toString()
            .toLowerCase();
    if (dishVisibility == 'oculto') continue;

    final dishDays = data['days'];
    if (dishDays != null && dishDays is List) {
      if (todayIndex < 0 || todayIndex >= dishDays.length) continue;
      if (dishDays[todayIndex] == false) continue;
    }

    final restaurantId = data['restaurantId'] as String?;
    if (restaurantId == null || restaurantId.isEmpty) continue;

    final rSnap =
        await db.collection('restaurants').doc(restaurantId).get();
    if (!rSnap.exists) continue;

    final rData = rSnap.data() as Map<String, dynamic>? ?? {};

    final restVisibility =
        (rData['visibility'] ?? rData['visibilidad'] ?? 'publico')
            .toString()
            .toLowerCase();
    if (restVisibility == 'oculto') continue;

    Map<String, dynamic>? schedule;

    if (rData['openingHours'] is List &&
        (rData['openingHours'] as List).isNotEmpty) {
      final first = (rData['openingHours'] as List).first;
      if (first is Map<String, dynamic>) schedule = first;
    } else if (rData['openingHours'] is Map<String, dynamic>) {
      final first = (rData['openingHours'] as Map<String, dynamic>)['0'];
      if (first is Map<String, dynamic>) schedule = first;
    } else if (rData['0'] is Map<String, dynamic>) {
      schedule = rData['0'] as Map<String, dynamic>;
    }

    if (schedule != null) {
      final rDays = schedule['days'] as List<dynamic>?;
      if (rDays != null) {
        if (todayIndex < 0 || todayIndex >= rDays.length) continue;
        if (rDays[todayIndex] == false) continue;
      }

      final openingStr = schedule['openingTime'] as String?;
      final closingStr = schedule['closingTime'] as String?;

      if (openingStr != null && closingStr != null) {
        final openMinutes = _timeStringToMinutes(openingStr);
        final closeMinutes = _timeStringToMinutes(closingStr);

        if (openMinutes != null && closeMinutes != null) {
          final isOpenNow =
              nowMinutes >= openMinutes && nowMinutes <= closeMinutes;
          if (!isOpenNow) continue;
        }
      }
    }

    result.add(Food.fromFirestore(d));
  }

  return result;
}

int? _timeStringToMinutes(String time) {
  try {
    final parts = time.split(':');
    if (parts.length != 2) return null;
    final h = int.parse(parts[0]);
    final m = int.parse(parts[1]);
    if (h < 0 || h > 23 || m < 0 || m > 59) return null;
    return h * 60 + m;
  } catch (_) {
    return null;
  }
}
