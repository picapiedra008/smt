import 'dart:convert';
import 'dart:typed_data';

import 'package:Sabores_de_mi_Tierra/ui/listaPlatos2/view_model/detallePlato.dart';
import 'package:Sabores_de_mi_Tierra/widgets/bottom_nav_var.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:Sabores_de_mi_Tierra/widgets/calificacion_promedio.dart';

class PlatosAgrupadosScreen extends StatefulWidget {
  const PlatosAgrupadosScreen({Key? key}) : super(key: key);

  @override
  State<PlatosAgrupadosScreen> createState() => _PlatosAgrupadosScreenState();
}

class _PlatosAgrupadosScreenState extends State<PlatosAgrupadosScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final TextEditingController _searchController = TextEditingController();
  final int _pageSize = 20;

  List<GrupoPlato> _gruposPlatos = [];
  List<GrupoPlato> _filteredGrupos = [];
  GrupoPlato? _recomendacionDelDia;
  bool _isLoading = true;
  bool _hasMore = true;
  DocumentSnapshot? _lastDocument;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadGruposPlatos();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _filterGrupos();
    });
  }

  void _filterGrupos() {
    if (_searchQuery.isEmpty) {
      _filteredGrupos = _gruposPlatos;
    } else {
      _filteredGrupos = _gruposPlatos.where((grupo) {
        return grupo.nombrePlato.toLowerCase().contains(_searchQuery);
      }).toList();
    }
  }

  // Función para determinar la categoría prioritaria según la hora actual
  String _getCategoriaPrioritaria() {
    final now = DateTime.now();
    final hour = now.hour;

    if (hour >= 6 && hour < 11) {
      return 'desayuno';
    } else if (hour >= 11 && hour < 16) {
      return 'almuerzo';
    } else if (hour >= 16 && hour < 22) {
      return 'cena';
    } else {
      return 'cualquiera';
    }
  }

  // Función para seleccionar la recomendación del día
  void _seleccionarRecomendacionDelDia(List<GrupoPlato> grupos) {
    if (grupos.isEmpty) {
      _recomendacionDelDia = null;
      return;
    }

    final categoriaPrioritaria = _getCategoriaPrioritaria();
    
    // Filtrar grupos por categoría prioritaria
    List<GrupoPlato> gruposPrioritarios = grupos.where((grupo) {
      // Verificar si algún plato del grupo tiene la categoría prioritaria
      return grupo.platos.any((plato) => plato.categoria.toLowerCase() == categoriaPrioritaria);
    }).toList();

    // Si no hay grupos con la categoría prioritaria, usar todos los grupos
    if (gruposPrioritarios.isEmpty) {
      gruposPrioritarios = grupos;
    }

    // Seleccionar un grupo aleatorio de los prioritarios
    if (gruposPrioritarios.isNotEmpty) {
      gruposPrioritarios.shuffle();
      _recomendacionDelDia = gruposPrioritarios.first;
    } else {
      _recomendacionDelDia = null;
    }
  }

  Future<void> _loadGruposPlatos({bool loadMore = false}) async {
    if (!loadMore) {
      setState(() {
        _isLoading = true;
        _gruposPlatos = [];
        _lastDocument = null;
        _recomendacionDelDia = null;
      });
    }

    try {
      Query query = _db.collection('foods')
        .where('visibility', isEqualTo: 'publico')
        .orderBy('name')
        .limit(_pageSize);

      if (_lastDocument != null) {
        query = query.startAfterDocument(_lastDocument!);
      }

      final foodsSnapshot = await query.get();

      if (foodsSnapshot.docs.isEmpty) {
        setState(() {
          _hasMore = false;
          _isLoading = false;
        });
        return;
      }

      // Agrupar platos por nombre similar
      final Map<String, GrupoPlato> gruposMap = {};

      for (final foodDoc in foodsSnapshot.docs) {
        final foodData = foodDoc.data() as Map<String, dynamic>;
        final restaurantId = foodData['restaurantId'] as String?;
        
        if (restaurantId == null) continue;

        // Verificar si el restaurante es público
        final restaurantDoc = await _db.collection('restaurants').doc(restaurantId).get();
        if (!restaurantDoc.exists) continue;
        
        final restaurantData = restaurantDoc.data() as Map<String, dynamic>;
        if (restaurantData['visibility'] != 'publico') continue;

        final foodName = (foodData['name'] as String? ?? '').toLowerCase().trim();
        final String grupoKey = _getGrupoKey(foodName);

        if (!gruposMap.containsKey(grupoKey)) {
          gruposMap[grupoKey] = GrupoPlato(
            nombrePlato: foodName,
            platos: [],
            restaurantesCount: 0,
          );
        }

        gruposMap[grupoKey]!.platos.add(PlatoInfo(
          id: foodDoc.id,
          nombre: foodData['name'] ?? '',
          descripcion: foodData['description'] ?? '',
          restaurantId: restaurantId,
          imageBase64: foodData['imageBase64'],
          categoria: foodData['category'] ?? 'cualquiera',
        ));
      }

      // Calcular conteo de restaurantes únicos para cada grupo
      for (final grupo in gruposMap.values) {
        final uniqueRestaurants = <String>{};
        for (final plato in grupo.platos) {
          uniqueRestaurants.add(plato.restaurantId);
        }
        grupo.restaurantesCount = uniqueRestaurants.length;
      }

      final newGrupos = gruposMap.values.toList();

      setState(() {
        if (loadMore) {
          _gruposPlatos.addAll(newGrupos);
        } else {
          _gruposPlatos = newGrupos;
          // Seleccionar recomendación del día solo en la primera carga
          _seleccionarRecomendacionDelDia(newGrupos);
        }
        _filterGrupos();
        _lastDocument = foodsSnapshot.docs.last;
        _hasMore = foodsSnapshot.docs.length == _pageSize;
        _isLoading = false;
      });

    } catch (e) {
      print('Error cargando platos agrupados: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al cargar platos: $e')),
      );
    }
  }

  String _getGrupoKey(String foodName) {
    // Normalizar el nombre para agrupar variaciones similares
    String normalized = foodName
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9áéíóúñ]'), '')
        .trim();

    // Remover prefijos/sufijos comunes
    final commonWords = ['de', 'la', 'el', 'los', 'las', 'con', 'sin', 'al'];
    for (final word in commonWords) {
      normalized = normalized.replaceAll(word, '');
    }

    return normalized;
  }

  void _onPlatoTap(GrupoPlato grupo) {
    final platoAleatorio = grupo.platos.isNotEmpty 
        ? (grupo.platos..shuffle()).first 
        : null;
    
    if (platoAleatorio != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DetallePlatoScreen(
            plato: platoAleatorio,
            grupo: grupo,
          ),
        ),
      );
    }
  }

  // Widget para la recomendación del día
  Widget _buildRecomendacionDelDia() {
    if (_recomendacionDelDia == null) return const SizedBox();

    final grupo = _recomendacionDelDia!;
    final platoAleatorio = grupo.platos.isNotEmpty 
        ? (grupo.platos..shuffle()).first 
        : null;

    if (platoAleatorio == null) return const SizedBox();

    final categoriaPrioritaria = _getCategoriaPrioritaria();
    String mensajeCategoria = '';
    
    switch (categoriaPrioritaria) {
      case 'desayuno':
        mensajeCategoria = '¡Perfecto para empezar el día!';
        break;
      case 'almuerzo':
        mensajeCategoria = '¡Ideal para tu comida!';
        break;
      case 'cena':
        mensajeCategoria = '¡Perfecto para cerrar el día!';
        break;
      default:
        mensajeCategoria = '¡Recomendación especial!';
    }

    Uint8List? imageBytes;
    if (platoAleatorio.imageBase64 != null && platoAleatorio.imageBase64!.isNotEmpty) {
      try {
        imageBytes = base64Decode(platoAleatorio.imageBase64!);
      } catch (e) {
        print('Error decodificando imagen: $e');
      }
    }

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.star, color: Colors.amber.shade700, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Recomendación del Día',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              mensajeCategoria,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 12),
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: imageBytes != null
                  ? Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(8),
                        image: DecorationImage(
                          image: MemoryImage(imageBytes),
                          fit: BoxFit.cover,
                        ),
                      ),
                    )
                  : Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(Icons.fastfood, color: Colors.grey),
                    ),
              title: Text(
                grupo.nombrePlato,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  FutureBuilder<DocumentSnapshot>(
                    future: _db.collection('restaurants').doc(platoAleatorio.restaurantId).get(),
                    builder: (context, snapshot) {
                      if (snapshot.hasData && snapshot.data!.exists) {
                        final restaurantData = snapshot.data!.data() as Map<String, dynamic>;
                        final restaurantName = restaurantData['name'] ?? 'Restaurante';
                        return Text(
                          restaurantName,
                          style: const TextStyle(fontSize: 14),
                        );
                      }
                      return const Text(
                        'Restaurante',
                        style: TextStyle(fontSize: 14),
                      );
                    },
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      CalificacionPromedio(
                        restaurantId: platoAleatorio.restaurantId,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '• ${grupo.restaurantesCount} restaurante${grupo.restaurantesCount != 1 ? 's' : ''}',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () => _onPlatoTap(grupo),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Sabores de mi Tierra'),
      ),
      bottomNavigationBar: const CustomBottomNav(selectedIndex: 0),
      body: Column(
        children: [
          // Recomendación del día (encima de la barra de búsqueda)
          if (_recomendacionDelDia != null) _buildRecomendacionDelDia(),
          
          // Barra de búsqueda (solo afecta a la lista)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Buscar platos...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          
          // Lista de platos agrupados (solo esta se ve afectada por la búsqueda)
          Expanded(
            child: _isLoading && _gruposPlatos.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : _filteredGrupos.isEmpty && _searchQuery.isNotEmpty
                    ? const Center(
                        child: Text('No se encontraron platos'),
                      )
                    : _filteredGrupos.isEmpty
                    ? const Center(
                        child: Text('No se encontraron platos'),
                      )
                    : ListView.builder(
                        itemCount: _filteredGrupos.length + (_hasMore ? 1 : 0),
                        itemBuilder: (context, index) {
                          if (index == _filteredGrupos.length) {
                            if (_hasMore) {
                              _loadGruposPlatos(loadMore: true);
                              return const Padding(
                                padding: EdgeInsets.all(16.0),
                                child: Center(child: CircularProgressIndicator()),
                              );
                            }
                            return const SizedBox();
                          }
                          
                          final grupo = _filteredGrupos[index];
                          final platoAleatorio = grupo.platos.isNotEmpty 
                              ? (grupo.platos..shuffle()).first 
                              : null;
                          
                          return platoAleatorio == null 
                              ? const SizedBox()
                              : _buildPlatoCard(grupo, platoAleatorio);
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlatoCard(GrupoPlato grupo, PlatoInfo plato) {
    Uint8List? imageBytes;
    
    if (plato.imageBase64 != null && plato.imageBase64!.isNotEmpty) {
      try {
        imageBytes = base64Decode(plato.imageBase64!);
      } catch (e) {
        print('Error decodificando imagen: $e');
      }
    }

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: ListTile(
        leading: imageBytes != null
            ? Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(8),
                  image: DecorationImage(
                    image: MemoryImage(imageBytes),
                    fit: BoxFit.cover,
                  ),
                ),
              )
            : Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.fastfood, color: Colors.grey),
              ),
        title: Text(
          grupo.nombrePlato,
          style: const TextStyle(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<DocumentSnapshot>(
              future: _db.collection('restaurants').doc(plato.restaurantId).get(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!.exists) {
                  final restaurantData = snapshot.data!.data() as Map<String, dynamic>;
                  final restaurantName = restaurantData['name'] ?? 'Restaurante';
                  return Text(
                    restaurantName,
                    style: const TextStyle(fontSize: 12),
                  );
                }
                return const Text(
                  'Restaurante',
                  style: TextStyle(fontSize: 12),
                );
              },
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                CalificacionPromedio(
                  restaurantId: plato.restaurantId,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  '• ${grupo.restaurantesCount} restaurante${grupo.restaurantesCount != 1 ? 's' : ''}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ],
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: () => _onPlatoTap(grupo),
      ),
    );
  }

  ImageProvider _base64ToImage(String base64String) {
    try {
      return MemoryImage(_base64Decode(base64String));
    } catch (e) {
      return const AssetImage('assets/placeholder_food.png');
    }
  }

  Uint8List _base64Decode(String base64String) {
    try {
      return base64Decode(base64String);
    } catch (e) {
      return Uint8List(0);
    }
  }
}

class GrupoPlato {
  String nombrePlato;
  List<PlatoInfo> platos;
  int restaurantesCount;

  GrupoPlato({
    required this.nombrePlato,
    required this.platos,
    required this.restaurantesCount,
  });
}

class PlatoInfo {
  final String id;
  final String nombre;
  final String descripcion;
  final String restaurantId;
  final String? imageBase64;
  final String categoria;

  PlatoInfo({
    required this.id,
    required this.nombre,
    required this.descripcion,
    required this.restaurantId,
    this.imageBase64,
    required this.categoria,
  });
}