import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Importar para SystemChrome
import 'package:provider/provider.dart';
import 'database/database.dart';
import 'providers/cart_provider.dart';
import 'providers/rental_provider.dart'; // ✅ NUEVO
import 'screens/home_screen.dart';

void main() async {
  // ✅ Asegurar inicialización de Flutter
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ FORZAR ORIENTACIÓN HORIZONTAL
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);

  // ✅ ESCONDER BARRA DE NOTIFICACIONES Y NAVEGACIÓN (MODO INMERSIVO)
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  final database = AppDatabase(); // Instancia única

  runApp(
    MultiProvider(
      providers: [
        // 1. La Base de Datos
        Provider<AppDatabase>.value(value: database),
        
        // 2. El Carrito de Compras
        ChangeNotifierProvider(
          create: (context) => CartProvider(),
        ),

        // 3. Gestión de Rentas
        ChangeNotifierProvider(
          create: (context) => RentalProvider(database),
        ),
      ],
      child: const GamerCafeApp(),
    ),
  );
}

class GamerCafeApp extends StatelessWidget {
  const GamerCafeApp({super.key});

  // --- COLORES EXACTOS DE NEXUS ---
  static const Color nexusBlue = Color(0xFF00187A);
  static const Color nexusYellow = Color(0xFFFFDE00);
  static const Color nexusRed = Color(0xFFE62117);
  static const Color nexusDarkBg = Color(0xFF000F4D);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Nexus POS',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: nexusDarkBg,

        colorScheme: ColorScheme.dark(
          primary: nexusYellow,
          onPrimary: nexusBlue,
          secondary: nexusRed,
          surface: nexusBlue,
          onSurface: Colors.white,
        ),

        textTheme: const TextTheme(
          displayLarge: TextStyle(fontWeight: FontWeight.w900, color: nexusYellow, letterSpacing: 1.0),
          titleMedium: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.white),
        ),

        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: nexusYellow,
            foregroundColor: nexusBlue,
            textStyle: const TextStyle(fontWeight: FontWeight.w900, fontSize: 18),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            elevation: 5,
          ),
        ),
      ),
      home: const HomeScreen(),
    );
  }
}