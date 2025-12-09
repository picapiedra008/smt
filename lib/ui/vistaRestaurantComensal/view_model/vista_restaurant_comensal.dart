import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:Sabores_de_mi_Tierra/widgets/calificacion_form.dart';
import 'package:Sabores_de_mi_Tierra/widgets/calificacion_promedio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart'; // 👈 NUEVO

final FirebaseFirestore db = FirebaseFirestore.instance;

class RestaurantUserView extends StatefulWidget {
  final String restaurantId;

  const RestaurantUserView({
    Key? key,
    required this.restaurantId,
  }) : super(key: key);

  @override
  State<RestaurantUserView> createState() => _RestaurantUserViewState();
}

class _RestaurantUserViewState extends State<RestaurantUserView> {
  final List<String> _fullDayNames = [
    'Lunes',
    'Martes',
    'Miércoles',
    'Jueves',
    'Viernes',
    'Sábado',
    'Domingo'
  ];

  Map<String, dynamic>? _restaurantData;
  List<Map<String, dynamic>> _foods = [];
  bool _isLoading = true;
  int _currentDayIndex = 0;

  // distancia en km 
  double? _distanceKm;

  @override
  void initState() {
    super.initState();
    _currentDayIndex = _getCurrentDayIndex();
    _loadRestaurantData();
  }

  int _getCurrentDayIndex() {
    final now = DateTime.now();
    return now.weekday - 1;
  }

  Future<void> _loadRestaurantData() async {
    try {
      DocumentSnapshot restaurantDoc =
          await db.collection('restaurants').doc(widget.restaurantId).get();

      if (restaurantDoc.exists) {
        setState(() {
          _restaurantData = restaurantDoc.data() as Map<String, dynamic>;
        });

        await _loadRestaurantFoods();
        await _calculateDistance(); 
      }
    } catch (e) {
      print('Error al cargar datos del restaurante: $e');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadRestaurantFoods() async {
    try {
      QuerySnapshot foodsSnapshot = await db
          .collection('foods')
          .where('restaurantId', isEqualTo: widget.restaurantId)
          .get();

      List<Map<String, dynamic>> loadedFoods = [];

      for (var doc in foodsSnapshot.docs) {
        var foodData = doc.data() as Map<String, dynamic>;

        if (foodData['visibility'] != 'oculto') {
          loadedFoods.add({
            'id': doc.id,
            'name': foodData['name'] ?? '',
            'description': foodData['description'] ?? '',
            'days': List<bool>.from(
                foodData['days'] ?? List.generate(7, (_) => false)),
            'category': foodData['category'] ?? 'cualquiera',
            'imageBase64': foodData['imageBase64'] ?? '',
          });
        }
      }

      setState(() {
        _foods = loadedFoods;
      });
    } catch (e) {
      print('Error al cargar platos: $e');
    }
  }


  Future<void> _calculateDistance() async {
    try {
      final locStr = _restaurantData?['location'] as String?;
      if (locStr == null || locStr.isEmpty) {
        print('[DISTANCIA] No hay location en la BD');
        return;
      }

      final parts = locStr.split(',');
      if (parts.length < 2) {
        print('[DISTANCIA] Location inválida: $locStr');
        return;
      }

      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat == null || lng == null) {
        print('[DISTANCIA] No se pudo parsear lat/lng');
        return;
      }

      
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        print('[DISTANCIA] Servicios de ubicación desactivados');
        return;
      }

      // Permisos
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          print('[DISTANCIA] Permiso de ubicación denegado');
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        print('[DISTANCIA] Permiso de ubicación denegado permanentemente');
        return;
      }

      // Posición actual 
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final meters = Geolocator.distanceBetween(
        position.latitude,
        position.longitude,
        lat,
        lng,
      );

      setState(() {
        _distanceKm = meters / 1000.0;
      });

      print('[DISTANCIA] Distancia calculada: $_distanceKm km');
    } catch (e) {
      print('[DISTANCIA] Error calculando distancia: $e');
    }
  }

  // Google Maps
  Future<void> _openInGoogleMaps() async {
    final loc = _restaurantData?['location'] as String?;
    if (loc == null || loc.isEmpty) {
      print('[MAPS] No hay location en la BD');
      return;
    }

    final parts = loc.split(',');
    if (parts.length < 2) {
      print('[MAPS] Location inválida: $loc');
      return;
    }

    final lat = parts[0].trim();
    final lng = parts[1].trim();

    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );

    print('[MAPS] Abriendo URL: $uri');

    try {
      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened) {
        print('[MAPS] launchUrl devolvió false');
      }
    } catch (e) {
      print('[MAPS] Error al abrir Google Maps: $e');
    }
  }

  List<Map<String, dynamic>> _getFoodsForDay(int dayIndex) {
    return _foods.where((food) {
      final days = food['days'] as List<bool>;
      return days[dayIndex];
    }).toList();
  }

  String _getOpeningHoursForDay(int dayIndex) {
    if (_restaurantData == null ||
        _restaurantData!['openingHours'] == null) {
      return 'Horario no disponible';
    }

    final openingHours =
        List<Map<String, dynamic>>.from(_restaurantData!['openingHours']);

    for (var hour in openingHours) {
      final days = List<bool>.from(hour['days'] ?? []);
      if (days[dayIndex]) {
        final openingTime = hour['openingTime'] ?? '';
        final closingTime = hour['closingTime'] ?? '';
        return '$openingTime - $closingTime';
      }
    }

    return 'Cerrado';
  }

  bool _isRestaurantOpen(int dayIndex) {
    final hours = _getOpeningHoursForDay(dayIndex);
    return hours != 'Cerrado' && hours != 'Horario no disponible';
  }

  Widget _buildDayCard(int dayIndex) {
    final foods = _getFoodsForDay(dayIndex);
    final openingHours = _getOpeningHoursForDay(dayIndex);
    final isOpen = _isRestaurantOpen(dayIndex);
    final isToday = dayIndex == _getCurrentDayIndex();

    return Container(
      width: MediaQuery.of(context).size.width * 0.85,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header del día
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isToday ? const Color(0xFFFF6A00) : Colors.grey[100],
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16),
                  topRight: Radius.circular(16),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    isOpen ? Icons.check_circle : Icons.cancel,
                    color: isToday
                        ? Colors.white
                        : (isOpen ? Colors.green : Colors.red),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _fullDayNames[dayIndex],
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: isToday ? Colors.white : Colors.black87,
                      ),
                    ),
                  ),
                  Text(
                    openingHours,
                    style: TextStyle(
                      fontSize: 14,
                      color: isToday ? Colors.white : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            // Lista de platos
            Expanded(
              child: foods.isEmpty
                  ? Container(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.fastfood,
                              size: 48, color: Colors.grey[400]),
                          const SizedBox(height: 12),
                          Text(
                            'No hay platos disponibles',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : ListView(
                      padding: const EdgeInsets.all(16),
                      children: [
                        ...foods.map((food) => _buildFoodCard(food)).toList(),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> food) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del plato
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: food['imageBase64'] != null &&
                      food['imageBase64'].isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _decodeBase64(food['imageBase64']),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.fastfood,
                              color: Colors.grey);
                        },
                      ),
                    )
                  : const Icon(Icons.fastfood, color: Colors.grey),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    food['name'] ?? 'Sin nombre',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (food['description'] != null &&
                      food['description'].isNotEmpty)
                    Text(
                      food['description'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(food['category']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getCategoryText(food['category']),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalificacionSection() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Calificación del restaurante',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                CalificacionPromedio(
                  restaurantId: widget.restaurantId,
                  size: 24,
                  color: Colors.amber,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'Basado en las opiniones de nuestros clientes',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            CalificacionForm(
              restaurantId: widget.restaurantId,
            ),
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor(String category) {
    switch (category) {
      case 'desayuno':
        return Colors.orange;
      case 'almuerzo':
        return Colors.green;
      case 'cena':
        return Colors.blue;
      default:
        return Colors.grey;
    }
  }

  String _getCategoryText(String category) {
    switch (category) {
      case 'desayuno':
        return 'Desayuno';
      case 'almuerzo':
        return 'Almuerzo';
      case 'cena':
        return 'Cena';
      default:
        return 'Cualquiera';
    }
  }

  Uint8List _decodeBase64(String base64String) {
    try {
      return base64.decode(base64String);
    } catch (e) {
      print('Error decoding base64: $e');
      return Uint8List(0);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Restaurante'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_restaurantData == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Restaurante'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: const Center(
          child: Text('Restaurante no encontrado'),
        ),
      );
    }

    final isCurrentlyOpen = _isRestaurantOpen(_currentDayIndex);

    return Scaffold(
      appBar: AppBar(
        title: Text(_restaurantData!['name'] ?? 'Restaurante'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header con logo, nombre, estado, descripción, distancia y botón Maps
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              color: Colors.grey[50],
              child: Column(
                children: [
                  // Logo
                  if (_restaurantData!['logoBase64'] != null &&
                      _restaurantData!['logoBase64'].isNotEmpty)
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        image: DecorationImage(
                          image: MemoryImage(
                            _decodeBase64(_restaurantData!['logoBase64']),
                          ),
                          fit: BoxFit.cover,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      width: 150,
                      height: 150,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.1),
                            blurRadius: 8,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.restaurant,
                        color: Colors.grey,
                        size: 60,
                      ),
                    ),
                  const SizedBox(height: 20),

                  // Nombre del restaurante
                  Text(
                    _restaurantData!['name'] ?? 'Sin nombre',
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 12),

                  // Estado actual (Abierto/Cerrado)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: isCurrentlyOpen ? Colors.green[50] : Colors.red[50],
                      borderRadius: BorderRadius.circular(25),
                      border: Border.all(
                        color: isCurrentlyOpen ? Colors.green : Colors.red,
                        width: 2,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isCurrentlyOpen ? Icons.check_circle : Icons.cancel,
                          color: isCurrentlyOpen ? Colors.green : Colors.red,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          isCurrentlyOpen ? 'Abierto ahora' : 'Cerrado ahora',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isCurrentlyOpen ? Colors.green : Colors.red,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Descripción
                  Text(
                    _restaurantData!['description'] ?? 'Sin descripción',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                    ),
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 8),

                  // Distancia 
                  if (_distanceKm != null)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.directions_walk,
                          size: 18,
                          color: Colors.blueGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'A ${_distanceKm!.toStringAsFixed(2)} km de tu ubicación',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),

                  const SizedBox(height: 8),

                  // Botón Google Maps
                  if (_restaurantData!['location'] != null &&
                      (_restaurantData!['location'] as String).isNotEmpty)
                    ElevatedButton.icon(
                      onPressed: _openInGoogleMaps,
                      icon: const Icon(Icons.map),
                      label: const Text('Ver en Google Maps'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                      ),
                    ),
                ],
              ),
            ),

            // Cards de días (scroll horizontal)
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text(
                'Horarios y Platos',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 400,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: 7,
                itemBuilder: (context, index) {
                  return _buildDayCard(index);
                },
              ),
            ),

            // Sección de calificación
            _buildCalificacionSection(),
          ],
        ),
      ),
    );
  }
}
