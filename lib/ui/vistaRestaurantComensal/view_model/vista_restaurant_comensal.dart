import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:Sabores_de_mi_Tierra/widgets/calificacion_form.dart';
import 'package:Sabores_de_mi_Tierra/widgets/calificacion_promedio.dart';

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

class _RestaurantUserViewState extends State<RestaurantUserView> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _dayNames = ['L', 'M', 'Mi', 'J', 'V', 'S', 'D'];
  final List<String> _fullDayNames = ['Lunes', 'Martes', 'Miércoles', 'Jueves', 'Viernes', 'Sábado', 'Domingo'];
  
  Map<String, dynamic>? _restaurantData;
  List<Map<String, dynamic>> _foods = [];
  bool _isLoading = true;
  int _currentDayIndex = 0;

  @override
  void initState() {
    super.initState();
    _currentDayIndex = _getCurrentDayIndex();
    _tabController = TabController(
      length: 7,
      vsync: this,
      initialIndex: _currentDayIndex,
    );
    _loadRestaurantData();
  }

  int _getCurrentDayIndex() {
    final now = DateTime.now();
    // DateTime.weekday: 1=Monday, 7=Sunday
    // Nuestra lista: 0=Lunes, 6=Domingo
    return now.weekday - 1;
  }

  Future<void> _loadRestaurantData() async {
    try {
      // Cargar datos del restaurante
      DocumentSnapshot restaurantDoc = await db
          .collection('restaurants')
          .doc(widget.restaurantId)
          .get();

      if (restaurantDoc.exists) {
        setState(() {
          _restaurantData = restaurantDoc.data() as Map<String, dynamic>;
        });

        // Cargar platos del restaurante
        await _loadRestaurantFoods();
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
        
        // Solo incluir platos que no estén ocultos
        if (foodData['visibility'] != 'oculto') {
          loadedFoods.add({
            'id': doc.id,
            'name': foodData['name'] ?? '',
            'description': foodData['description'] ?? '',
            'days': List<bool>.from(foodData['days'] ?? List.generate(7, (_) => false)),
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

  List<Map<String, dynamic>> _getFoodsForDay(int dayIndex) {
    return _foods.where((food) {
      final days = food['days'] as List<bool>;
      return days[dayIndex];
    }).toList();
  }

  String _getOpeningHoursForDay(int dayIndex) {
    if (_restaurantData == null || _restaurantData!['openingHours'] == null) {
      return 'Horario no disponible';
    }

    final openingHours = List<Map<String, dynamic>>.from(_restaurantData!['openingHours']);
    
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

  Widget _buildRestaurantHeader() {
    if (_restaurantData == null) return Container();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        border: Border.all(color: Colors.grey.shade200), // CORREGIDO AQUÍ
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Logo del restaurante
              if (_restaurantData!['logoBase64'] != null && _restaurantData!['logoBase64'].isNotEmpty)
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: MemoryImage(
                        _decodeBase64(_restaurantData!['logoBase64']),
                      ),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.grey),
                ),
              
              const SizedBox(width: 16),
              
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _restaurantData!['name'] ?? 'Sin nombre',
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        CalificacionPromedio(
                          restaurantId: widget.restaurantId,
                          size: 18,
                          color: Colors.amber,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _restaurantData!['description'] ?? 'Sin descripción',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayTab(int index) {
    final isOpen = _isRestaurantOpen(index);
    final isToday = index == _currentDayIndex;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isToday ? const Color(0xFFFF6A00) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _dayNames[index],
            style: TextStyle(
              color: isToday ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 2),
          Icon(
            isOpen ? Icons.check_circle : Icons.cancel,
            size: 12,
            color: isToday ? Colors.white : (isOpen ? Colors.green : Colors.red),
          ),
        ],
      ),
    );
  }

  Widget _buildDayContent(int dayIndex) {
    final foods = _getFoodsForDay(dayIndex);
    final openingHours = _getOpeningHoursForDay(dayIndex);
    final isOpen = _isRestaurantOpen(dayIndex);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Estado y horario
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  Icon(
                    isOpen ? Icons.check_circle : Icons.cancel,
                    color: isOpen ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          isOpen ? 'Abierto' : 'Cerrado',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: isOpen ? Colors.green : Colors.red,
                          ),
                        ),
                        Text(
                          openingHours,
                          style: TextStyle(color: Colors.grey[600]),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Platos del día
          Text(
            'Platos disponibles (${_fullDayNames[dayIndex]})',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),

          if (foods.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              child: Column(
                children: [
                  Icon(Icons.fastfood, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No hay platos disponibles para ${_fullDayNames[dayIndex]}',
                    style: TextStyle(color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            )
          else
            Column(
              children: foods.map((food) => _buildFoodCard(food)).toList(),
            ),
        ],
      ),
    );
  }

  Widget _buildFoodCard(Map<String, dynamic> food) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del plato
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: Colors.grey[200],
              ),
              child: food['imageBase64'] != null && food['imageBase64'].isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.memory(
                        _decodeBase64(food['imageBase64']),
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.fastfood, color: Colors.grey);
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
                  if (food['description'] != null && food['description'].isNotEmpty)
                    Text(
                      food['description'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 14,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: _getCategoryColor(food['category']),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _getCategoryText(food['category']),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
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

    return Scaffold(
      appBar: AppBar(
        title: Text(_restaurantData!['name'] ?? 'Restaurante'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelPadding: const EdgeInsets.symmetric(horizontal: 4),
          tabs: List.generate(7, (index) => _buildDayTab(index)),
        ),
      ),
      body: Column(
        children: [
          _buildRestaurantHeader(),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: List.generate(7, (index) => _buildDayContent(index)),
            ),
          ),
        ],
      ),
      // Widget de calificación fijo en la parte inferior
      persistentFooterButtons: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          color: Colors.white,
          child: CalificacionForm(
            restaurantId: widget.restaurantId,
          ),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }
}