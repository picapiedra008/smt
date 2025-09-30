import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'widgets/restaurant_form_page.dart';


void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  bool firebaseConnected = false;
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    firebaseConnected = true;
  } catch (e) {
    // If initialization fails we set connected=false and allow the app to run
    firebaseConnected = false;
  }
  runApp(MyApp(firebaseConnected: firebaseConnected));
}

class MyApp extends StatelessWidget {
  final bool firebaseConnected;

  const MyApp({super.key, required this.firebaseConnected});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        // Color primario basado en #FEF3F3
        primaryColor: const Color(0xFFFEF3F3),
        primaryColorLight: const Color(0xFFFFF7F7),
        primaryColorDark: const Color(0xFFF5E0E0),
        
        // ColorScheme para una paleta más completa
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFFEF3F3),
          primary: const Color(0xFFFEF3F3),
          secondary: const Color(0xFF4A5568), // Un gris azulado como secundario
          background: const Color(0xFFFFFFFF),
          surface: const Color(0xFFFEF3F3),
        ),
        
        // Scaffold background
        scaffoldBackgroundColor: const Color(0xFFFEF3F3),
        
        // AppBar theme
        appBarTheme: AppBarTheme(
          backgroundColor: const Color(0xFFFEF3F3),
          foregroundColor: Colors.black87,
          elevation: 0,
          iconTheme: IconThemeData(color: Colors.black87),
        ),
        
        // Floating Action Button
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: const Color(0xFF4A5568),
          foregroundColor: Colors.white,
        ),
        
        // Text themes
        textTheme: TextTheme(
          displayLarge: TextStyle(color: Colors.black87),
          displayMedium: TextStyle(color: Colors.black87),
          displaySmall: TextStyle(color: Colors.black87),
          bodyLarge: TextStyle(color: Colors.black87),
          bodyMedium: TextStyle(color: Colors.black87),
          titleMedium: TextStyle(color: Colors.black87),
          titleSmall: TextStyle(color: Colors.black87),
        ),
        
        // Input decoration theme
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
        ),
      ),
      home: MyHomePage(title: 'Flutter Demo Home Page', firebaseConnected: firebaseConnected),
    );
  }
}

class MyHomePage extends StatefulWidget {
  final bool firebaseConnected;

  const MyHomePage({super.key, required this.title, required this.firebaseConnected});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          title: Text(widget.title),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Inicio'),
              Tab(text: 'Mis restaurantes'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // show connection status based on Firebase initialization
            Center(child: Text(widget.firebaseConnected ? 'conectado' : 'desconectado')),
            const RestaurantFormPage(),
          ],
        ),
      ),
    );
  }
}
