import 'package:flutter/material.dart';

/// =====================
/// Modelos (mock)
/// =====================
class Restaurant {
  final String nombre;
  final String direccion;
  final double distanciaKm;
  final double rating;
  final String horario;

  Restaurant({
    required this.nombre,
    required this.direccion,
    required this.distanciaKm,
    required this.rating,
    required this.horario,
  });
}

class Dish {
  final String nombre;
  final String imagenUrl;
  final String tipo;       // "Almuerzo" | "Cena"
  final int restaurantes;  // cantidad total
  final double rating;     // 0.0 - 5.0
  final List<Restaurant> disponibles;

  Dish({
    required this.nombre,
    required this.imagenUrl,
    required this.tipo,
    required this.restaurantes,
    required this.rating,
    required this.disponibles,
  });
}

/// =====================
/// Datos Mock
/// =====================
final _mockDishes = <Dish>[
  Dish(
    nombre: 'Pique Macho',
    imagenUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?q=80&w=800',
    tipo: 'Almuerzo',
    restaurantes: 8,
    rating: 4.7,
    disponibles: [
      Restaurant(
        nombre: 'La Casa del Pique',
        direccion: 'Av. América #450, Cochabamba',
        distanciaKm: 1.2,
        rating: 4.7,
        horario: 'Abierto hasta 9 PM',
      ),
      Restaurant(
        nombre: 'Sabores del Valle',
        direccion: 'Calle España #120, Centro',
        distanciaKm: 2.1,
        rating: 4.6,
        horario: 'Abierto hasta 10 PM',
      ),
    ],
  ),
  Dish(
    nombre: 'Sopa de Maní',
    imagenUrl: 'https://i.pinimg.com/736x/71/38/f5/7138f594579a706bab8b17184f591d8b.jpg',
    tipo: 'Almuerzo',
    restaurantes: 6,
    rating: 4.8,
    disponibles: [
      Restaurant(
        nombre: 'La Salteñería Paceña',
        direccion: 'Av. 16 de Julio #1234, La Paz',
        distanciaKm: 1.8,
        rating: 4.8,
        horario: 'Abierto hasta 8 PM',
      ),
      Restaurant(
        nombre: 'Sabores del Altiplano',
        direccion: 'Calle Sagárnaga #456, Centro',
        distanciaKm: 2.5,
        rating: 4.9,
        horario: 'Abierto hasta 10 PM',
      ),
      Restaurant(
        nombre: 'Doña Manuela',
        direccion: 'Av. Blanco Galindo km 5',
        distanciaKm: 3.2,
        rating: 4.7,
        horario: 'Abierto hasta 7 PM',
      ),
    ],
  ),
  Dish(
    nombre: 'Anticuchos',
    imagenUrl: 'https://images.unsplash.com/photo-1553621042-f6e147245754?q=80&w=800',
    tipo: 'Cena',
    restaurantes: 15,
    rating: 4.6,
    disponibles: [
      Restaurant(
        nombre: 'Anticuchería La Grilla',
        direccion: 'C. Aroma #77, Centro',
        distanciaKm: 0.9,
        rating: 4.6,
        horario: 'Abierto hasta 11 PM',
      ),
      Restaurant(
        nombre: 'Brasas Andinas',
        direccion: 'Av. Circunvalación #900',
        distanciaKm: 3.8,
        rating: 4.5,
        horario: 'Abierto hasta 12 AM',
      ),
    ],
  ),
];

/// =====================
/// Pantalla Catálogo
/// =====================
class DishCatalogPage extends StatelessWidget {
  const DishCatalogPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFEF3F3),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Catálogo de Platos',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.separated(
                  itemCount: _mockDishes.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 14),
                  itemBuilder: (context, index) {
                    final d = _mockDishes[index];
                    return _DishCard(dish: d);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =====================
/// Card de Plato
/// =====================
class _DishCard extends StatelessWidget {
  final Dish dish;
  const _DishCard({required this.dish});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.white,
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          builder: (_) => DishDetailSheet(dish: dish),
        );
      },
      child: Card(
        elevation: 2.5,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Imagen
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  dish.imagenUrl,
                  width: 100,
                  height: 90,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 12),

              // Centro
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      dish.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.location_on, size: 16, color: Colors.grey),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            '${dish.restaurantes} restaurantes',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Derecha: limitado para evitar overflow
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 92),
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerRight,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: dish.tipo == 'Cena' ? Colors.orange[400] : Colors.amber[600],
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          dish.tipo,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star, color: Colors.orange, size: 18),
                          const SizedBox(width: 4),
                          Text(
                            dish.rating.toStringAsFixed(1),
                            style: const TextStyle(color: Colors.black87),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// =====================
/// Modal de Detalle
/// =====================
class DishDetailSheet extends StatelessWidget {
  final Dish dish;
  const DishDetailSheet({super.key, required this.dish});

  @override
  Widget build(BuildContext context) {
    final themeText = const TextStyle(color: Colors.black87);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, controller) {
        return SingleChildScrollView(
          controller: controller,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header con título y cerrar
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      dish.nombre,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Imagen grande
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.network(
                  dish.imagenUrl,
                  height: 180,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 12),

              // Fila: chip de tipo + rating
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: dish.tipo == 'Cena' ? Colors.orange[400] : Colors.amber[600],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      dish.tipo,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.star, color: Colors.orange),
                  const SizedBox(width: 4),
                  Text(dish.rating.toStringAsFixed(1), style: themeText),
                ],
              ),
              const SizedBox(height: 14),

              // Título sección
              Row(
                children: [
                  const Icon(Icons.group_outlined, color: Colors.black54),
                  const SizedBox(width: 8),
                  Text(
                    'Restaurantes Disponibles (${dish.disponibles.length})',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Lista de restaurantes
              ...dish.disponibles.map((r) => _RestaurantCard(r)),
            ],
          ),
        );
      },
    );
  }
}

/// =====================
/// Card de Restaurante
/// =====================
class _RestaurantCard extends StatelessWidget {
  final Restaurant r;
  const _RestaurantCard(this.r);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.black12),
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            offset: Offset(0, 2),
            color: Color(0x14000000),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre + distancia
          Row(
            children: [
              Expanded(
                child: Text(
                  r.nombre,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.black87,
                  ),
                ),
              ),
              Text('${r.distanciaKm.toStringAsFixed(1)} km',
                  style: const TextStyle(color: Colors.black54)),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            r.direccion,
            style: const TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(Icons.star, color: Colors.orange, size: 18),
              const SizedBox(width: 4),
              Text(r.rating.toStringAsFixed(1),
                  style: const TextStyle(color: Colors.black87)),
              const SizedBox(width: 16),
              const Text('•', style: TextStyle(color: Colors.black26)),
              const SizedBox(width: 16),
              Text('Abierto hasta ${r.horario.split(" ").last}',
                  style: const TextStyle(color: Colors.black54)),
            ],
          ),
        ],
      ),
    );
  }
}
