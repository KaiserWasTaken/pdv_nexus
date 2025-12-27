import 'package:flutter/material.dart';
import 'package:provider/provider.dart'; // Importante para leer el carrito
import '../providers/cart_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_sidebar.dart'; // Importamos el widget nuevo

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Row(
        children: [
          // 1. MENÚ LATERAL (IZQUIERDA)
          NavigationRail(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (int index) {
              setState(() => _selectedIndex = index);
            },
            labelType: NavigationRailLabelType.all,
            // Estilo Nexus (Amarillo/Azul) ya definido en main.dart
            destinations: const [
              NavigationRailDestination(icon: Icon(Icons.coffee), label: Text('Cafetería')),
              NavigationRailDestination(icon: Icon(Icons.videogame_asset), label: Text('Rentas')),
              NavigationRailDestination(icon: Icon(Icons.list_alt), label: Text('Monitor')),
              NavigationRailDestination(icon: Icon(Icons.settings), label: Text('Admin')),
            ],
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // 2. CONTENIDO CENTRAL (GRID DE PRODUCTOS)
          Expanded(
            flex: 3, // Ocupa la mayor parte de la pantalla
            child: _getSelectedScreen(_selectedIndex),
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // 3. CARRITO DE COMPRAS (DERECHA) - ¡NUEVO!
          // Solo lo mostramos si estamos en la pestaña de Cafetería (índice 0)
          if (_selectedIndex == 0)
            const Expanded(
              flex: 1, // Ocupa menos espacio (1/4 aprox)
              child: CartSidebar(),
            ),
        ],
      ),
    );
  }

  Widget _getSelectedScreen(int index) {
    switch (index) {
      case 0: // CAFETERÍA
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "MENÚ PRINCIPAL",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
              ),
              const SizedBox(height: 20),
              Expanded(
                child: GridView.count(
                  crossAxisCount: 3,
                  childAspectRatio: 0.70,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  children: [
                    // --- AQUÍ CONECTAMOS LOS BOTONES AL CARRITO ---
                    ProductCard(
                      name: "BUBBLE TEA CONEJOS",
                      price: 89,
                      category: "Bebida",
                      onTap: () {
                        // ¡AGREGAR AL CARRITO!
                        context.read<CartProvider>().addItem("Bubble Tea Conejos", 89);
                      },
                    ),
                    ProductCard(
                      name: "NEXULETA CLÁSICA",
                      price: 45,
                      category: "Snack",
                      onTap: () {
                        context.read<CartProvider>().addItem("Nexuleta Clásica", 45);
                      },
                    ),
                    ProductCard(
                      name: "COMBO GAMER",
                      price: 120,
                      category: "Snack",
                      onTap: () {
                        context.read<CartProvider>().addItem("Combo Gamer", 120);
                      },
                    ),
                    ProductCard(
                      name: "FRAPPÉ OREO",
                      price: 65,
                      category: "Bebida",
                      onTap: () {
                        context.read<CartProvider>().addItem("Frappé Oreo", 65);
                      },
                    ),
                    ProductCard(
                      name: "PIZZA INDIVIDUAL",
                      price: 50,
                      category: "Snack",
                      onTap: () {
                        context.read<CartProvider>().addItem("Pizza Individual", 50);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      case 1:
        return const Center(child: Text("Rentas Xbox/PlayStation"));
      case 2:
        return const Center(child: Text("Monitor de Pedidos"));
      default:
        return const Center(child: Text("Configuración"));
    }
  }
}