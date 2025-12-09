import 'dart:convert';
import 'dart:typed_data';

import 'package:Sabores_de_mi_Tierra/ui/listaPlatos2/view_model/listaPlatos2.dart';
import 'package:Sabores_de_mi_Tierra/ui/vistaRestaurantComensal/view_model/vista_restaurant_comensal.dart';
import 'package:Sabores_de_mi_Tierra/widgets/calificacion_promedio.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

// Asegúrate de importar el componente RestaurantUserView
// import 'package:Sabores_de_mi_Tierra/ui/restaurant_user_view/view/restaurant_user_view.dart';

class DetallePlatoScreen extends StatefulWidget {
  final PlatoInfo plato;
  final GrupoPlato grupo;

  const DetallePlatoScreen({
    Key? key,
    required this.plato,
    required this.grupo,
  }) : super(key: key);

  @override
  State<DetallePlatoScreen> createState() => _DetallePlatoScreenState();
}

class _DetallePlatoScreenState extends State<DetallePlatoScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Map<String, Map<String, dynamic>> _restaurantesInfo = {};

  @override
  void initState() {
    super.initState();
    _loadRestaurantesInfo();
  }

  Future<void> _loadRestaurantesInfo() async {
    try {
      final restaurantIds = widget.grupo.platos.map((p) => p.restaurantId).toSet();
      
      for (final restaurantId in restaurantIds) {
        final restaurantDoc = await _db.collection('restaurants').doc(restaurantId).get();
        if (restaurantDoc.exists) {
          _restaurantesInfo[restaurantId] = restaurantDoc.data()!;
        }
      }
      
      setState(() {});
    } catch (e) {
      print('Error cargando info de restaurantes: $e');
    }
  }

  Uint8List? _getImageBytes(String? base64String) {
    if (base64String == null || base64String.isEmpty) return null;
    try {
      return base64Decode(base64String);
    } catch (e) {
      print('Error decodificando imagen: $e');
      return null;
    }
  }

  void _onRestaurantTap(String restaurantId) {
    // Navegar al componente RestaurantUserView
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RestaurantUserView(restaurantId: restaurantId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final platoPrincipal = widget.plato;
    final restaurantPrincipal = _restaurantesInfo[platoPrincipal.restaurantId];
    final platoImageBytes = _getImageBytes(platoPrincipal.imageBase64);

    return Scaffold(
      appBar: AppBar(
        title: Text(platoPrincipal.nombre),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen del plato principal
            if (platoImageBytes != null)
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  image: DecorationImage(
                    image: MemoryImage(platoImageBytes),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.fastfood, size: 60, color: Colors.grey),
              ),
            
            const SizedBox(height: 16),
            
            // Información del plato principal
            Text(
              platoPrincipal.nombre,
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            
            const SizedBox(height: 8),
            
            if (platoPrincipal.descripcion.isNotEmpty)
              Text(
                platoPrincipal.descripcion,
                style: const TextStyle(fontSize: 16, color: Colors.grey),
              ),
            
            const SizedBox(height: 16),
            
            // Restaurante principal
            if (restaurantPrincipal != null)
              _buildRestaurantCard(
                restaurantPrincipal,
                platoPrincipal.restaurantId,
                esPrincipal: true,
              ),
            
            const SizedBox(height: 24),
            
            // Lista de otros restaurantes con el mismo plato
            if (widget.grupo.platos.length > 1)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'También disponible en:',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey.shade800,
                    ),
                  ),
                  
                  const SizedBox(height: 12),
                  
                  ...widget.grupo.platos.where((p) => p.restaurantId != platoPrincipal.restaurantId).map((plato) {
                    final restaurantInfo = _restaurantesInfo[plato.restaurantId];
                    return restaurantInfo != null
                        ? Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: _buildRestaurantCard(restaurantInfo, plato.restaurantId),
                          )
                        : const SizedBox();
                  }).toList(),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRestaurantCard(Map<String, dynamic> restaurantInfo, String restaurantId, {bool esPrincipal = false}) {
    final logoBytes = _getImageBytes(restaurantInfo['logoBase64']);

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () => _onRestaurantTap(restaurantId),
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              // Logo del restaurante
              if (logoBytes != null)
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    image: DecorationImage(
                      image: MemoryImage(logoBytes),
                      fit: BoxFit.cover,
                    ),
                  ),
                )
              else
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.restaurant, color: Colors.grey),
                ),
              
              const SizedBox(width: 12),
              
              // Información del restaurante
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      restaurantInfo['name'] ?? 'Restaurante',
                      style: TextStyle(
                        fontWeight: esPrincipal ? FontWeight.bold : FontWeight.normal,
                        fontSize: esPrincipal ? 16 : 14,
                      ),
                    ),
                    
                    const SizedBox(height: 4),
                    
                    Row(
                      children: [
                        CalificacionPromedio(
                          restaurantId: restaurantId,
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        
                        if (restaurantInfo['location'] != null)
                          Expanded(
                            child: Text(
                              _formatLocation(restaurantInfo['location']),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              
              const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
            ],
          ),
        ),
      ),
    );
  }

  String _formatLocation(String location) {
    try {
      final parts = location.split(',');
      if (parts.length == 2) {
        final lat = double.parse(parts[0]);
        final lng = double.parse(parts[1]);
        return '📍 ${lat.toStringAsFixed(4)}, ${lng.toStringAsFixed(4)}';
      }
    } catch (e) {
      print('Error formateando ubicación: $e');
    }
    return '📍 Ubicación disponible';
  }
}
