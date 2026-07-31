import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../providers/cart_provider.dart';
import '../providers/rental_provider.dart';
import '../widgets/product_card.dart';
import '../widgets/cart_sidebar.dart';
import '../widgets/stats_panel.dart';
import 'rentals_screen.dart';
import 'order_monitor_screen.dart';
import 'product_management_screen.dart';
import 'day_preview_screen.dart'; // ✅ Añadido
import '../services/report_service.dart'; // ✅ NUEVO

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  // --- ESTADO DE NAVEGACIÓN DE CAFETERÍA ---
  String? _currentCategory;
  String? _currentSubcategory;

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

  Widget _buildGlobalAlertBanner() {
    return Consumer<RentalProvider>(
      builder: (context, provider, child) {
        if (provider.currentAlert == null) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          color: const Color(0xFFE62117), // Rojo Nexus
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 20),
          child: Row(
            children: [
              const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 28),
              const SizedBox(width: 15),
              Expanded(
                child: Text(
                  provider.currentAlert!,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
                ),
              ),
              TextButton(
                onPressed: () => provider.clearAlert(),
                child: const Text("DESCARTAR", style: TextStyle(color: Colors.white, decoration: TextDecoration.underline)),
              ),
            ],
          ),
        );
      },
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
            child: Column(
              children: [
                _buildGlobalAlertBanner(),
                Expanded(child: _getSelectedScreen(_selectedIndex)),
              ],
            ),
          ),

          const VerticalDivider(thickness: 1, width: 1),

          // 3. CARRITO (Solo en Cafetería)
          if (_selectedIndex == 0)
            const Expanded(
              flex: 1,
              child: CartSidebar(),
            ),
        ],
      ),
    );
  }

  Widget _getSelectedScreen(int index) {
    switch (index) {
      case 0:
        return _buildCafeteriaMenu();
      case 1:
        return const RentalsScreen();
      case 2:
        return const OrderMonitorScreen();
      default:
        return _buildAdminPanel();
    }
  }

  Widget _buildAdminPanel() {
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
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                bool isCompact = constraints.maxWidth < 800;
                if (isCompact) {
                  return ListView(
                    children: [
                      const StatsPanel(),
                      const SizedBox(height: 16),
                      GridView.count(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisCount: constraints.maxWidth < 450 ? 1 : 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.5,
                        children: _getAdminCards(context),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    const Expanded(flex: 4, child: StatsPanel()),
                    const SizedBox(width: 16),
                    Expanded(
                      flex: 6,
                      child: GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.3,
                        children: _getAdminCards(context),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // NAVEGACIÓN JERÁRQUICA DE CAFETERÍA
  // ============================================

  Widget _buildCafeteriaMenu() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_currentCategory != null)
                IconButton(
                  icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFFDE00)),
                  onPressed: () {
                    setState(() {
                      if (_currentSubcategory != null) {
                        _currentSubcategory = null;
                      } else {
                        _currentCategory = null;
                      }
                    });
                  },
                ),
              Text(
                _currentSubcategory?.toUpperCase() ??
                    _currentCategory?.toUpperCase() ??
                    "MENÚ PRINCIPAL",
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(child: _buildMenuContent()),
        ],
      ),
    );
  }

  Widget _buildMenuContent() {
    if (_currentCategory == null) return _buildCategorySelection();
    if (_currentCategory == 'Bebidas' && _currentSubcategory == null) return _buildBebidasSubcategorySelection();
    return _buildProductGrid();
  }

  Widget _buildCategorySelection() {
    final categories = [
      {'name': 'Bebidas', 'icon': Icons.local_drink},
      {'name': 'Comidas', 'icon': Icons.fastfood},
      {'name': 'Combos', 'icon': Icons.card_giftcard},
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.2,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final cat = categories[index];
        return _MenuNavigationButton(
          title: cat['name'] as String,
          icon: cat['icon'] as IconData,
          onTap: () => setState(() => _currentCategory = cat['name'] as String),
        );
      },
    );
  }

  Widget _buildBebidasSubcategorySelection() {
    final subcategories = [
      {'name': 'Bubble Tea', 'icon': Icons.bubble_chart},
      {'name': 'Soda Italiana', 'icon': Icons.local_bar},
      {'name': 'Tisana', 'icon': Icons.emoji_food_beverage},
      {'name': 'Frappé', 'icon': Icons.icecream},
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 20,
        mainAxisSpacing: 20,
        childAspectRatio: 1.5,
      ),
      itemCount: subcategories.length,
      itemBuilder: (context, index) {
        final sub = subcategories[index];
        return _MenuNavigationButton(
          title: sub['name'] as String,
          icon: sub['icon'] as IconData,
          onTap: () => setState(() => _currentSubcategory = sub['name'] as String),
        );
      },
    );
  }

  Widget _buildProductGrid() {
    final db = context.read<AppDatabase>();

    return StreamBuilder<List<Product>>(
      stream: db.productDao.watchActiveProducts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

        final filteredProducts = snapshot.data!.where((p) {
          bool matchCategory = p.category == _currentCategory;
          if (_currentSubcategory != null) {
            return matchCategory && p.subcategory == _currentSubcategory;
          }
          return matchCategory;
        }).toList();

        if (filteredProducts.isEmpty) {
          return const Center(child: Text("No hay productos", style: TextStyle(color: Colors.white54)));
        }

        return LayoutBuilder(
          builder: (context, constraints) {
            bool isComboSelection = _currentCategory == 'Combos';
            int crossAxisCount = isComboSelection ? 2 : 3;

            return GridView.builder(
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: isComboSelection ? 1.3 : 1.0,
              ),
              itemCount: filteredProducts.length,
              itemBuilder: (context, index) {
                final product = filteredProducts[index];
                return ProductCard(
                  name: _getCleanProductName(product.name, product.subcategory),
                  price: product.price,
                  category: product.category,
                  description: product.description,
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
        );
      },
    );
  }

  String _getCleanProductName(String fullName, String? subcategory) {
    if (subcategory == null) return fullName;
    String cleanName = fullName.replaceFirst(subcategory, '').trim();
    if (cleanName.isEmpty) return fullName;
    return cleanName;
  }

  List<Widget> _getAdminCards(BuildContext context) {
    return [
      _AdminActionCard(
        icon: Icons.inventory,
        title: "Productos",
        subtitle: "Gestionar catálogo",
        onTap: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => const ProductManagementScreen()));
        },
      ),
      _AdminActionCard(
        icon: Icons.picture_as_pdf,
        title: "Generar Reporte",
        subtitle: "PDF del día",
        onTap: () async {
          final db = context.read<AppDatabase>();
          final reportService = ReportService(db);
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Generando PDF..."), duration: Duration(seconds: 1)),
          );
          
          try {
            await reportService.generateDailyReport();
          } catch (e) {
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Error al generar PDF: $e"), backgroundColor: Colors.red),
              );
            }
          }
        },
      ),
      _AdminActionCard(
        icon: Icons.history,
        title: "Historial / Avance",
        subtitle: "Ver ventas activas",
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const DayPreviewScreen()),
          );
        },
      ),
    ];
  }

  // Se eliminó _showDaySneakPeak porque ahora usamos DayPreviewScreen
}

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
            Icon(icon, size: 40, color: nexusYellow),
            const SizedBox(height: 8),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(subtitle, textAlign: TextAlign.center, style: const TextStyle(color: Colors.white70, fontSize: 11)),
          ],
        ),
      ),
    );
  }
}

class _MenuNavigationButton extends StatelessWidget {
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  const _MenuNavigationButton({
    required this.title,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        decoration: BoxDecoration(
          color: nexusBlue.withOpacity(0.4),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: nexusYellow, width: 2),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 50, color: nexusYellow),
            const SizedBox(height: 12),
            Text(title.toUpperCase(), textAlign: TextAlign.center, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
          ],
        ),
      ),
    );
  }
}
