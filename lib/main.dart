import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
// geolocator removed (not used) to keep imports clean
import 'package:geocoding/geocoding.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

void main() {
  runApp(const MyApp());
}

class LocationPickerDialog extends StatefulWidget {
  final String initialLocation;
  const LocationPickerDialog({super.key, required this.initialLocation});

  @override
  State<LocationPickerDialog> createState() => _LocationPickerDialogState();
}

class _LocationPickerDialogState extends State<LocationPickerDialog> {
  final TextEditingController _searchController = TextEditingController();
  LatLng? _selectedLatLng;
  final Completer<GoogleMapController> _mapController = Completer();
  // selected name handled by returning selection to caller
  String _status = '';
  bool _isSearching = false;
  final List<Map<String, dynamic>> _suggestions = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Try to geocode the initial location to center the map
    Future.microtask(() async {
      try {
        final locs = await locationFromAddress(widget.initialLocation);
        if (locs.isNotEmpty) {
          final first = locs.first;
          setState(() {
            _selectedLatLng = LatLng(first.latitude, first.longitude);
          });
          final controller = await _mapController.future;
          controller.animateCamera(CameraUpdate.newLatLng(_selectedLatLng!));
        }
      } catch (_) {}
    });
  }

  Future<void> _searchAddress() async {
    final query = _searchController.text.trim();
    if (query.isEmpty) return;
    setState(() {
      _isSearching = true;
      _status = 'Buscando...';
      _suggestions.clear();
    });
    try {
      final locations = await locationFromAddress(query);
      if (locations.isNotEmpty) {
        for (final loc in locations) {
          final lat = loc.latitude;
          final lon = loc.longitude;
          String name = '${lat.toStringAsFixed(4)}, ${lon.toStringAsFixed(4)}';
          try {
            final placemarks = await placemarkFromCoordinates(lat, lon);
            if (placemarks.isNotEmpty) {
              final p = placemarks.first;
              name = '${p.locality ?? p.subAdministrativeArea ?? query}${p.country != null ? ', ${p.country}' : ''}';
            }
          } catch (_) {}
          _suggestions.add({'lat': lat, 'lon': lon, 'name': name});
        }
        // Center map on first result
        final first = locations.first;
        setState(() {
          _selectedLatLng = LatLng(first.latitude, first.longitude);
        });
        try {
          final ctrl = await _mapController.future;
          ctrl.animateCamera(CameraUpdate.newLatLng(_selectedLatLng!));
        } catch (_) {}
        setState(() {
          _status = 'Resultados:';
        });
      } else {
        setState(() {
          _status = 'No se encontró la localidad';
        });
      }
    } catch (e) {
      setState(() {
        _status = 'Error al buscar: $e';
      });
    } finally {
      setState(() {
        _isSearching = false;
      });
    }
  }

  Future<void> _selectCurrentLatLng() async {
    if (_selectedLatLng == null) return;
    try {
      final p = await placemarkFromCoordinates(_selectedLatLng!.latitude, _selectedLatLng!.longitude);
      String name;
      if (p.isNotEmpty) {
        final a = p.first;
        name = '${a.locality ?? a.subAdministrativeArea ?? ''}${a.country != null ? ', ${a.country}' : ''}';
        name = name.trim();
      } else {
        name = '${_selectedLatLng!.latitude.toStringAsFixed(4)}, ${_selectedLatLng!.longitude.toStringAsFixed(4)}';
      }
      Navigator.of(context).pop(name);
    } catch (e) {
      Navigator.of(context).pop('${_selectedLatLng!.latitude.toStringAsFixed(4)}, ${_selectedLatLng!.longitude.toStringAsFixed(4)}');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AppBar(
          title: const Text('Cambiar ubicación'),
          automaticallyImplyLeading: false,
        ),
        SizedBox(
          height: 16,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchController,
                  decoration: const InputDecoration(
                    hintText: 'Buscar localidad, ej: London, UK',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _isSearching ? null : _searchAddress,
                child: _isSearching ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Buscar'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_status.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            child: Text(_status),
          ),
        const SizedBox(height: 8),
        // Suggestions list
        if (_suggestions.isNotEmpty)
          SizedBox(
            height: 160,
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              itemCount: _suggestions.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (context, idx) {
                      final s = _suggestions[idx];
                      return ListTile(
                        title: Text(s['name'] ?? ''),
                        subtitle: Text('${(s['lat'] as double).toStringAsFixed(4)}, ${(s['lon'] as double).toStringAsFixed(4)}'),
                        onTap: () async {
                          // set selection and center map, then return name
                          final lat = s['lat'] as double;
                          final lon = s['lon'] as double;
                          setState(() {
                            _selectedLatLng = LatLng(lat, lon);
                          });
                          try {
                            final ctrl = await _mapController.future;
                            ctrl.animateCamera(CameraUpdate.newLatLng(_selectedLatLng!));
                          } catch (_) {}
                          Navigator.of(context).pop(s['name'] as String);
                        },
                      );
                    },
            ),
          ),
        const SizedBox(height: 8),
        // Map area (simple): if selectedLatLng present show small map, otherwise hint
        SizedBox(
          height: 240,
          child: GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _selectedLatLng ?? const LatLng(-17.397, -66.157),
              zoom: 12,
            ),
            onMapCreated: (controller) {
              if (!_mapController.isCompleted) {
                _mapController.complete(controller);
              }
            },
            onTap: (pos) async {
              setState(() {
                _selectedLatLng = pos;
              });
              try {
                final places = await placemarkFromCoordinates(pos.latitude, pos.longitude);
                if (places.isNotEmpty) {
                  final p = places.first;
                  setState(() {
                    _status = '${p.locality ?? p.subAdministrativeArea ?? ''}${p.country != null ? ', ${p.country}' : ''}';
                  });
                }
              } catch (_) {}
            },
            markers: _selectedLatLng != null
                ? {
                    Marker(markerId: const MarkerId('sel'), position: _selectedLatLng!),
                  }
                : {},
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                onPressed: _selectedLatLng == null ? null : _selectCurrentLatLng,
                child: const Text('Seleccionar'),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _isDarkMode = false;

  void _toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sabores de Mi Tierra',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFFE91E63),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF5F5F5),
        cardColor: Colors.white,
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2196F3),
          primary: const Color(0xFF2196F3),
          secondary: const Color(0xFFE91E63),
          brightness: Brightness.dark,
        ),
        scaffoldBackgroundColor: const Color(0xFF121212),
        cardColor: const Color(0xFF1E1E1E),
        useMaterial3: true,
      ),
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      home: HomePage(
        toggleDarkMode: _toggleDarkMode,
        isDarkMode: _isDarkMode,
      ),
    );
  }
}

class HomePage extends StatefulWidget {
  final VoidCallback toggleDarkMode;
  final bool isDarkMode;

  const HomePage({
    super.key,
    required this.toggleDarkMode,
    required this.isDarkMode,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

// Modelo de datos para platos
class Dish {
  final String name;
  final String description;
  final double rating;
  final int restaurantCount;
  final double distance; // en kilómetros
  final String category;

  Dish({
    required this.name,
    required this.description,
    required this.rating,
    required this.restaurantCount,
    required this.distance,
    required this.category,
  });
}

class _HomePageState extends State<HomePage> {
  String _location = 'Cochabamba - Bolivia';
  String _dateTime = '';
  String _temperature = '--';
  String _weatherIcon = '';
  String _weatherDescription = '';
  bool _isLoadingWeather = false;
  
  // Búsqueda y filtros
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _countController = TextEditingController();
  bool _isProgrammaticCountUpdate = false;
  String _searchQuery = '';
  int _resultCount = 10; // default 10
  
  // Lista de platos disponibles
  final List<Dish> _allDishes = [
    Dish(name: 'Pique Macho', description: 'Plato típico con carne, papas y verduras', rating: 4.8, restaurantCount: 15, distance: 0.5, category: 'Almuerzo'),
    Dish(name: 'Salteña Paceña', description: 'La salteña más auténtica de La Paz', rating: 4.9, restaurantCount: 12, distance: 0.8, category: 'Desayuno'),
    Dish(name: 'Chuleta de Cerdo', description: 'Chuleta jugosa con papas fritas', rating: 4.7, restaurantCount: 20, distance: 1.2, category: 'Almuerzo'),
    Dish(name: 'Sopa de Maní', description: 'Sopa tradicional boliviana', rating: 4.6, restaurantCount: 18, distance: 0.3, category: 'Almuerzo'),
    Dish(name: 'Silpancho', description: 'Carne empanizada con arroz y huevo', rating: 4.9, restaurantCount: 25, distance: 0.6, category: 'Almuerzo'),
    Dish(name: 'Fricase', description: 'Plato tradicional con carne de cerdo', rating: 4.8, restaurantCount: 10, distance: 1.5, category: 'Almuerzo'),
    Dish(name: 'Ají de Fideo', description: 'Fideos con ají y carne', rating: 4.5, restaurantCount: 14, distance: 0.9, category: 'Almuerzo'),
    Dish(name: 'Pollo a la Broaster', description: 'Pollo crujiente con papas', rating: 4.7, restaurantCount: 22, distance: 1.1, category: 'Almuerzo'),
    Dish(name: 'Tucumana', description: 'Empanada frita rellena', rating: 4.6, restaurantCount: 16, distance: 0.4, category: 'Desayuno'),
    Dish(name: 'Lawa', description: 'Sopa espesa de maíz', rating: 4.4, restaurantCount: 8, distance: 1.8, category: 'Almuerzo'),
    Dish(name: 'Chairo', description: 'Sopa de chuño y carne', rating: 4.7, restaurantCount: 12, distance: 0.7, category: 'Almuerzo'),
    Dish(name: 'Anticucho', description: 'Brochetas de corazón de res', rating: 4.8, restaurantCount: 19, distance: 1.0, category: 'Cena'),
  ];
  
  // OpenWeatherMap configuration
  static const String _apiKey = 'fb8194e4216e7c02a6cf94a12958d53d';
  
  @override
  void dispose() {
    _searchController.dispose();
    _countController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _updateDateTime();
    _startTimer();
    _fetchWeather();
    // initialize counter controller with default
    _updateCountController(_resultCount);
  }

  void _updateDateTime() {
    final now = DateTime.now();
    final dayNames = ['Dom', 'Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb'];
    final monthNames = [
      'Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun',
      'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'
    ];
    final dayOfWeek = dayNames[now.weekday == 7 ? 0 : now.weekday - 1];
    final day = now.day.toString().padLeft(2, '0');
    final month = monthNames[now.month - 1];
    final year = now.year.toString().substring(2);
    final hour = now.hour.toString().padLeft(2, '0');
    final minute = now.minute.toString().padLeft(2, '0');
    final formattedDate = '$dayOfWeek $day-$month-$year @ $hour:$minute';
    setState(() {
      _dateTime = formattedDate;
    });
  }

  void _startTimer() {
    Future.delayed(const Duration(seconds: 60), () {
      if (mounted) {
        _updateDateTime();
        _startTimer();
      }
    });
  }

  Future<void> _fetchWeather() async {
    setState(() {
      _isLoadingWeather = true;
    });

    try {
      // Compose query from _location string: prefer comma-separated names
      String query = _location;
      if (query.contains('-')) {
        query = query.split('-').first.trim();
      }
      query = query.replaceAll(' ', '+');

      final url = Uri.https('api.openweathermap.org', '/data/2.5/weather', {
        'q': query,
        'appid': _apiKey,
        'units': 'metric',
        'lang': 'es',
      });

      final response = await http.get(url).timeout(
        const Duration(seconds: 10),
        onTimeout: () {
          throw Exception('Timeout al obtener el clima');
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final temp = (data['main']?['temp'] ?? 0).round().toString();
        final weatherMain = (data['weather']?[0]?['main'] ?? '').toString().toLowerCase();
        final weatherIcon = _getWeatherIcon(weatherMain);
        final description = (data['weather'] != null && data['weather'].isNotEmpty) ? (data['weather'][0]['description'] ?? '') : '';

        setState(() {
          _temperature = temp;
          _weatherIcon = weatherIcon;
          _weatherDescription = description.toString();
          _isLoadingWeather = false;
        });
      } else {
        throw Exception('Error al obtener el clima: ${response.statusCode}');
      }
    } catch (e) {
      // En caso de error, usar datos de ejemplo
      setState(() {
        _temperature = '24';
        _weatherIcon = '☀️';
        _weatherDescription = 'despejado';
        _isLoadingWeather = false;
      });
    }
  }

  Future<void> _showWeatherDetails() async {
    try {
      String query = _location;
      if (query.contains('-')) query = query.split('-').first.trim();

      final url = Uri.https('api.openweathermap.org', '/data/2.5/forecast', {
        'q': query.replaceAll(' ', '+'),
        'appid': _apiKey,
        'units': 'metric',
        'lang': 'es',
      });

      final response = await http.get(url).timeout(const Duration(seconds: 10));
      if (response.statusCode != 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al obtener pronóstico: ${response.statusCode}')),
        );
        return;
      }

      final data = json.decode(response.body);
      final List items = data['list'] ?? [];
      final display = items.take(8).toList(); // ~24 horas

      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('Pronóstico para $_location'),
          content: SizedBox(
            width: double.maxFinite,
            height: 320,
            child: ListView.separated(
              itemCount: display.length,
              separatorBuilder: (_, __) => const Divider(),
              itemBuilder: (context, index) {
                final it = display[index];
                final dt = it['dt_txt'] ?? '';
                final temp = (it['main']?['temp'] ?? 0).toString();
                final desc = it['weather'] != null && it['weather'].isNotEmpty ? it['weather'][0]['description'] : '';
                final main = it['weather'] != null && it['weather'].isNotEmpty ? (it['weather'][0]['main'] ?? '') : '';
                final icon = _getWeatherIcon(main.toString().toLowerCase());
                return ListTile(
                  leading: Text(icon, style: const TextStyle(fontSize: 20)),
                  title: Text(dt),
                  subtitle: Text(desc.toString()),
                  trailing: Text('${double.tryParse(temp)?.round() ?? temp}°C'),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(context).pop(), child: const Text('Cerrar')),
          ],
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al obtener pronóstico: $e')),
      );
    }
  }

  String _getWeatherIcon(String weatherMain) {
    switch (weatherMain) {
      case 'clear':
        return '☀️';
      case 'clouds':
        return '☁️';
      case 'rain':
        return '🌧️';
      case 'drizzle':
        return '🌦️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }

  void _updateCountController(int? value) {
    _isProgrammaticCountUpdate = true;
    if (value == null || value == 0) {
      _countController.clear();
    } else {
      final text = value.toString();
      _countController.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
    _isProgrammaticCountUpdate = false;
  }

  void _setResultCount(int value) {
    final clamped = value.clamp(1, 99);
    setState(() {
      _resultCount = clamped;
    });
    _updateCountController(clamped);
  }

  void _incrementCount() {
    if (_resultCount == 0) {
      _setResultCount(1);
      return;
    }
    if (_resultCount < 99) {
      _setResultCount(_resultCount + 1);
    }
  }

  void _decrementCount() {
    if (_resultCount == 0 || _resultCount == 1) {
      _setResultCount(1);
      return;
    }
    _setResultCount(_resultCount - 1);
  }
  

  List<Dish> get _filteredDishes {
    List<Dish> result;
    
    if (_searchQuery.isEmpty) {
      // Sin búsqueda: los más cercanos, al azar si no hay límite
      result = List<Dish>.from(_allDishes);
      if (_resultCount == 0) {
        // Al azar pero ordenados por distancia
        result.shuffle();
        result.sort((a, b) => a.distance.compareTo(b.distance));
      } else {
        // Ordenados por distancia (más cercanos primero)
        result.sort((a, b) => a.distance.compareTo(b.distance));
        result = result.take(_resultCount).toList();
      }
    } else {
      // Con búsqueda: filtrar y ordenar por distancia (más cercano al más lejano)
      result = _allDishes.where((dish) {
        return dish.name.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               dish.description.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               dish.category.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
      result.sort((a, b) => a.distance.compareTo(b.distance));
      if (_resultCount > 0) {
        result = result.take(_resultCount).toList();
      }
    }
    
    return result;
  }

  // Método para obtener tamaños responsivos
  double _getResponsiveSize(BuildContext context, {
    required double mobile,
    required double tablet,
    required double desktop,
  }) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return desktop;
    if (width > 600) return tablet;
    return mobile;
  }

  Future<void> _openLocationPicker() async {
    final result = await showDialog<String>(
      context: context,
      builder: (context) => Dialog(
        child: SizedBox(
          width: 600,
          child: LocationPickerDialog(initialLocation: _location),
        ),
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() {
        _location = result;
      });
      // After changing location, fetch weather for the new location
      await _fetchWeather();
    }
  }

  @override
  Widget build(BuildContext context) {
    // responsive sizes computed per widget where needed
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth > 1200;
    final isTablet = screenWidth > 600;

    return DefaultTextStyle(
      style: const TextStyle(height: 1.0),
      child: Scaffold(
        body: Column(
          children: [
            _buildHeader(isTablet, isDesktop),
            Expanded(
              child: isTablet ? _buildTabletLayout() : _buildMobileLayout(),
            ),
            // Global footer placed below main content so it appears in all layouts
            _buildFooter(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isTablet, bool isDesktop) {
    final logoSize = _getResponsiveSize(
      context,
      mobile: 40.0,
      tablet: 50.0,
      desktop: 60.0,
    );

    final fontSizeLocation = _getResponsiveSize(
      context,
      mobile: 14.0,
      tablet: 16.0,
      desktop: 18.0,
    );

    // date/time moved to main area (Recomendado Hoy)

    final fontSizeTemp = _getResponsiveSize(
      context,
      mobile: 16.0,
      tablet: 18.0,
      desktop: 20.0,
    );

    final fontSizeAppName = _getResponsiveSize(
      context,
      mobile: 24.0,
      tablet: 28.0,
      desktop: 32.0,
    );

    final iconSize = _getResponsiveSize(
      context,
      mobile: 18.0,
      tablet: 20.0,
      desktop: 24.0,
    );

    final iconsWidth = _getResponsiveSize(context, mobile: 56.0, tablet: 64.0, desktop: 72.0);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 24.0),
        vertical: _getResponsiveSize(context, mobile: 10.0, tablet: 12.0, desktop: 16.0),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(widget.isDarkMode ? 0.3 : 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Top row: logo | title centered | icons column (settings + dark-mode)
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo on the left
              Image.asset(
                widget.isDarkMode 
                    ? 'assets/images/logos/logo2.png' 
                    : 'assets/images/logos/logo.png',
                height: logoSize,
                width: logoSize,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.restaurant,
                    size: logoSize,
                    color: Theme.of(context).colorScheme.secondary,
                  );
                },
              ),
              // Title centered
              Expanded(
                child: Center(
                  child: Text(
                    'Sabores de Mi Tierra',
                    style: TextStyle(
                      fontSize: fontSizeAppName,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
              // Right icons column (settings above, dark-mode below)
              Container(
                width: iconsWidth,
                alignment: Alignment.center,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      icon: Icon(Icons.settings, size: iconSize),
                      color: Theme.of(context).colorScheme.onSurface,
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Ajustes')),
                        );
                      },
                    ),
                    SizedBox(height: 4),
                    IconButton(
                      icon: Icon(
                        widget.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                        size: iconSize * 1.15,
                      ),
                      color: Theme.of(context).colorScheme.onSurface,
                      onPressed: widget.toggleDarkMode,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: _getResponsiveSize(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
          // Second row: centered location + weather (between logo and icons column)
          Row(
            children: [
              // reserve left area equal to logo width so location is centered under title
              SizedBox(width: logoSize),
              Expanded(
                child: Center(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(Icons.location_on),
                        color: Theme.of(context).colorScheme.secondary,
                        iconSize: iconSize,
                        tooltip: 'Cambiar ubicación',
                        onPressed: _openLocationPicker,
                      ),
                      SizedBox(width: _getResponsiveSize(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
                      Flexible(
                        child: Text(
                          _location,
                          style: TextStyle(
                            fontSize: fontSizeLocation,
                            fontWeight: FontWeight.w600,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      SizedBox(width: _getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
                      _isLoadingWeather
                          ? SizedBox(
                              width: iconSize,
                              height: iconSize,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary,
                                ),
                              ),
                            )
                          : InkWell(
                              onTap: _showWeatherDetails,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _weatherIcon,
                                    style: TextStyle(fontSize: iconSize),
                                  ),
                                  SizedBox(width: _getResponsiveSize(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
                                  Column(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        '$_temperature°C',
                                        style: TextStyle(
                                          fontSize: fontSizeTemp,
                                          fontWeight: FontWeight.w600,
                                          color: Theme.of(context).colorScheme.primary,
                                        ),
                                      ),
                                      if (_weatherDescription.isNotEmpty)
                                        Text(
                                          _weatherDescription,
                                          style: TextStyle(
                                            fontSize: fontSizeTemp * 0.65,
                                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.75),
                                          ),
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                    ],
                  ),
                ),
              ),
              // reserve right icons column width to keep horizontal alignment
              SizedBox(width: iconsWidth),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTabletLayout() {
    // tablet-specific sizing handled inline where needed

    return Row(
      children: [
        // Nav
        Container(
          width: _getResponsiveSize(context, mobile: 200.0, tablet: 220.0, desktop: 250.0),
          decoration: BoxDecoration(
            color: widget.isDarkMode 
                ? const Color(0xFF2D1F24) 
                : const Color(0xFFFFE0E6),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: _getResponsiveSize(context, mobile: 10.0, tablet: 14.0, desktop: 18.0),
            vertical: _getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0),
          ),
          child: _buildNav(),
        ),
        // Main content area
        Expanded(
          child: Row(
            children: [
              // Main
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isDarkMode 
                        ? const Color(0xFF1A1A1A) 
                        : const Color(0xFFFFF5F5),
                  ),
                  padding: EdgeInsets.all(_getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
                  child: _buildDishOfTheDay(),
                ),
              ),
              // Aside
              Expanded(
                flex: 1,
                child: Container(
                  decoration: BoxDecoration(
                    color: widget.isDarkMode 
                        ? const Color(0xFF2D1F24) 
                        : const Color(0xFFFFCCD5),
                  ),
                  padding: EdgeInsets.all(_getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
                  child: _buildAside(),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout() {
    

    return Column(
      children: [
        // Main
        Expanded(
          flex: 3,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.isDarkMode 
                  ? const Color(0xFF1A1A1A) 
                  : const Color(0xFFFFF5F5),
            ),
            padding: EdgeInsets.all(_getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
            child: _buildDishOfTheDay(),
          ),
        ),
        // Nav
        Container(
          width: double.infinity,
          height: _getResponsiveSize(context, mobile: 70.0, tablet: 80.0, desktop: 90.0),
          decoration: BoxDecoration(
            color: widget.isDarkMode 
                ? const Color(0xFF2D1F24) 
                : const Color(0xFFFFE0E6),
          ),
          padding: EdgeInsets.symmetric(
            horizontal: _getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0),
            vertical: _getResponsiveSize(context, mobile: 6.0, tablet: 8.0, desktop: 10.0),
          ),
          child: _buildNav(),
        ),
        // Aside
        Expanded(
          flex: 2,
          child: Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: widget.isDarkMode 
                  ? const Color(0xFF2D1F24) 
                  : const Color(0xFFFFCCD5),
            ),
            padding: EdgeInsets.all(_getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
            child: _buildAside(),
          ),
        ),
        // Footer removed from mobile layout — global footer used instead
      ],
    );
  }

  Widget _buildDishOfTheDay() {
    // responsive sizes computed per widget where needed
    
    final titleFontSize = _getResponsiveSize(
      context,
      mobile: 20.0,
      tablet: 24.0,
      desktop: 28.0,
    );

    final descriptionFontSize = _getResponsiveSize(
      context,
      mobile: 12.0,
      tablet: 14.0,
      desktop: 16.0,
    );

    final infoFontSize = _getResponsiveSize(
      context,
      mobile: 11.0,
      tablet: 13.0,
      desktop: 15.0,
    );

    return LayoutBuilder(
      builder: (context, constraints) {
        final available = constraints.maxHeight.isFinite && constraints.maxHeight > 0
            ? constraints.maxHeight
            : MediaQuery.of(context).size.height * 0.5;
        final imageHeight = available * 0.35; // keep image to a fraction so rest fits

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // "Recomendado Hoy" header
            Row(
              children: [
                Icon(
                  Icons.access_time,
                  color: Theme.of(context).colorScheme.secondary,
                  size: _getResponsiveSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
                ),
                SizedBox(width: _getResponsiveSize(context, mobile: 6.0, tablet: 8.0, desktop: 10.0)),
                Text(
                  'Recomendado Hoy',
                  style: TextStyle(
                    fontSize: _getResponsiveSize(context, mobile: 16.0, tablet: 18.0, desktop: 20.0),
                    fontWeight: FontWeight.w600,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const Spacer(),
                // Date/time aligned right, bold and highlighted
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _dateTime,
                    style: TextStyle(
                      fontSize: _getResponsiveSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: _getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
            // Dish card
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image with "Plato del Día" tag
                  Stack(
                    children: [
                      ClipRRect(
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                        child: Image.asset(
                          'assets/media/desserts/salteña.png',
                          width: double.infinity,
                          height: imageHeight,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              height: imageHeight,
                              color: Colors.grey[300],
                              child: const Center(
                                child: Icon(Icons.image_not_supported, size: 50),
                              ),
                            );
                          },
                        ),
                      ),
                      // "Plato del Día" tag
                      Positioned(
                        top: _getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0),
                        left: _getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0),
                        child: Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: _getResponsiveSize(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
                            vertical: _getResponsiveSize(context, mobile: 6.0, tablet: 8.0, desktop: 10.0),
                          ),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.secondary,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'Plato del Día',
                            style: TextStyle(
                              fontSize: _getResponsiveSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  // Dish information
                  Padding(
                    padding: EdgeInsets.all(_getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Dish name
                        Text(
                          'Salteña Paceña',
                          style: TextStyle(
                            fontSize: titleFontSize,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        SizedBox(height: _getResponsiveSize(context, mobile: 6.0, tablet: 8.0, desktop: 10.0)),
                        // Description
                        Text(
                          'La salteña más auténtica de La Paz, con carne jugosa, papa, huevo duro,...',
                          style: TextStyle(
                            fontSize: descriptionFontSize,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        SizedBox(height: _getResponsiveSize(context, mobile: 10.0, tablet: 12.0, desktop: 14.0)),
                        // Restaurant count, rating and button
                        Row(
                          children: [
                            // Restaurant count
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: _getResponsiveSize(context, mobile: 16.0, tablet: 18.0, desktop: 20.0),
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                SizedBox(width: _getResponsiveSize(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
                                Text(
                                  '12 restaurantes',
                                  style: TextStyle(
                                    fontSize: infoFontSize,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(width: _getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
                            // Rating
                            Row(
                              children: [
                                Icon(
                                  Icons.star,
                                  size: _getResponsiveSize(context, mobile: 16.0, tablet: 18.0, desktop: 20.0),
                                  color: Colors.amber,
                                ),
                                SizedBox(width: _getResponsiveSize(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
                                Text(
                                  '4.9',
                                  style: TextStyle(
                                    fontSize: infoFontSize,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            // View Restaurant button
                            ElevatedButton(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Ver Restaurantes')),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Theme.of(context).colorScheme.primary,
                                foregroundColor: Colors.white,
                                padding: EdgeInsets.symmetric(
                                  horizontal: _getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0),
                                  vertical: _getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0),
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                              child: Text(
                                'Ver Restaurantes',
                                style: TextStyle(
                                  fontSize: _getResponsiveSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildNav() {
    final searchField = Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).cardColor,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
            width: 1.5,
          ),
        ),
        child: TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Buscar platos ...',
            hintStyle: TextStyle(
              color: Colors.grey[500],
              fontSize: _getResponsiveSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
            ),
            prefixIcon: Icon(
              Icons.search,
              color: Colors.grey[600],
              size: _getResponsiveSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0),
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: EdgeInsets.symmetric(
              horizontal: _getResponsiveSize(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
              vertical: _getResponsiveSize(context, mobile: 6.0, tablet: 8.0, desktop: 10.0),
            ),
            isDense: true,
          ),
          style: TextStyle(
            fontSize: _getResponsiveSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
            });
          },
        ),
      ),
    );

    final counterWidth = _getResponsiveSize(context, mobile: 90.0, tablet: 100.0, desktop: 110.0);
    final counterField = Container(
      width: counterWidth,
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Theme.of(context).colorScheme.secondary.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      padding: EdgeInsets.symmetric(
        horizontal: _getResponsiveSize(context, mobile: 6.0, tablet: 8.0, desktop: 10.0),
        vertical: _getResponsiveSize(context, mobile: 6.0, tablet: 8.0, desktop: 10.0),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          InkWell(
            onTap: () {
              if (_resultCount > 1) _decrementCount();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text('-', style: TextStyle(fontSize: _getResponsiveSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0), fontWeight: FontWeight.bold)),
            ),
          ),
          Text(
            '$_resultCount',
            style: TextStyle(
              fontSize: _getResponsiveSize(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
              fontWeight: FontWeight.w700,
            ),
          ),
          InkWell(
            onTap: () {
              _incrementCount();
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
              child: Text('+', style: TextStyle(fontSize: _getResponsiveSize(context, mobile: 18.0, tablet: 20.0, desktop: 22.0), fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );

    return Row(
      children: [
        searchField,
        SizedBox(width: _getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
        counterField,
      ],
    );
  }

  Widget _buildAside() {
    final dishes = _filteredDishes;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Title
        Text(
          'Catálogo de Platos',
          style: TextStyle(
            fontSize: _getResponsiveSize(context, mobile: 16.0, tablet: 18.0, desktop: 20.0),
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        SizedBox(height: _getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
        // Dishes list
        Expanded(
          child: dishes.isEmpty
              ? Center(
                  child: Text(
                    'No se encontraron platos',
                    style: TextStyle(
                      fontSize: _getResponsiveSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0),
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                )
              : ListView.builder(
                  itemCount: dishes.length,
                  itemBuilder: (context, index) {
                    final dish = dishes[index];
                    return Card(
                      margin: EdgeInsets.only(
                        bottom: _getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0),
                      ),
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(_getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    dish.name,
                                    style: TextStyle(
                                      fontSize: _getResponsiveSize(context, mobile: 13.0, tablet: 15.0, desktop: 17.0),
                                      fontWeight: FontWeight.bold,
                                      color: Theme.of(context).colorScheme.onSurface,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: EdgeInsets.symmetric(
                                    horizontal: _getResponsiveSize(context, mobile: 6.0, tablet: 8.0, desktop: 10.0),
                                    vertical: _getResponsiveSize(context, mobile: 2.0, tablet: 4.0, desktop: 6.0),
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.secondary.withOpacity(0.2),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    dish.category,
                                    style: TextStyle(
                                      fontSize: _getResponsiveSize(context, mobile: 9.0, tablet: 11.0, desktop: 13.0),
                                      color: Theme.of(context).colorScheme.secondary,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            SizedBox(height: _getResponsiveSize(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
                            Text(
                              dish.description,
                              style: TextStyle(
                                fontSize: _getResponsiveSize(context, mobile: 11.0, tablet: 13.0, desktop: 15.0),
                                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            SizedBox(height: _getResponsiveSize(context, mobile: 6.0, tablet: 8.0, desktop: 10.0)),
                            Row(
                              children: [
                                Icon(
                                  Icons.location_on,
                                  size: _getResponsiveSize(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
                                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                ),
                                SizedBox(width: _getResponsiveSize(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
                                Text(
                                  '${dish.distance.toStringAsFixed(1)} km',
                                  style: TextStyle(
                                    fontSize: _getResponsiveSize(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                SizedBox(width: _getResponsiveSize(context, mobile: 8.0, tablet: 10.0, desktop: 12.0)),
                                Icon(
                                  Icons.star,
                                  size: _getResponsiveSize(context, mobile: 14.0, tablet: 16.0, desktop: 18.0),
                                  color: Colors.amber,
                                ),
                                SizedBox(width: _getResponsiveSize(context, mobile: 4.0, tablet: 6.0, desktop: 8.0)),
                                Text(
                                  dish.rating.toString(),
                                  style: TextStyle(
                                    fontSize: _getResponsiveSize(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                  ),
                                ),
                                const Spacer(),
            Text(
                                  '${dish.restaurantCount} rest.',
                                  style: TextStyle(
                                    fontSize: _getResponsiveSize(context, mobile: 10.0, tablet: 12.0, desktop: 14.0),
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ),
                              ],
            ),
          ],
        ),
      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    final fontSize = _getResponsiveSize(context, mobile: 12.0, tablet: 14.0, desktop: 16.0);
    return Container(
      width: double.infinity,
      color: widget.isDarkMode ? const Color(0xFF1A1A1A) : const Color(0xFFFFF5F5),
      padding: EdgeInsets.all(_getResponsiveSize(context, mobile: 12.0, tablet: 16.0, desktop: 20.0)),
      child: Center(
        child: Text(
          '(c) Master Devs, 2025)',
          style: TextStyle(
            fontSize: fontSize,
            fontWeight: FontWeight.w600,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
