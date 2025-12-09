import 'package:cloud_firestore/cloud_firestore.dart';

class Food {
  final String id;
  final String nombre;
  final String? descripcion;
  final String imagen;
  final String imagenBase64;
  final int restaurantes;
  final String tipo;
  final double rating;
  final String restaurantId;
  
  // Nuevos campos agregados
  final List<bool> days;
  final String visibility;
  final String? imageFile;
  final String category;

  Food({
    required this.id,
    required this.nombre,
    required this.imagen,
    required this.imagenBase64,
    required this.restaurantes,
    required this.tipo,
    required this.rating,
    required this.restaurantId,
    required this.days,
    required this.visibility,
    required this.category,
    this.descripcion,
    this.imageFile,
  });

  factory Food.fromFirestore(DocumentSnapshot doc) {
    final data = (doc.data() ?? {}) as Map<String, dynamic>;

    // Nombre: intentar con 'nombre' o 'name'
    final nombre = (data['nombre'] ?? data['name'] ?? 'Sin nombre') as String;

    // Descripción: en Firestore es 'description'
    final descripcion =
        (data['descripcion'] ?? data['description']) as String?;

    // Imagen:
    final imagen = (data['imagen'] ??
            data['imageUrl'] ??
            data['image'] ??
            data['imageBase64'] ??
            '') as String;

    final imagenBase64 =
        (data['imageBase64'] ?? data['imagenBase64']) as String;

    // Restaurantes: si no existe, 0
    final rawRest = data['restaurantes'] ?? data['restaurantsCount'] ?? 0;
    final restaurantes = rawRest is int
        ? rawRest
        : int.tryParse(rawRest.toString()) ?? 0;

    final restaurantId = data['restaurantId'] ?? '';

    // Tipo / categoría
    final tipo = (data['tipo'] ?? data['category'] ?? '') as String;

    // Rating individual del plato
    final rawRating = data['rating'] ?? 0;
    final rating = rawRating is num
        ? rawRating.toDouble()
        : double.tryParse(rawRating.toString()) ?? 0.0;

    // Nuevos campos - Days
    final rawDays = data['days'];
    List<bool> days = List.generate(7, (_) => false);
    if (rawDays is List) {
      for (int i = 0; i < rawDays.length && i < 7; i++) {
        if (rawDays[i] is bool) {
          days[i] = rawDays[i];
        } else {
          days[i] = rawDays[i] == true;
        }
      }
    }

    // Visibility
    final visibility = (data['visibility'] ?? 'publico') as String;

    // ImageFile
    final imageFile = data['imageFile'] as String?;

    // Category
    final category = (data['category'] ?? 'cualquiera') as String;

    return Food(
      id: doc.id,
      nombre: nombre,
      descripcion: descripcion,
      imagen: imagen,
      imagenBase64: imagenBase64,
      restaurantes: restaurantes,
      tipo: tipo,
      rating: rating,
      restaurantId: restaurantId,
      days: days,
      visibility: visibility,
      imageFile: imageFile,
      category: category,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'name': nombre,
      'description': descripcion,
      'days': days,
      'category': category,
      'visibility': visibility,
      'imageBase64': imagenBase64,
      'imageFile': imageFile,
      'tipo': tipo,
      'restaurantes': restaurantes,
      'rating': rating,
      'restaurantId': restaurantId,
      'imagen': imagen,
    };
  }
}