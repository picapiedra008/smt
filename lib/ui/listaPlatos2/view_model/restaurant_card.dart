// lib/ui/restaurantes/widgets/restaurante_card.dart (actualizado)
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:Sabores_de_mi_Tierra/ui/listaPlatos2/repositories/restaurant_repositorie.dart';

class RestauranteCard extends StatelessWidget {
  final Restaurante restaurante;
  final VoidCallback onTap;

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
              // Imagen del restaurante
              _buildImageSection(logoBytes),
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

  Widget _buildImageSection(Uint8List? logoBytes) {
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
    return const Center(
      child: Icon(
        Icons.restaurant,
        size: 60,
        color: Colors.grey,
      ),
    );
  }
}