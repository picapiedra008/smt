import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class CatalogoPlatosPage extends StatelessWidget {
  const CatalogoPlatosPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Catálogo de Platos'),
        centerTitle: true,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('foods').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('Error al cargar los platos'));
          }

          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final platos = snapshot.data!.docs;

          if (platos.isEmpty) {
            return const Center(child: Text('No hay platos registrados.'));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(10),
            itemCount: platos.length,
            itemBuilder: (context, index) {
              final plato = platos[index];
              final data = plato.data() as Map<String, dynamic>;

              return Card(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(15)),
                margin: const EdgeInsets.symmetric(vertical: 8),
                elevation: 3,
                child: ListTile(
                  contentPadding: const EdgeInsets.all(10),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.network(
                      data['imagen'] ?? '',
                      width: 70,
                      height: 70,
                      fit: BoxFit.cover,
                    ),
                  ),
                  title: Text(
                    data['nombre'] ?? 'Sin nombre',
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 4),
                      Text('${data['restaurantes']} restaurantes'),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Chip(
                            label: Text(data['tipo'] ?? ''),
                            backgroundColor: Colors.orange.shade100,
                            labelStyle: const TextStyle(
                                color: Colors.orange, fontWeight: FontWeight.bold),
                          ),
                          const Spacer(),
                          const Icon(Icons.star, color: Colors.amber, size: 20),
                          Text(
                            data['rating']?.toString() ?? '0.0',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
