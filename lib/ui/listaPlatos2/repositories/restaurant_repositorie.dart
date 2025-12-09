// lib/data/repositories/restaurant_repository.dart
import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Modelo para horarios de apertura
class OpeningHours {
  final List<bool> days; // [lunes, martes, miércoles, jueves, viernes, sábado, domingo]
  final String openingTime; // formato "HH:MM"
  final String closingTime; // formato "HH:MM"

  OpeningHours({
    required this.days,
    required this.openingTime,
    required this.closingTime,
  });

  factory OpeningHours.fromMap(Map<String, dynamic> map) {
    return OpeningHours(
      days: List<bool>.from(map['days'] ?? List.filled(7, false)),
      openingTime: map['openingTime'] ?? '00:00',
      closingTime: map['closingTime'] ?? '23:59',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'days': days,
      'openingTime': openingTime,
      'closingTime': closingTime,
    };
  }
}

class Restaurante {
  final String id;
  final String nombre;
  final String descripcion;
  final String horario;
  final double averageRate;
  final String? logoBase64;
  final bool abierto;
  final bool destacado;
  final int totalRatings;
  final List<OpeningHours>? openingHours;

  Restaurante({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.horario,
    required this.averageRate,
    this.logoBase64,
    required this.abierto,
    required this.destacado,
    required this.totalRatings,
    this.openingHours,
  });

  factory Restaurante.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    
    // Parsear openingHours si existe
    List<OpeningHours>? parsedOpeningHours;
    if (data['openingHours'] != null) {
      final hoursList = data['openingHours'] as List;
      parsedOpeningHours = hoursList
          .map((item) => OpeningHours.fromMap(item as Map<String, dynamic>))
          .toList();
    }

    // Obtener horario del día actual
    final horario = _getHorarioDelDia(parsedOpeningHours);

    return Restaurante(
      id: doc.id,
      nombre: data['name'] ?? 'Sin nombre',
      descripcion: data['description'] ?? 'Sin descripción',
      horario: horario,
      averageRate: (data['average_rate'] as num?)?.toDouble() ?? 0.0,
      logoBase64: data['logoBase64'],
      abierto: _estaAbierto(parsedOpeningHours),
      destacado: data['destacado'] ?? false,
      totalRatings: (data['total_ratings'] as int?) ?? 0,
      openingHours: parsedOpeningHours,
    );
  }

  // Obtener el horario del día actual
  static String _getHorarioDelDia(List<OpeningHours>? openingHours) {
    if (openingHours == null || openingHours.isEmpty) {
      return 'Horario no disponible';
    }

    final now = DateTime.now();
    final int diaSemana = now.weekday - 1; // DateTime: 1=lunes, 7=domingo

    // Buscar horarios para el día actual
    for (final horario in openingHours) {
      if (horario.days[diaSemana]) {
        return '${horario.openingTime} - ${horario.closingTime}';
      }
    }

    return 'Cerrado hoy';
  }

  // Verificar si está abierto ahora
  static bool _estaAbierto(List<OpeningHours>? openingHours) {
    if (openingHours == null || openingHours.isEmpty) return true;

    final now = DateTime.now();
    final int diaSemana = now.weekday - 1;
    final horaActual = TimeOfDay.fromDateTime(now);

    for (final horario in openingHours) {
      if (horario.days[diaSemana] && _estaEnHorario(horaActual, horario)) {
        return true;
      }
    }

    return false;
  }

  static bool _estaEnHorario(TimeOfDay horaActual, OpeningHours horario) {
    try {
      final opening = _parseTime(horario.openingTime);
      final closing = _parseTime(horario.closingTime);

      if (opening == null || closing == null) return true;

      final actualMinutos = horaActual.hour * 60 + horaActual.minute;
      final openingMinutos = opening.hour * 60 + opening.minute;
      final closingMinutos = closing.hour * 60 + closing.minute;

      // Si el horario cierra después de medianoche
      if (closingMinutos < openingMinutos) {
        return actualMinutos >= openingMinutos || actualMinutos <= closingMinutos;
      } else {
        return actualMinutos >= openingMinutos && actualMinutos <= closingMinutos;
      }
    } catch (e) {
      print('Error verificando horario: $e');
      return true;
    }
  }

  static TimeOfDay? _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      print('Error parsing time: $e');
    }
    return null;
  }
}

class RestaurantRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final int _pageSize = 10;
  
  DocumentSnapshot? _lastDocument;
  List<Restaurante> _cachedRestaurantes = [];
  bool _hasMore = true;
  bool _isLoading = false;

  // Método principal para obtener restaurantes con la nueva lógica
  Future<List<Restaurante>> getRestaurantes({
    required String searchQuery,
    required bool soloAbiertos,
    bool resetPagination = false,
  }) async {
    if (resetPagination) {
      _resetPagination();
    }

    if (_isLoading || !_hasMore) {
      return _cachedRestaurantes;
    }

    _isLoading = true;

    try {
      // Paso 1: Obtener restaurantes basados en categorías de comidas
      final restaurantIdsFromFoods = await _getRestaurantIdsFromFoods(searchQuery);
      
      // Paso 2: Obtener restaurantes basados en búsqueda
      final restaurantIdsFromSearch = await _getRestaurantIdsFromSearch(searchQuery);
      
      // Paso 3: Combinar y eliminar duplicados
      var combinedIds;

      if(searchQuery.isEmpty){
        combinedIds = _combineAndDeduplicateIds(
        restaurantIdsFromFoods,
        restaurantIdsFromSearch,
      );
      }else{
        combinedIds = _combineAndDeduplicateIds(
        restaurantIdsFromSearch,
        restaurantIdsFromFoods,
      );
      }
      

      // Paso 4: Aplicar filtro de solo abiertos
      final filteredIds = soloAbiertos 
          ? await _filterOpenRestaurants(combinedIds)
          : combinedIds;

      if (filteredIds.isEmpty) {
        _hasMore = false;
        _isLoading = false;
        return _cachedRestaurantes;
      }
      print('IDs finales después de filtros: $filteredIds');
      // Paso 5: Obtener restaurantes con paginación
      final restaurantes = await _getRestaurantesByIds(
        filteredIds,
        startAfter: _lastDocument,
      );

      if (restaurantes.isEmpty) {
        _hasMore = false;
        _isLoading = false;
        return _cachedRestaurantes;
      }
      print('Restaurantes obtenidos en esta página: ${restaurantes.map((r) => r.id).toList()}');
      // Actualizar último documento para paginación
      if (restaurantes.isNotEmpty) {
        _lastDocument = await _getLastDocument(restaurantes.last.id);
      }

      // Agregar a caché
      _cachedRestaurantes.addAll(restaurantes);
      
      // Si no obtuvimos una página completa, intentar cargar más
      if (restaurantes.length < _pageSize && filteredIds.length > _cachedRestaurantes.length) {
        return await getRestaurantes(
          searchQuery: searchQuery,
          soloAbiertos: soloAbiertos,
          resetPagination: false,
        );
      }

      _isLoading = false;
      return _cachedRestaurantes;

    } catch (e) {
      print('Error en getRestaurantes: $e');
      _isLoading = false;
      return _cachedRestaurantes;
    }
  }

  // Función para normalizar texto (quitar acentos, minúsculas, etc.)
  String _normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^\w\s]'), '') // Remover caracteres especiales
        .trim();
  }

  // Función para verificar si el texto contiene la búsqueda (normalizada)
  bool _containsNormalized(String text, String searchQuery) {
    if (searchQuery.isEmpty) return true;
    
    final normalizedText = _normalizeText(text);
    final normalizedSearch = _normalizeText(searchQuery);
    
    return normalizedText.contains(normalizedSearch);
  }

  // Paso 1: Obtener restaurantIds de foods según categoría y hora
  Future<List<String>> _getRestaurantIdsFromFoods(String searchQuery) async {
  try {
    final categoryOrder = _getCategoryOrderByHour();
    final Set<String> finalIds = {};

    // Obtenemos todos los foods una sola vez
    final snapshot = await _db.collection('foods').get();

    // Normalizar búsqueda
    final normalizedSearch = _normalizeText(searchQuery);

    for (final category in categoryOrder) {
      // Lista para acumular IDs de esta categoría
      final idsForCategory = <String>{};

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        final foodCategory = data['category'] as String? ?? 'cualquiera';
        final foodName = data['name'] as String? ?? '';
        final restaurantId = data['restaurantId'] as String?;

        if (restaurantId == null) continue;

        // Filtrar por categoría exacta
        if (foodCategory != category) continue;

        // Filtrar por búsqueda (solo si hay query)
        if (searchQuery.isNotEmpty) {
          if (!_containsNormalized(foodName, normalizedSearch)) continue;
        }

        idsForCategory.add(restaurantId);
      }

      // Agregar al set global para mantener orden por prioridad
      for (final id in idsForCategory) {
        finalIds.add(id);
      }
    }

    return finalIds.toList();

  } catch (e) {
    print("Error en _getRestaurantIdsFromFoods por partes: $e");
    return [];
  }
}


  // Determinar orden de categorías según hora actual
  List<String> _getCategoryOrderByHour() {
    final now = DateTime.now();
    final hour = now.hour;
    final minute = now.minute;
    final totalMinutes = hour * 60 + minute;

    // 4:00 a 11:30
    if (totalMinutes >= 4 * 60 && totalMinutes <= 11 * 60 + 30) {
      return [ 'desayuno',  'cualquiera', 'almuerzo', 'cena'];
    }
    // 11:31 a 15:00
    else if (totalMinutes >= 11 * 60 + 31 && totalMinutes <= 15 * 60) {
      return ['almuerzo', 'cena', 'cualquiera', 'desayuno'];
    }
    // 15:01 a 23:59
    else if (totalMinutes >= 15 * 60 + 1 && totalMinutes <= 23 * 60 + 59) {
      return ['cena', 'cualquiera', 'almuerzo', 'desayuno'];
    }
    // 00:00 a 3:59
    else {
      return ['cualquiera', 'cena', 'desayuno' ,  'almuerzo'];
    }
  }

  // Paso 2: Obtener restaurantIds de búsqueda en restaurants
  Future<List<String>> _getRestaurantIdsFromSearch(String searchQuery) async {
    try {
      // Obtener todos los restaurantes públicos primero
      final snapshot = await _db.collection('restaurants')
          .where('visibility', isEqualTo: 'publico')
          .get();

      // Filtrar localmente para búsqueda insensible
      final filteredDocs = snapshot.docs.where((doc) {
        if (searchQuery.isEmpty) return true;
        
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] as String? ?? '';
        final description = data['description'] as String? ?? '';
        
        // Buscar en nombre y descripción
        return _containsNormalized(name, searchQuery) || 
               _containsNormalized(description, searchQuery);
      }).toList();

      // Ordenar por average_rate descendente (con valores nulos al final)
      filteredDocs.sort((a, b) {
        final aData = a.data() as Map<String, dynamic>;
        final bData = b.data() as Map<String, dynamic>;
        final aRate = (aData['average_rate'] as num?)?.toDouble() ?? 0.0;
        final bRate = (bData['average_rate'] as num?)?.toDouble() ?? 0.0;
        
        // Orden descendente por rating
        final ratingComparison = bRate.compareTo(aRate);
        if (ratingComparison != 0) return ratingComparison;
        
        // Si tienen el mismo rating, ordenar alfabéticamente
        final aName = _normalizeText(aData['name'] as String? ?? '');
        final bName = _normalizeText(bData['name'] as String? ?? '');
        return aName.compareTo(bName);
      });

      return filteredDocs.map((doc) => doc.id).toList();

    } catch (e) {
      print('Error en _getRestaurantIdsFromSearch: $e');
      return [];
    }
  }

  // Paso 3: Combinar y eliminar duplicados
  List<String> _combineAndDeduplicateIds(
  List<String> primary,
  List<String> secondary,
) {
  final result = <String>[];
  final seen = <String>{};

  // Primero la lista primaria (mantiene el orden)
  for (final id in primary) {
    if (!seen.contains(id)) {
     // print("primario: $id");
      seen.add(id);
      result.add(id);
    }
  }

  // Luego la secundaria
  for (final id in secondary) {
    if (!seen.contains(id)) {
      seen.add(id);
      result.add(id);
    }
  }
  //print('IDs combinados: $result');

  return result;
}

  // Paso 4: Filtrar restaurantes abiertos
Future<List<String>> _filterOpenRestaurants(List<String> restaurantIds) async {
  try {
    if (restaurantIds.isEmpty) return [];

    final now = DateTime.now();
    final diaSemana = now.weekday - 1;
    final horaActual = TimeOfDay.fromDateTime(now);

    final openIds = <String>{};

    for (var i = 0; i < restaurantIds.length; i += 10) {
      final batchIds = restaurantIds.sublist(
        i,
        i + 10 > restaurantIds.length ? restaurantIds.length : i + 10,
      );

      final snapshot = await _db.collection('restaurants')
          .where(FieldPath.documentId, whereIn: batchIds)
          .get();

      for (final doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;
        final openingHours = data['openingHours'] as List?;

        if (openingHours == null || openingHours.isEmpty) {
          openIds.add(doc.id);
          continue;
        }

        bool estaAbierto = false;

        for (final hourData in openingHours) {
          final hourMap = hourData as Map<String, dynamic>;
          final days = List<bool>.from(hourMap['days'] ?? []);
          final openingTime = hourMap['openingTime'] as String?;
          final closingTime = hourMap['closingTime'] as String?;

          if (days.length > diaSemana &&
              days[diaSemana] &&
              openingTime != null &&
              closingTime != null) {
            
            if (_estaEnHorario(horaActual, openingTime, closingTime)) {
              estaAbierto = true;
              break;
            }
          }
        }

        if (estaAbierto) {
          openIds.add(doc.id);
        }
      }
    }

    // 🔥 Reordenar según la lista original
    final ordered = restaurantIds.where((id) => openIds.contains(id)).toList();

    return ordered;

  } catch (e) {
    print('Error en _filterOpenRestaurants: $e');
    return restaurantIds;
  }
}


  bool _estaEnHorario(TimeOfDay horaActual, String openingTime, String closingTime) {
    try {
      final opening = _parseTime(openingTime);
      final closing = _parseTime(closingTime);

      if (opening == null || closing == null) return true;

      final actualMinutos = horaActual.hour * 60 + horaActual.minute;
      final openingMinutos = opening.hour * 60 + opening.minute;
      final closingMinutos = closing.hour * 60 + closing.minute;

      // Si el horario cierra después de medianoche
      if (closingMinutos < openingMinutos) {
        return actualMinutos >= openingMinutos || actualMinutos <= closingMinutos;
      } else {
        return actualMinutos >= openingMinutos && actualMinutos <= closingMinutos;
      }
    } catch (e) {
      print('Error en _estaEnHorario: $e');
      return true;
    }
  }

  // Paso 5: Obtener restaurantes por IDs con paginación
  Future<List<Restaurante>> _getRestaurantesByIds(
    List<String> ids, {
    DocumentSnapshot? startAfter,
  }) async {
    if (ids.isEmpty) return [];

    try {
      // Calcular índices para la paginación
      final startIndex = _cachedRestaurantes.length;
      final endIndex = startIndex + _pageSize;
      
      if (startIndex >= ids.length) return [];

      final pageIds = ids.sublist(
        startIndex,
        endIndex > ids.length ? ids.length : endIndex,
      );

      final snapshot = await _db.collection('restaurants')
          .where(FieldPath.documentId, whereIn: pageIds)
          .get();

      // Ordenar según el orden de los IDs en pageIds
      final restaurantesMap = {
        for (var doc in snapshot.docs) doc.id: Restaurante.fromFirestore(doc)
      };

      return pageIds
          .where((id) => restaurantesMap.containsKey(id))
          .map((id) => restaurantesMap[id]!)
          .toList();

    } catch (e) {
      print('Error en _getRestaurantesByIds: $e');
      return [];
    }
  }

  // Obtener documento para paginación
  Future<DocumentSnapshot> _getLastDocument(String restaurantId) async {
    return await _db.collection('restaurants').doc(restaurantId).get();
  }

  // Método para buscar (reseteará la paginación)
  Future<List<Restaurante>> buscarRestaurantes({
    required String searchQuery,
    required bool soloAbiertos,
  }) async {
    _resetPagination();
    return await getRestaurantes(
      searchQuery: searchQuery,
      soloAbiertos: soloAbiertos,
      resetPagination: true,
    );
  }

  // Cargar más restaurantes
  Future<List<Restaurante>> loadMoreRestaurantes({
    required String searchQuery,
    required bool soloAbiertos,
  }) async {
    return await getRestaurantes(
      searchQuery: searchQuery,
      soloAbiertos: soloAbiertos,
      resetPagination: false,
    );
  }

  // Resetear paginación
  void _resetPagination() {
    _lastDocument = null;
    _cachedRestaurantes.clear();
    _hasMore = true;
    _isLoading = false;
  }

  // Helper para parsear tiempo
  TimeOfDay? _parseTime(String timeString) {
    try {
      final parts = timeString.split(':');
      if (parts.length == 2) {
        return TimeOfDay(
          hour: int.parse(parts[0]),
          minute: int.parse(parts[1]),
        );
      }
    } catch (e) {
      print('Error parsing time: $e');
    }
    return null;
  }

  // Getters
  bool get hasMore => _hasMore;
  bool get isLoading => _isLoading;

  // Obtener restaurante por ID
  Future<Restaurante?> getRestauranteById(String id) async {
    try {
      final doc = await _db.collection('restaurants').doc(id).get();
      if (doc.exists) {
        return Restaurante.fromFirestore(doc);
      }
      return null;
    } catch (e) {
      print('Error en getRestauranteById: $e');
      return null;
    }
  }

  // Método para decodificar base64
  static Uint8List? decodeBase64(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    
    try {
      return base64.decode(base64String);
    } catch (e) {
      print('Error decoding base64: $e');
      return null;
    }
  }

  // Método público para normalizar texto (si se necesita en otros lugares)
  static String normalizeText(String text) {
    return text
        .toLowerCase()
        .replaceAll('á', 'a')
        .replaceAll('é', 'e')
        .replaceAll('í', 'i')
        .replaceAll('ó', 'o')
        .replaceAll('ú', 'u')
        .replaceAll('ü', 'u')
        .replaceAll('ñ', 'n')
        .replaceAll(RegExp(r'[^\w\s]'), '')
        .trim();
  }
}