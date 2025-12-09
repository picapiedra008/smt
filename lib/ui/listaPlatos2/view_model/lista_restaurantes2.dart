// lib/ui/restaurantes/screens/restaurantes_screen.dart
import 'package:Sabores_de_mi_Tierra/ui/listaPlatos2/view_model/restaurant_card.dart';
import 'package:flutter/material.dart';
import 'package:Sabores_de_mi_Tierra/ui/listaPlatos2/repositories/restaurant_repositorie.dart';
import 'package:Sabores_de_mi_Tierra/widgets/calificacion_promedio.dart';
import 'package:Sabores_de_mi_Tierra/ui/formularioRestaurante/view_model/formularioRestaurante.dart';
import 'package:Sabores_de_mi_Tierra/ui/vistaRestaurantComensal/view_model/vista_restaurant_comensal.dart';
import 'package:Sabores_de_mi_Tierra/widgets/bottom_nav_var.dart';

class RestaurantesScreen extends StatefulWidget {
  const RestaurantesScreen({super.key});

  @override
  State<RestaurantesScreen> createState() => _RestaurantesScreenState();
}

class _RestaurantesScreenState extends State<RestaurantesScreen> {
  final RestaurantRepository _repository = RestaurantRepository();
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  
  List<Restaurante> _restaurantes = [];
  bool _isLoading = true;
  bool _loadingMore = false;
  bool _soloAbiertos = true; // Empieza activo
  String _searchQuery = '';
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _setupScrollListener();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _setupScrollListener() {
    _scrollController.addListener(() {
      if (_scrollController.position.pixels == 
          _scrollController.position.maxScrollExtent) {
        if (!_loadingMore && _repository.hasMore && !_isSearching) {
          _loadMoreData();
        }
      }
    });
  }

  Future<void> _loadInitialData() async {
    setState(() => _isLoading = true);
    
    try {
      final restaurantes = await _repository.getRestaurantes(
        searchQuery: _searchQuery,
        soloAbiertos: _soloAbiertos,
        resetPagination: true,
      );
      
      setState(() {
        _restaurantes = restaurantes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al cargar restaurantes: $e');
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadMoreData() async {
    if (_loadingMore || !_repository.hasMore) return;
    
    setState(() => _loadingMore = true);
    
    try {
      final nuevosRestaurantes = await _repository.loadMoreRestaurantes(
        searchQuery: _searchQuery,
        soloAbiertos: _soloAbiertos,
      );
      
      setState(() {
        _restaurantes = nuevosRestaurantes;
        _loadingMore = false;
      });
    } catch (e) {
      print('Error al cargar más restaurantes: $e');
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _buscarRestaurantes() async {
    if (_searchQuery.isEmpty && !_soloAbiertos) {
      // Si no hay filtros, usar paginación normal
      _isSearching = false;
      await _loadInitialData();
      return;
    }

    setState(() {
      _isLoading = true;
      _isSearching = true;
    });

    try {
      final restaurantes = await _repository.buscarRestaurantes(
        searchQuery: _searchQuery,
        soloAbiertos: _soloAbiertos,
      );
      
      setState(() {
        _restaurantes = restaurantes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error al buscar restaurantes: $e');
      setState(() => _isLoading = false);
      _showErrorSnackbar('Error al buscar restaurantes');
    }
  }

  void _onSearchChanged(String query) {
    setState(() => _searchQuery = query);
    // Debounce para evitar muchas llamadas
    Future.delayed(const Duration(milliseconds: 500), () {
      if (mounted && query == _searchController.text) {
        _buscarRestaurantes();
      }
    });
  }

  void _onSoloAbiertosChanged(bool value) {
    setState(() => _soloAbiertos = value);
    _buscarRestaurantes();
  }

  void _showErrorSnackbar(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
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
      body: Column(
        children: [
          // Filtros de búsqueda
          _buildSearchFilters(),
          
          // Lista de restaurantes
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _restaurantes.isEmpty
                    ? _buildEmptyState()
                    : _buildRestaurantesList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchFilters() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Encuentra un restaurante en específico",
            style: TextStyle(color: Colors.black54),
          ),
          const SizedBox(height: 10),
          
          // Campo de búsqueda
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              prefixIcon: const Icon(Icons.search),
              hintText: 'Buscar restaurantes...',
              filled: true,
              fillColor: Theme.of(context).colorScheme.surface,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: 1.0,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                  width: 1.0,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: Theme.of(context).colorScheme.primary,
                  width: 2.0,
                ),
              ),
            ),
            onChanged: _onSearchChanged,
          ),
          
          const SizedBox(height: 16),
          
          // Filtro de solo abiertos - ENCUADRADO CON TEMA
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _soloAbiertos 
                    ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                    : Theme.of(context).colorScheme.outline.withOpacity(0.2),
                width: 1.5,
              ),
              boxShadow: _soloAbiertos
                  ? [
                      BoxShadow(
                        color: Theme.of(context).colorScheme.primary.withOpacity(0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ]
                  : null,
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Icono con color condicional
                Icon(
                  Icons.access_time,
                  color: _soloAbiertos
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  size: 24,
                ),
                const SizedBox(width: 12),
                
                // Texto
                Expanded(
                  child: Text(
                    'Mostrar solo restaurantes abiertos',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: _soloAbiertos
                          ? Theme.of(context).colorScheme.onSurface
                          : Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                
                // Switch con tema
                Switch(
                  value: _soloAbiertos,
                  onChanged: _onSoloAbiertosChanged,
                  activeColor: Theme.of(context).colorScheme.primary,
                  activeTrackColor: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                  inactiveThumbColor: Theme.of(context).colorScheme.outline,
                  inactiveTrackColor: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Contador de resultados
          if (!_isLoading && _restaurantes.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.restaurant,
                    size: 16,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_restaurantes.length} restaurante${_restaurantes.length != 1 ? 's' : ''} encontrado${_restaurantes.length != 1 ? 's' : ''}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRestaurantesList() {
    return NotificationListener<ScrollNotification>(
      onNotification: (scrollNotification) {
        if (scrollNotification is ScrollEndNotification &&
            !_isSearching &&
            _repository.hasMore &&
            !_loadingMore) {
          _loadMoreData();
        }
        return false;
      },
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: _restaurantes.length + (_loadingMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == _restaurantes.length) {
            return _buildLoadingMoreIndicator();
          }
          
          final restaurante = _restaurantes[index];
          return RestauranteCard(
            restaurante: restaurante,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => RestaurantUserView(
                    restaurantId: restaurante.id,
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLoadingMoreIndicator() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        children: [
          Center(
            child: _repository.hasMore
                ? SizedBox(
                    width: 30,
                    height: 30,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  )
                : Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'No hay más restaurantes',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.restaurant_menu,
                size: 60,
                color: Theme.of(context).colorScheme.onSurfaceVariant.withOpacity(0.5),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              _searchQuery.isNotEmpty || _soloAbiertos
                  ? 'No se encontraron restaurantes'
                  : 'No hay restaurantes disponibles',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Intenta con otros términos de búsqueda'
                  : _soloAbiertos
                      ? 'Prueba desactivando el filtro de "solo abiertos"'
                      : 'Vuelve más tarde para ver nuevos restaurantes',
              style: TextStyle(
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            if (_searchQuery.isNotEmpty || _soloAbiertos)
              ElevatedButton(
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                    _soloAbiertos = false;
                  });
                  _loadInitialData();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text('Limpiar filtros'),
              ),
          ],
        ),
      ),
    );
  }
}