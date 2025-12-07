import 'dart:convert';
import 'dart:typed_data';

import 'package:Sabores_de_mi_Tierra/ui/formularioRestaurante/view_model/formularioRestaurante.dart';
import 'package:Sabores_de_mi_Tierra/widgets/bottom_nav_var.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:Sabores_de_mi_Tierra/ui/vistaRestaurantComensal/view_model/vista_restaurant_comensal.dart';

/// MODELO LOCAL
class Restaurante {
  final String id;
  final String nombre;
  final String descripcion;
  final String horario;
  final double calificacion;
  final String? logoBase64;
  final bool abierto;
  final bool destacado;

  Restaurante({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.horario,
    required this.calificacion,
    this.logoBase64,
    this.abierto = true,
    this.destacado = false,
  });
}

/// PANTALLA QUE VAS A USAR EN EL MAIN
class RestaurantesScreen extends StatefulWidget {
  const RestaurantesScreen({super.key});

  @override
  State<RestaurantesScreen> createState() => _RestaurantesScreenState();
}

class _RestaurantesScreenState extends State<RestaurantesScreen> {
  final TextEditingController searchController = TextEditingController();
  final FirebaseFirestore db = FirebaseFirestore.instance;

  List<Restaurante> restaurantes = [];
  bool _isLoading = true;
  String searchText = '';

  @override
  void initState() {
    super.initState();
    _loadRestaurantes();
  }

  Future<void> _loadRestaurantes() async {
    try {
      // 👇 Query simple: solo filtra por visibility, SIN orderBy
      final snapshot = await db
          .collection('restaurants')
          .where('visibility', isEqualTo: 'publico')
          .get();

      print('Restaurantes recibidos: ${snapshot.docs.length}');

      final List<Restaurante> loadedRestaurantes = [];

      for (var doc in snapshot.docs) {
        final data = doc.data() as Map<String, dynamic>;

        // Construir el horario desde openingTime y closingTime
        String horario = 'Horario no disponible';
        final openingTime = data['openingTime'] as String?;
        final closingTime = data['closingTime'] as String?;

        if (openingTime != null && closingTime != null) {
          horario = '$openingTime - $closingTime';
        } else if (openingTime != null) {
          horario = 'Desde $openingTime';
        } else if (closingTime != null) {
          horario = 'Hasta $closingTime';
        }

        // Calificación por defecto si no existe
        final calificacion =
            (data['calificacion'] is num) ? (data['calificacion'] as num).toDouble() : 4.0;

        loadedRestaurantes.add(
          Restaurante(
            id: doc.id,
            nombre: data['name'] ?? 'Sin nombre',
            descripcion: data['description'] ?? 'Sin descripción',
            horario: horario,
            calificacion: calificacion,
            logoBase64: data['logoBase64'],
            abierto: _estaAbierto(openingTime, closingTime),
            destacado: data['destacado'] ?? false,
          ),
        );
      }

      setState(() {
        restaurantes = loadedRestaurantes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar restaurantes: $e');
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cargar restaurantes: $e')),
        );
      }
    }
  }

  bool _estaAbierto(String? openingTime, String? closingTime) {
    if (openingTime == null || closingTime == null) return true;

    try {
      final now = TimeOfDay.now();
      final opening = _parseTime(openingTime);
      final closing = _parseTime(closingTime);

      if (opening == null || closing == null) return true;

      final nowMinutes = now.hour * 60 + now.minute;
      final openingMinutes = opening.hour * 60 + opening.minute;
      final closingMinutes = closing.hour * 60 + closing.minute;

      return nowMinutes >= openingMinutes && nowMinutes <= closingMinutes;
    } catch (_) {
      return true;
    }
  }

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

  void _editarRestaurante(String restauranteId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantFormPage(restaurantId: restauranteId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filteredList = restaurantes
        .where(
          (r) =>
              r.nombre.toLowerCase().contains(searchText.toLowerCase()) ||
              r.descripcion.toLowerCase().contains(searchText.toLowerCase()),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Sabores de mi Tierra"),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const RestaurantFormPage(),
                ),
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 0),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Encuentra un restaurante en específico",
                        style: TextStyle(color: Colors.black54),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: searchController,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.search),
                          hintText: 'Buscar restaurantes...',
                          filled: true,
                          fillColor: Colors.white,
                          contentPadding:
                              const EdgeInsets.symmetric(horizontal: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.transparent,
                              width: 0,
                            ),
                          ),
                        ),
                        onChanged: (val) {
                          setState(() => searchText = val);
                        },
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: filteredList.isEmpty
                      ? const Center(
                          child: Text('No se encontraron restaurantes'),
                        )
                      : ListView.builder(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 4),
                          itemCount: filteredList.length,
                          itemBuilder: (context, index) {
                            final r = filteredList[index];
                            return _buildRestauranteCard(r);
                          },
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildRestauranteCard(Restaurante r) {
    Uint8List? logoBytes;
    if (r.logoBase64 != null && r.logoBase64!.isNotEmpty) {
      try {
        logoBytes = _decodeBase64(r.logoBase64!);
      } catch (e) {
        print('Error decoding base64: $e');
      }
    }

    return InkWell(
      onTap: () {
        // 👉 Al tocar la tarjeta, ver detalle del restaurante (comensal)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => RestaurantUserView(restaurantId: r.id),
          ),
        );
      },
      borderRadius: BorderRadius.circular(16),
      child: Card(
        margin: const EdgeInsets.only(bottom: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 1,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    height: 160,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      color: Colors.grey[200],
                    ),
                    child: logoBytes != null && logoBytes.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.memory(
                              logoBytes,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return _buildPlaceholderIcon();
                              },
                            ),
                          )
                        : _buildPlaceholderIcon(),
                  ),
                  if (r.destacado)
                    Positioned(
                      top: 10,
                      left: 10,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade700,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Destacado',
                          style: TextStyle(color: Colors.white, fontSize: 12),
                        ),
                      ),
                    ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: r.abierto ? Colors.green : Colors.redAccent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        r.abierto ? 'Abierto' : 'Cerrado',
                        style: const TextStyle(color: Colors.white, fontSize: 12),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                r.nombre,
                style:
                    const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 4),
                  Text("${r.calificacion}"),
                  const SizedBox(width: 16),
                  const Icon(Icons.access_time, color: Colors.grey, size: 18),
                  const SizedBox(width: 4),
                  Text(r.horario, style: const TextStyle(color: Colors.grey)),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                r.descripcion,
                style: const TextStyle(color: Colors.black54),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              const Text(
                'Toca para ver más detalles',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildPlaceholderIcon() {
    return const Center(
      child: Icon(
        Icons.restaurant,
        size: 60,
        color: Colors.grey,
      ),
    );
  }

  Uint8List _decodeBase64(String base64String) {
    try {
      return base64.decode(base64String);
    } catch (e) {
      print('Error decoding base64: $e');
      return Uint8List(0);
    }
  }
}
