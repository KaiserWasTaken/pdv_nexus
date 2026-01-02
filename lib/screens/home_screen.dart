import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../providers/cart_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_sidebar.dart';
import '../widgets/stats_panel.dart';
import 'order_monitor_screen.dart';
import 'product_management_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // ============================================
  // MÉTODO PARA FEEDBACK VISUAL
  // ============================================
  void _showAddedToCartFeedback(BuildContext context, String productName) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(
              '✓ $productName',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
        backgroundColor: const Color(0xFF00187A).withOpacity(0.95),
        duration: const Duration(milliseconds: 600),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        margin: const EdgeInsets.only(
          bottom: 80,
          left: 20,
          right: 20,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        dismissDirection: DismissDirection.horizontal,
      ),
    );
  }

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
            destinations: const [
              NavigationRailDestination(
                icon: Icon(Icons.coffee),
                label: Text('Cafetería'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.videogame_asset),
                label: Text('Rentas'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.list_alt),
                label: Text('Monitor'),
              ),
              NavigationRailDestination(
                icon: Icon(Icons.settings),
                label: Text('Admin'),
              ),
            ],
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // 2. CONTENIDO CENTRAL
          Expanded(
            flex: 3,
            child: _getSelectedScreen(_selectedIndex),
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // 3. CARRITO (Solo en Cafetería)
          if (_selectedIndex == 0)
            Expanded(
              flex: 1,
              child: const CartSidebar(),
            ),
        ],
      ),
    );
  }

  Widget _getSelectedScreen(int index) {
    switch (index) {
    // ==========================================
    // CASO 0: CAFETERÍA
    // ==========================================
      case 0:
        final db = context.read<AppDatabase>();

        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "MENÚ PRINCIPAL",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 20),

              // PRODUCTOS DINÁMICOS DESDE LA BD
              Expanded(
                child: StreamBuilder<List<Product>>(
                  stream: db.productDao.watchActiveProducts(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFFDE00),
                        ),
                      );
                    }

                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Error: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                        ),
                      );
                    }

                    final products = snapshot.data ?? [];

                    if (products.isEmpty) {
                      return const Center(
                        child: Text(
                          'No hay productos disponibles. Ve a Admin > Productos para agregar.',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                          textAlign: TextAlign.center,
                        ),
                      );
                    }

                    return GridView.builder(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 0.9,
                      ),
                      itemCount: products.length,
                      itemBuilder: (context, index) {
                        final product = products[index];
                        return ProductCard(
                          name: product.name,
                          price: product.price,
                          category: product.category,
                          imagePath: product.imagePath,
                          onTap: () {
                            final cart = context.read<CartProvider>();
                            cart.addItem(product.name, product.price);
                            _showAddedToCartFeedback(context, product.name);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );

    // ==========================================
    // CASO 1: RENTAS
    // ==========================================
      case 1:
        return const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.videogame_asset, size: 80, color: Colors.white54),
              SizedBox(height: 20),
              Text(
                "Rentas Xbox/PlayStation",
                style: TextStyle(fontSize: 24, color: Colors.white70),
              ),
              SizedBox(height: 10),
              Text(
                "Próximamente...",
                style: TextStyle(color: Colors.white38),
              ),
            ],
          ),
        );

    // ==========================================
    // CASO 2: MONITOR DE PEDIDOS
    // ==========================================
      case 2:
        return const OrderMonitorScreen();

    // ==========================================
    // CASO 3: ADMIN - REDISEÑADO PARA HORIZONTAL
    // ==========================================
      default:
        return Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "PANEL DE ADMINISTRACIÓN",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 16),

              // ✅ DISEÑO HORIZONTAL OPTIMIZADO
              Expanded(
                child: Row(
                  children: [
                    // ESTADÍSTICAS A LA IZQUIERDA (40%)
                    Expanded(
                      flex: 4,
                      child: const StatsPanel(),
                    ),

                    const SizedBox(width: 16),

                    // BOTONES DE ACCIÓN A LA DERECHA (60%)
                    Expanded(
                      flex: 6,
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3, // Ajustado para horizontal
                        children: [
                          _AdminActionCard(
                            icon: Icons.inventory,
                            title: "Productos",
                            subtitle: "Gestionar catálogo",
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const ProductManagementScreen(),
                                ),
                              );
                            },
                          ),
                          _AdminActionCard(
                            icon: Icons.picture_as_pdf,
                            title: "Generar Reporte",
                            subtitle: "PDF del día",
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Próximamente...")),
                              );
                            },
                          ),
                          _AdminActionCard(
                            icon: Icons.cloud_upload,
                            title: "Sincronizar",
                            subtitle: "Subir a Drive",
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Próximamente...")),
                              );
                            },
                          ),
                          _AdminActionCard(
                            icon: Icons.history,
                            title: "Historial",
                            subtitle: "Ver ventas pasadas",
                            onTap: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("Próximamente...")),
                              );
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
    }
  }
}

// ============================================
// WIDGET AUXILIAR: TARJETA DE ACCIÓN ADMIN
// ============================================
class _AdminActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  const _AdminActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: nexusBlue.withOpacity(0.7),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: nexusYellow, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 40, color: nexusYellow), // Reducido de 48 a 40
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16, // Reducido de 18 a 16
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white70,
                fontSize: 11, // Reducido de 12 a 11
              ),
            ),
          ],
        ),
      ),
    );
  }
}