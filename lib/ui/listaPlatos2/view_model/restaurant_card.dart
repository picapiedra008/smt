import 'dart:typed_data';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:Sabores_de_mi_Tierra/ui/listaPlatos2/repositories/restaurant_repositorie.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Opcional para futuro

class RestauranteCard extends StatelessWidget {
  final Restaurante restaurante;
  final VoidCallback onTap;
  
  // Cache para imágenes decodificadas
  static final Map<String, Image> _imageCache = {};

  const RestauranteCard({
    super.key,
    required this.restaurante,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final logoBytes = RestaurantRepository.decodeBase64(restaurante.logoBase64);

    return InkWell(
      onTap: onTap,
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
              // Imagen del restaurante - OPTIMIZADA
              _buildOptimizedImageSection(logoBytes),
              const SizedBox(height: 8),
              
              // Nombre del restaurante
              Text(
                restaurante.nombre,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              const SizedBox(height: 4),
              
              // Calificación y horario
              _buildInfoRow(),
              const SizedBox(height: 8),
              
              // Descripción
              Text(
                restaurante.descripcion,
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

  Widget _buildOptimizedImageSection(Uint8List? logoBytes) {
    return Stack(
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
                  child: _buildOptimizedImage(logoBytes),
                )
              : _buildPlaceholderIcon(),
        ),
        
        // Badge destacado
        if (restaurante.destacado)
          Positioned(
            top: 10,
            left: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
        
        // Badge estado (abierto/cerrado)
        Positioned(
          top: 10,
          right: 10,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: restaurante.abierto ? Colors.green : Colors.redAccent,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              restaurante.abierto ? 'Abierto' : 'Cerrado',
              style: const TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),
        ),
      ],
    );
  }

  // SOLUCIÓN 1: Simple con gaplessPlayback
  Widget _buildOptimizedImage(Uint8List logoBytes) {
    return Image.memory(
      logoBytes,
      fit: BoxFit.cover,
      
      // Configuraciones clave para evitar parpadeo
      gaplessPlayback: true, // ← MÁS IMPORTANTE: Evita parpadeo al reciclar widgets
      cacheWidth: 400, // Limitar tamaño máximo para caché
      cacheHeight: 225, // Relación 16:9 (400x225)
      
      // Usar filtro de alta calidad pero rápido
      filterQuality: FilterQuality.medium, // Equilibrio entre calidad y rendimiento
      
      errorBuilder: (context, error, stackTrace) {
        return _buildPlaceholderIcon();
      },
      
      // Asegurar que se mantenga en caché
      isAntiAlias: true,
      excludeFromSemantics: true, // Opcional: mejora rendimiento
    );
  }

  // SOLUCIÓN 2: Con FutureBuilder y cache manual
  Widget _buildImageWithCache(Uint8List logoBytes) {
    final cacheKey = '${restaurante.id}_${logoBytes.length}';
    
    if (_imageCache.containsKey(cacheKey)) {
      return _imageCache[cacheKey]!;
    }
    
    return FutureBuilder<Image>(
      future: _decodeAndCacheImage(logoBytes, cacheKey),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data!;
        } else if (snapshot.hasError) {
          return _buildPlaceholderIcon();
        } else {
          return _buildLoadingPlaceholder();
        }
      },
    );
  }

  Future<Image> _decodeAndCacheImage(Uint8List bytes, String cacheKey) async {
    // Decodificar la imagen
    final codec = await instantiateImageCodec(bytes);
    final frame = await codec.getNextFrame();
    
    // Crear widget de imagen optimizado
    final image = Image(
      image: ResizeImage(
        MemoryImage(bytes),
        width: 400,
        height: 225,
        allowUpscaling: false,
      ),
      fit: BoxFit.cover,
      gaplessPlayback: true,
      filterQuality: FilterQuality.medium,
      isAntiAlias: true,
    );
    
    // Guardar en caché
    _imageCache[cacheKey] = image;
    
    return image;
  }

  Widget _buildLoadingPlaceholder() {
    return Center(
      child: Container(
        width: double.infinity,
        height: 160,
        color: Colors.grey[200],
        child: const Center(
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  // SOLUCIÓN 3: Widget de imagen precargado (más eficiente)
  Widget _buildPreloadedImage(Uint8List logoBytes) {
    return PreloadedImageWidget(
      bytes: logoBytes,
      placeholder: _buildLoadingPlaceholder(),
      errorWidget: _buildPlaceholderIcon(),
    );
  }

  Widget _buildInfoRow() {
    return Row(
      children: [
        // Calificación promedio
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.star,
              color: restaurante.averageRate > 0 ? Colors.amber : Colors.grey,
              size: 18,
            ),
            const SizedBox(width: 4),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  restaurante.averageRate > 0 
                      ? restaurante.averageRate.toStringAsFixed(1) 
                      : "-",
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
        const SizedBox(width: 16),
        
        // Horario
        const Icon(Icons.access_time, color: Colors.grey, size: 18),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            restaurante.horario,
            style: const TextStyle(color: Colors.grey),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderIcon() {
    return Center(
      child: Icon(
        Icons.restaurant,
        size: 60,
        color: Colors.grey[400],
      ),
    );
  }
}

// SOLUCIÓN 4: Widget personalizado para precarga
class PreloadedImageWidget extends StatefulWidget {
  final Uint8List bytes;
  final Widget placeholder;
  final Widget errorWidget;

  const PreloadedImageWidget({
    super.key,
    required this.bytes,
    required this.placeholder,
    required this.errorWidget,
  });

  @override
  State<PreloadedImageWidget> createState() => _PreloadedImageWidgetState();
}

class _PreloadedImageWidgetState extends State<PreloadedImageWidget> {
  late Future<Image> _imageFuture;

  @override
  void initState() {
    super.initState();
    _imageFuture = _loadImage();
  }

  Future<Image> _loadImage() async {
    return Image.memory(
      widget.bytes,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      cacheWidth: 400,
      cacheHeight: 225,
      filterQuality: FilterQuality.medium,
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Image>(
      future: _imageFuture,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return snapshot.data!;
        } else if (snapshot.hasError) {
          return widget.errorWidget;
        } else {
          return widget.placeholder;
        }
      },
    );
  }
}