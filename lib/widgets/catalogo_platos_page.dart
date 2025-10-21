import 'package:flutter/material.dart';

class CatalogoPlatosPage extends StatelessWidget {
  const CatalogoPlatosPage({super.key});

  final List<Map<String, dynamic>> platos = const [
    {
      "title": "Pique Macho",
      "image":
          "https://images.unsplash.com/photo-1604908177522-31b9d6a89f8b?auto=format&fit=crop&w=800&q=60",
      "type": "Almuerzo",
      "restaurants": 8,
      "rating": 4.7
    },
    {
      "title": "Sopa de Maní",
      "image":
          "https://images.unsplash.com/photo-1604908177520-123e6b4b5d46?auto=format&fit=crop&w=800&q=60",
      "type": "Almuerzo",
      "restaurants": 6,
      "rating": 4.8
    },
    {
      "title": "Anticuchos",
      "image":
          "https://images.unsplash.com/photo-1540189549336-e6e99c3679fe?auto=format&fit=crop&w=800&q=60",
      "type": "Cena",
      "restaurants": 15,
      "rating": 4.6
    },
    {
      "title": "Silpancho Cochabambino",
      "image":
          "https://images.unsplash.com/photo-1601050690683-8d5bf7f7b9c7?auto=format&fit=crop&w=800&q=60",
      "type": "Almuerzo",
      "restaurants": 5,
      "rating": 4.8
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListView.separated(
        itemCount: platos.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final item = platos[index];
          return FoodCard(
            title: item['title'],
            imageUrl: item['image'],
            type: item['type'],
            restaurants: item['restaurants'],
            rating: item['rating'],
          );
        },
      ),
    );
  }
}

class FoodCard extends StatelessWidget {
  final String title;
  final String imageUrl;
  final String type;
  final int restaurants;
  final double rating;

  const FoodCard({
    super.key,
    required this.title,
    required this.imageUrl,
    required this.type,
    required this.restaurants,
    required this.rating,
  });

  Color getTagColor() {
    if (type.toLowerCase() == 'almuerzo') {
      return Colors.orange.shade600;
    } else if (type.toLowerCase() == 'cena') {
      return Colors.deepOrange.shade400;
    } else {
      return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // Imagen izquierda
          ClipRRect(
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(14),
              bottomLeft: Radius.circular(14),
            ),
            child: SizedBox(
              width: 96,
              height: 96,
              child: Image.network(
                imageUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.fastfood, size: 36, color: Colors.grey),
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          // Contenido
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título + etiqueta
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: getTagColor(),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          type,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  // Info + rating
                  Row(
                    children: [
                      const Icon(Icons.location_on_outlined, size: 16, color: Colors.black54),
                      const SizedBox(width: 4),
                      Text(
                        '$restaurants restaurantes',
                        style: const TextStyle(fontSize: 13, color: Colors.black54),
                      ),
                      const Spacer(),
                      Row(
                        children: [
                          const Icon(Icons.star, size: 16, color: Colors.amber),
                          const SizedBox(width: 4),
                          Text(
                            rating.toStringAsFixed(1),
                            style: const TextStyle(fontSize: 13),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
