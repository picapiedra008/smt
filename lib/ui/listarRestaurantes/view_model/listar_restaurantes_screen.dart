import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class SaboresApp extends StatelessWidget {
  const SaboresApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sabores de Cochabamba',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        scaffoldBackgroundColor: const Color(0xFFF8ECE3),
        textTheme: GoogleFonts.comfortaaTextTheme(),
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFFFF6A00)),
        useMaterial3: true,
      ),
      home: const RestaurantesPage(),
    );
  }
}

class Restaurante {
  final String nombre;
  final String descripcion;
  final String direccion;
  final String telefono;
  final String horario;
  final double calificacion;
  final String rangoPrecio;
  final List<String> servicios;
  final String imagen;
  final bool abierto;
  final bool destacado;

  Restaurante({
    required this.nombre,
    required this.descripcion,
    required this.direccion,
    required this.telefono,
    required this.horario,
    required this.calificacion,
    required this.rangoPrecio,
    required this.servicios,
    required this.imagen,
    this.abierto = true,
    this.destacado = false,
  });
}

class RestaurantesPage extends StatefulWidget {
  const RestaurantesPage({super.key});

  @override
  State<RestaurantesPage> createState() => _RestaurantesPageState();
}

class _RestaurantesPageState extends State<RestaurantesPage> {
  final TextEditingController searchController = TextEditingController();

  final List<Restaurante> restaurantes = [
    Restaurante(
      nombre: "La Casa de las Salteñas",
      descripcion:
          "Especialistas en salteñas tradicionales cochabambinas desde 1985. Recetas familiares...",
      direccion: "Av. América S/N, Zona Central, Cochabamba",
      telefono: "+591 4-4234567",
      horario: "06:00 - 12:00",
      calificacion: 4.8,
      rangoPrecio: "\$ - \$\$",
      servicios: ["Delivery", "Parqueo", "Wi-Fi"],
      imagen: "assets/img/restaurante1.jpeg",
      abierto: true,
      destacado: true,
    ),
    Restaurante(
      nombre: "Sabor Andino",
      descripcion:
          "Platos típicos bolivianos preparados con ingredientes locales y frescos.",
      direccion: "Calle España #1025, Cochabamba",
      telefono: "+591 4-4256789",
      horario: "11:00 - 23:00",
      calificacion: 4.5,
      rangoPrecio: "\$ - \$\$",
      servicios: ["Parqueo", "Wi-Fi"],
      imagen: "assets/img/restaurante2.jpg",
      abierto: true,
      destacado: false,
    ),
    Restaurante(
      nombre: "Rincón Gourmet",
      descripcion:
          "Experiencia gastronómica moderna con fusión de sabores internacionales.",
      direccion: "Av. Blanco Galindo km 5, Cochabamba",
      telefono: "+591 4-4789632",
      horario: "12:00 - 23:00",
      calificacion: 4.9,
      rangoPrecio: "\$\$ - \$\$\$",
      servicios: ["Wi-Fi", "Delivery"],
      imagen: "assets/img/restaurante3.jpeg",
      abierto: false,
      destacado: true,
    ),
  ];

  String searchText = '';

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
      appBar: AppBar(title: const Text("Restaurantes"), centerTitle: true),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Encuentra el lugar perfecto para disfrutar",
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
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                        color: Colors.transparent,
                        width: 0,
                      ),
                    ),
                  ),
                  onChanged: (val) => setState(() => searchText = val),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () {},
                        icon: const Icon(Icons.star, color: Color(0xFFFF6A00)),
                        label: const Text("Mejor calificados"),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.black87,
                          side: const BorderSide(color: Color(0xFFFF6A00)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    OutlinedButton(
                      onPressed: () {},
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black87,
                        side: const BorderSide(color: Color(0xFFFF6A00)),
                      ),
                      child: const Text("Filtros"),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              itemCount: filteredList.length,
              itemBuilder: (context, index) {
                final r = filteredList[index];
                return _buildRestauranteCard(r);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: 2,
        selectedItemColor: const Color(0xFFFF6A00),
        unselectedItemColor: Colors.grey,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            label: "Inicio",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_book_outlined),
            label: "Catálogo",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu),
            label: "Restaurantes",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map_outlined),
            label: "Mapa",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            label: "Perfil",
          ),
        ],
      ),
    );
  }

  Widget _buildRestauranteCard(Restaurante r) {
    return Card(
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
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.asset(
                    r.imagen,
                    height: 160,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
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
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.star, color: Colors.amber, size: 18),
                const SizedBox(width: 4),
                Text("${r.calificacion}"),
                const SizedBox(width: 6),
                Text(r.rangoPrecio, style: const TextStyle(color: Colors.grey)),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              r.descripcion,
              style: const TextStyle(color: Colors.black54),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(
                  Icons.location_on_outlined,
                  color: Colors.grey,
                  size: 18,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    r.direccion,
                    style: const TextStyle(color: Colors.black54),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.phone, color: Colors.grey, size: 18),
                const SizedBox(width: 6),
                Text(r.telefono, style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.access_time, color: Colors.grey, size: 18),
                const SizedBox(width: 6),
                Text(r.horario, style: const TextStyle(color: Colors.black54)),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              "Servicios disponibles:",
              style: TextStyle(fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              children: r.servicios
                  .map(
                    (s) => Chip(
                      backgroundColor: const Color(0xFFF1F1F1),
                      label: Text(
                        s,
                        style: const TextStyle(
                          color: Colors.black87,
                          fontSize: 13,
                        ),
                      ),
                      avatar: Icon(
                        s == "Delivery"
                            ? FontAwesomeIcons.motorcycle
                            : s == "Parqueo"
                            ? Icons.local_parking
                            : Icons.wifi,
                        size: 14,
                        color: const Color(0xFFFF6A00),
                      ),
                    ),
                  )
                  .toList(),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFFF6A00),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text("Ver Menú"),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.map_outlined, size: 18),
                    label: const Text("Ubicación"),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Color(0xFFFF6A00)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
