import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/dish.dart';
import '../../models/restaurant.dart';

class DishService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Catálogo en tiempo real
  Stream<List<Dish>> streamDishes() {
    return _db
        .collection('foods')
        // si no tienes 'nombre' en Firestore, comenta el orderBy
        //.orderBy('name')
        .snapshots()
        .map(
          (qs) => qs.docs.map((doc) => Dish.fromFirestore(doc)).toList(),
        );
  }

  /// 🔥 Busca restaurantes que tengan algún plato cuyo nombre
  /// CONTENGA [dishName], ignorando mayúsculas y acentos.
  ///
  /// Ej: dishName = "cafe"
  ///   - "cafe"              ✔
  ///   - "CAFÉ"             ✔
  ///   - "Café con leche"   ✔
  ///   - "leche con cafe"   ✔
  Future<List<Restaurant>> fetchRestaurantsByDishName(String dishName) async {
    // 1) Normalizar el texto que buscamos
    final searchNorm = _normalizeText(dishName);
    print('🟡 Buscando restaurantes para plato: "$dishName" (norm: $searchNorm)');

    // 2) Traer TODOS los foods (tu colección es pequeña, es viable)
    final foodsSnap = await _db.collection('foods').get();

    // 3) Filtrar en Flutter por "contiene", ignorando acentos y mayúsculas
    final filteredFoods = foodsSnap.docs.where((doc) {
      final data = doc.data();
      final rawName =
          (data['name'] ?? data['nombre'] ?? '').toString(); // soportar name/nombre
      final nameNorm = _normalizeText(rawName);
      return nameNorm.contains(searchNorm);
    }).toList();

    print('   Foods que contienen "$dishName": ${filteredFoods.length}');

    if (filteredFoods.isEmpty) {
      print('   No encontré ningún food que contenga esa palabra');
      return [];
    }

    // 4) Sacar restaurantId únicos
    final ids = filteredFoods
        .map((d) => (d.data()['restaurantId'] ?? '') as String)
        .where((id) => id.isNotEmpty)
        .toSet()
        .toList();

    print('   IDs de restaurantes encontrados: $ids');

    if (ids.isEmpty) {
      print('   Los foods no tenían restaurantId');
      return [];
    }

    // 5) Traer restaurantes en chunks de 10 (límite de whereIn)
    final List<Restaurant> restaurantes = [];
    const chunkSize = 10;

    for (var i = 0; i < ids.length; i += chunkSize) {
      final chunk = ids.sublist(
        i,
        i + chunkSize > ids.length ? ids.length : i + chunkSize,
      );

      final rsSnap = await _db
          .collection('restaurants')
          .where(FieldPath.documentId, whereIn: chunk)
          .get();

      restaurantes.addAll(
        rsSnap.docs.map((doc) => Restaurant.fromFirestore(doc)).toList(),
      );
    }

    print('   Restaurantes devueltos: ${restaurantes.length}');
    return restaurantes;
  }

  // Si la subcolección ya no la usas, puedes borrar esto.
  Future<List<Restaurant>> fetchRestaurantsForDish(String dishId) async {
    final snap = await _db
        .collection('foods')
        .doc(dishId)
        .collection('restaurantes')
        .get();

    return snap.docs.map((doc) => Restaurant.fromFirestore(doc)).toList();
  }

  /// Normaliza texto:
  /// - minúsculas
  /// - quita acentos
  /// - convierte ñ → n
  String _normalizeText(String input) {
    var s = input.toLowerCase();

    const accents = 'áàäâãéèëêíìïîóòöôõúùüûñ';
    const normal  = 'aaaaaeeeeiiiiooooouuuun';

    for (var i = 0; i < accents.length; i++) {
      s = s.replaceAll(accents[i], normal[i]);
    }

    return s;
  }
}
