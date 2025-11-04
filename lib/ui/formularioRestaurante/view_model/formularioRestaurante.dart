import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:image_picker/image_picker.dart';
import 'package:latlong2/latlong.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

final FirebaseFirestore db = FirebaseFirestore.instance;

class RestaurantFormPage extends StatefulWidget {
  final String? restaurantId; // si es nulo => creación

  const RestaurantFormPage({
    Key? key,
    this.restaurantId,
  }) : super(key: key);

  @override
  State<RestaurantFormPage> createState() => _RestaurantFormPageState();
}

class _RestaurantFormPageState extends State<RestaurantFormPage> {
  final _formKey = GlobalKey<FormState>();
  final _mapController = MapController();

  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  TimeOfDay? _openingTime;
  TimeOfDay? _closingTime;

  File? _logoImage;
  String? _logoBase64;
  LatLng? _selectedLocation;
  final List<Marker> _markers = [];
  bool _isLoading = false;
  List<Map<String, dynamic>> _foods = [];

  @override
  void initState() {
    super.initState();
    
    // Inicializar controles con valores vacíos
    _nameController = TextEditingController();
    _descriptionController = TextEditingController();
    _foods = [];

    // Si hay ID, cargar datos del restaurante y platos
    if (widget.restaurantId != null) {
      _loadRestaurantData();
    }
  }

  Future<void> _loadRestaurantData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      // Cargar datos del restaurante
      DocumentSnapshot restaurantDoc = await db.collection('restaurants').doc(widget.restaurantId!).get();

      if (restaurantDoc.exists) {
        var data = restaurantDoc.data() as Map<String, dynamic>;
        
        setState(() {
          _nameController.text = data['name'] ?? '';
          _descriptionController.text = data['description'] ?? '';
          _logoBase64 = data['logoBase64'];
          
          // Parsear horarios
          if (data['openingTime'] != null) {
            _openingTime = _stringToTimeOfDay(data['openingTime']);
          }
          if (data['closingTime'] != null) {
            _closingTime = _stringToTimeOfDay(data['closingTime']);
          }
          
          // Parsear ubicación
          if (data['location'] != null) {
            _parseInitialLocation(data['location']);
          }
        });

        // Cargar platos del restaurante
        await _loadRestaurantFoods();
      }
    } catch (e) {
      print('Error al cargar datos del restaurante: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar datos: $e')),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  TimeOfDay _stringToTimeOfDay(String timeString) {
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
    return TimeOfDay(hour: 0, minute: 0);
  }

  String _timeOfDayToString(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
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
        loadedFoods.add({
          'id': doc.id,
          'name': foodData['name'] ?? '',
          'imageBase64': foodData['imageBase64'] ?? '',
        });
      }

      setState(() {
        _foods = loadedFoods;
      });
    } catch (e) {
      print('Error al cargar platos: $e');
    }
  }

  void _parseInitialLocation(String location) {
    try {
      final parts = location.split(',');
      if (parts.length == 2) {
        final lat = double.tryParse(parts[0]);
        final lng = double.tryParse(parts[1]);
        if (lat != null && lng != null) {
          _selectedLocation = LatLng(lat, lng);
          _addMarker(_selectedLocation!);
          _mapController.move(_selectedLocation!, 15.0);
        }
      }
    } catch (e) {
      print('Error parsing location: $e');
    }
  }

  Future<void> _saveOrUpdateRestaurant() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final location = _selectedLocation != null
          ? '${_selectedLocation!.latitude},${_selectedLocation!.longitude}'
          : '';

      // Convertir imagen a base64 si hay una nueva
      String? logoBase64;
      if (_logoImage != null) {
        final bytes = await _logoImage!.readAsBytes();
        logoBase64 = base64Encode(bytes);
      } else if (_logoBase64 != null) {
        logoBase64 = _logoBase64; // Mantener la existente
      }

      // Preparar datos del restaurante
      final restaurantData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'openingTime': _openingTime != null ? _timeOfDayToString(_openingTime!) : null,
        'closingTime': _closingTime != null ? _timeOfDayToString(_closingTime!) : null,
        'location': location,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      // Agregar logo base64 si existe
      if (logoBase64 != null) {
        restaurantData['logoBase64'] = logoBase64;
      }

      String restaurantId;

      if (widget.restaurantId != null) {
        // ACTUALIZAR restaurante existente
        restaurantId = widget.restaurantId!;
        await db.collection('restaurants').doc(restaurantId).update(restaurantData);
        
        // ELIMINAR todos los platos existentes y crear los nuevos
        await _replaceAllFoods(restaurantId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurante actualizado exitosamente')),
        );
      } else {
        // CREAR nuevo restaurante
        restaurantData['createdAt'] = FieldValue.serverTimestamp();
        
        DocumentReference docRef = await db.collection('restaurants').add(restaurantData);
        restaurantId = docRef.id;
        
        // Crear platos para el nuevo restaurante
        await _createFoods(restaurantId);
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Restaurante creado exitosamente')),
        );
      }

      // Regresar a la pantalla anterior
      if (mounted) {
        Navigator.pop(context);
      }

    } catch (e) {
      print('Error al guardar: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al guardar: $e')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _replaceAllFoods(String restaurantId) async {
    try {
      // 1. Obtener y eliminar todos los platos existentes
      QuerySnapshot existingFoods = await db
          .collection('foods')
          .where('restaurantId', isEqualTo: restaurantId)
          .get();

      // Eliminar en lote todos los platos existentes
      WriteBatch batch = db.batch();
      for (var doc in existingFoods.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();

      // 2. Crear nuevos platos
      await _createFoods(restaurantId);
      
    } catch (e) {
      print('Error al reemplazar platos: $e');
      throw e;
    }
  }

  Future<void> _createFoods(String restaurantId) async {
    try {
      // Crear nuevos platos
      for (var food in _foods) {
        String? imageBase64;
        
        // Convertir imagen a base64 si hay archivo nuevo
        if (food['imageFile'] != null) {
          final bytes = await (food['imageFile'] as File).readAsBytes();
          imageBase64 = base64Encode(bytes);
        } else if (food['imageBase64'] != null) {
          imageBase64 = food['imageBase64']; // Mantener existente
        }

        final foodData = {
          'restaurantId': restaurantId,
          'name': food['name']?.toString().trim() ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        };

        // Agregar imagen base64 si existe
        if (imageBase64 != null) {
          foodData['imageBase64'] = imageBase64;
        }

        await db.collection('foods').add(foodData);
      }
    } catch (e) {
      print('Error al crear platos: $e');
      throw e;
    }
  }

  Future<void> _pickImage({bool isLogo = true, int? foodIndex}) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        if (isLogo) {
          _logoImage = File(pickedFile.path);
          _logoBase64 = null; // Limpiar base64 existente si hay nueva imagen
        } else if (foodIndex != null) {
          _foods[foodIndex]['imageFile'] = File(pickedFile.path);
          // Limpiar base64 existente si se selecciona nueva imagen
          _foods[foodIndex]['imageBase64'] = null;
        }
      });
    }
  }

  Future<void> _selectTime({bool isOpening = true}) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: isOpening ? (_openingTime ?? TimeOfDay(hour: 8, minute: 0)) 
                            : (_closingTime ?? TimeOfDay(hour: 22, minute: 0)),
    );

    if (picked != null) {
      setState(() {
        if (isOpening) {
          _openingTime = picked;
        } else {
          _closingTime = picked;
        }
      });
    }
  }

  void _onMapTapped(TapPosition tapPosition, LatLng location) {
    setState(() {
      _selectedLocation = location;
      _markers.clear();
      _addMarker(location);
    });
  }

  void _addMarker(LatLng location) {
    _markers.add(
      Marker(
        point: location,
        width: 40,
        height: 40,
        builder: (_) => const Icon(Icons.location_pin, color: Colors.red, size: 40),
      ),
    );
  }

  void _addFood() {
    setState(() {
      _foods.add({
        'name': '',
        'imageFile': null,
        'imageBase64': null,
      });
    });
  }

  void _removeFood(int index) {
    setState(() {
      _foods.removeAt(index);
    });
  }

  Widget _buildMap() {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey),
        borderRadius: BorderRadius.circular(4),
      ),
      child: FlutterMap(
        mapController: _mapController,
        options: MapOptions(
          center: _selectedLocation ?? LatLng(-17.397248, -66.161288),
          zoom: 12.0,
          onTap: _onMapTapped,
        ),
        children: [
          TileLayer(
            urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
            userAgentPackageName: 'com.foodapp.restaurant',
          ),
          MarkerLayer(markers: _markers),
        ],
      ),
    );
  }

  Widget _buildLogoSection() {
    return Column(
      children: [
        // Imagen grande del logo
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: _logoImage != null
              ? Image.file(_logoImage!, fit: BoxFit.cover)
              : _logoBase64 != null && _logoBase64!.isNotEmpty
                  ? Image.memory(
                      base64Decode(_logoBase64!),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.restaurant, size: 60, color: Colors.grey),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(Icons.restaurant, size: 60, color: Colors.grey),
                    ),
        ),
        const SizedBox(height: 12),
        // Botón para seleccionar imagen
        ElevatedButton.icon(
          onPressed: () => _pickImage(),
          icon: const Icon(Icons.photo_library),
          label: const Text('Seleccionar Logo'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 50),
          ),
        ),
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildFoodImageSection(int index) {
    final food = _foods[index];
    return Column(
      children: [
        // Imagen grande del plato
        Container(
          width: double.infinity,
          height: 150,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: food['imageFile'] != null
              ? Image.file(food['imageFile']!, fit: BoxFit.cover)
              : food['imageBase64'] != null && food['imageBase64'].isNotEmpty
                  ? Image.memory(
                      base64Decode(food['imageBase64']),
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return const Center(
                          child: Icon(Icons.fastfood, size: 40, color: Colors.grey),
                        );
                      },
                    )
                  : const Center(
                      child: Icon(Icons.fastfood, size: 40, color: Colors.grey),
                    ),
        ),
        const SizedBox(height: 8),
        // Botón para seleccionar imagen
        ElevatedButton.icon(
          onPressed: () => _pickImage(isLogo: false, foodIndex: index),
          icon: const Icon(Icons.photo_library),
          label: const Text('Seleccionar Imagen del Plato'),
          style: ElevatedButton.styleFrom(
            minimumSize: const Size(double.infinity, 40),
          ),
        ),
      ],
    );
  }

  Widget _buildFoodForm(int index) {
    final food = _foods[index];
    final nameController = TextEditingController(text: food['name'] ?? '');

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            // Imagen del plato
            _buildFoodImageSection(index),
            const SizedBox(height: 16),
            
            // Nombre del plato
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: nameController,
                    decoration: const InputDecoration(
                      labelText: 'Nombre del plato',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (v) => _foods[index]['name'] = v,
                    validator: (v) =>
                        v == null || v.isEmpty ? 'Ingrese el nombre del plato' : null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  onPressed: () => _removeFood(index),
                )
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimePicker(String label, TimeOfDay? currentTime, bool isOpening) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                currentTime != null 
                  ? '${currentTime.hour.toString().padLeft(2, '0')}:${currentTime.minute.toString().padLeft(2, '0')}'
                  : 'Seleccionar hora',
                style: TextStyle(
                  color: currentTime != null ? Colors.black : Colors.grey,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.access_time),
                onPressed: () => _selectTime(isOpening: isOpening),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.restaurantId != null;

    return Scaffold(
      appBar: AppBar(
        title: Text(isEditing ? 'Editar Restaurante' : 'Crear Restaurante'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: ListView(
                  children: [
                    _buildLogoSection(),

                    // Nombre del restaurante
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Nombre del restaurante',
                        border: OutlineInputBorder(),
                      ),
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Ingrese el nombre' : null,
                    ),
                    const SizedBox(height: 16),

                    // Mapa
                    Text('Ubicación', style: TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    _buildMap(),
                    const SizedBox(height: 8),
                    if (_selectedLocation != null)
                      Text(
                        '(${_selectedLocation!.latitude.toStringAsFixed(4)}, '
                        '${_selectedLocation!.longitude.toStringAsFixed(4)})',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    const SizedBox(height: 16),

                    // Horarios
                    _buildTimePicker('Hora de Apertura', _openingTime, true),
                    _buildTimePicker('Hora de Cierre', _closingTime, false),

                    // Descripción
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Descripción',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                      validator: (v) =>
                          v == null || v.isEmpty ? 'Ingrese la descripción' : null,
                    ),
                    const SizedBox(height: 24),

                    // --- Sección de platos ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Platos', style: TextStyle(fontWeight: FontWeight.w600)),
                        ElevatedButton.icon(
                          onPressed: _addFood,
                          icon: const Icon(Icons.add),
                          label: const Text('Añadir Plato'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    if (_foods.isEmpty)
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Center(
                          child: Text(
                            'No hay platos añadidos aún',
                            style: TextStyle(color: Colors.grey),
                          ),
                        ),
                      ),
                    
                    for (int i = 0; i < _foods.length; i++) _buildFoodForm(i),

                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _saveOrUpdateRestaurant,
                      child: _isLoading 
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(isEditing ? 'Actualizar' : 'Guardar'),
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}