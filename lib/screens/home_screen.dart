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
import 'day_preview_screen.dart';
import 'expenses_screen.dart'; // ✅ Añadido
import '../widgets/drink_customization_dialog.dart';
import '../widgets/food_customization_dialog.dart'; // ✅ Añadido
import '../widgets/combo_drink_dialog.dart'; // ✅ Añadido
import '../services/report_service.dart';

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
          LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: IntrinsicHeight(
                    child: NavigationRail(
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
                          icon: Icon(Icons.money_off),
                          label: Text('Gastos'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.settings),
                          label: Text('Admin'),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }
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
      case 3:
        return const ExpensesScreen();
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
    if (_currentCategory == 'Comidas' && _currentSubcategory == null) return _buildComidasSubcategorySelection();
    return _buildProductGrid();
  }

  Widget _buildCategorySelection() {
// ... (mismo código)
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
      {'name': 'Bubble Tea Base Leche', 'icon': Icons.bubble_chart},
      {'name': 'Bubble Tea Base Agua', 'icon': Icons.bubble_chart_outlined},
      {'name': 'Soda Italiana', 'icon': Icons.local_bar},
      {'name': 'Tisana', 'icon': Icons.emoji_food_beverage},
      {'name': 'Chamoyada', 'icon': Icons.icecream},
      {'name': 'Otros', 'icon': Icons.more_horiz},
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
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

  Widget _buildComidasSubcategorySelection() {
    final subcategories = [
      {'name': 'Nexuleta', 'icon': Icons.flatware},
      {'name': 'Nachos', 'icon': Icons.lunch_dining},
      {'name': 'Mini Hot Cakes', 'icon': Icons.cookie},
      {'name': 'Palomitas', 'icon': Icons.animation},
      {'name': 'Maruchan', 'icon': Icons.soup_kitchen}, // ✅ Añadido
      {'name': 'Otros Snacks', 'icon': Icons.more_horiz},
    ];

    return GridView.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
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

  // ========================================
  // LÓGICA PARA RESOLVER COMBOS DINÁMICOS
  // ========================================
  Future<void> _handleComboSelection(BuildContext context, Product combo) async {
    final db = context.read<AppDatabase>();
    final cart = context.read<CartProvider>();
    
    final comboItems = await db.productDao.getPackageItems(combo.id);
    
    if (comboItems.isEmpty) {
      cart.addItem(combo.name, combo.price, category: 'Combos');
      _showAddedToCartFeedback(context, combo.name);
      return;
    }

    List<String> selections = [];
    List<Map<String, dynamic>> structuredComponents = []; // ✅ Para el monitor
    double comboTotalPrice = combo.price; 
    bool cancelled = false;

    for (var item in comboItems) {
      if (cancelled) break;

      final int qty = item['quantity'] as int;
      for (int i = 0; i < qty; i++) {
        final String category = item['category'] as String;
        final bool isPlaceholder = item['isPlaceholder'] == true;

        if (category == 'Bebidas') {
          String drinkName = "";
          String? subcategory;
          double drinkBasePrice = 0;

          if (isPlaceholder) {
            final allProducts = await db.productDao.getActiveProducts();
            final drinks = allProducts.where((p) => p.category == 'Bebidas').toList();
            
            if (!context.mounted) return;
            final selected = await showDialog<String>(
              context: context,
              builder: (context) => ComboDrinkDialog(
                eligibleDrinks: drinks,
                comboName: "${combo.name} (Bebida ${i+1}/$qty)",
              ),
            );
            if (selected == null) { cancelled = true; break; }
            drinkName = selected;
            final p = drinks.firstWhere((p) => p.name == selected);
            subcategory = p.subcategory;
            drinkBasePrice = p.price;
          } else {
            drinkName = item['name'];
            final p = await db.productDao.getProductById(item['productId']);
            subcategory = p?.subcategory;
            drinkBasePrice = p?.price ?? 0;
          }

          if (!context.mounted) return;
          final customResult = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => DrinkCustomizationDialog(
              productName: drinkName,
              basePrice: drinkBasePrice,
              subcategory: subcategory ?? 'Bebida',
            ),
          );

          if (customResult == null) { cancelled = true; break; }
          
          final double extra = (customResult['finalPrice'] as double) - drinkBasePrice;
          if (extra > 0) comboTotalPrice += extra;

          final List<String> modsList = List<String>.from(customResult['modifiers'] ?? []);
          final String modsText = modsList.join(', ');
          
          selections.add("$drinkName ${modsText.isNotEmpty ? '($modsText)' : '(Original)'}");
          
          // ✅ Guardar componente estructurado
          structuredComponents.add({
            'name': drinkName,
            'category': 'Bebidas',
            'modifiers': modsText,
          });

        } else if (category == 'Comidas') {
          String foodName = item['name'];
          String? subcategory;
          double foodBasePrice = 0;

          if (!isPlaceholder) {
            final p = await db.productDao.getProductById(item['productId']);
            subcategory = p?.subcategory;
            foodBasePrice = p?.price ?? 0;
          }

          if (!context.mounted) return;
          final customResult = await showDialog<Map<String, dynamic>>(
            context: context,
            builder: (context) => FoodCustomizationDialog(
              productName: foodName,
              basePrice: foodBasePrice,
              subcategory: subcategory ?? 'Comida',
            ),
          );

          if (customResult == null) { cancelled = true; break; }
          
          final double extra = (customResult['finalPrice'] as double) - foodBasePrice;
          if (extra > 0) comboTotalPrice += extra;

          final List<String> modsList = List<String>.from(customResult['modifiers'] ?? []);
          final String modsText = modsList.join(', ');
          
          selections.add("$foodName ${modsText.isNotEmpty ? '($modsText)' : '(Incluido)'}");

          // ✅ Guardar componente estructurado
          structuredComponents.add({
            'name': foodName,
            'category': 'Comidas',
            'modifiers': modsText,
          });

        } else if (category == 'Rentas') {
          if (!context.mounted) return;
          final selectedConsole = await _showConsolePicker(context, "${combo.name} (${item['name']})");
          if (selectedConsole == null) { cancelled = true; break; }

          if (!context.mounted) return;
          int extraControllers = 0;
          final bool? confirmed = await showDialog<bool>(
            context: context,
            builder: (ctx) => StatefulBuilder(
              builder: (ctx, setDS) => AlertDialog(
                backgroundColor: const Color(0xFF000F4D),
                title: Text("Controles: $selectedConsole"),
                content: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text("¿Controles adicionales?", style: TextStyle(color: Colors.white70)),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        IconButton(icon: const Icon(Icons.remove_circle, color: Colors.red), onPressed: extraControllers > 0 ? () => setDS(() => extraControllers--) : null),
                        Text("$extraControllers", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                        IconButton(icon: const Icon(Icons.add_circle, color: Colors.green), onPressed: extraControllers < 3 ? () => setDS(() => extraControllers++) : null),
                      ],
                    ),
                    Text("(+\$${extraControllers * 15} MXN)", style: const TextStyle(color: Color(0xFFFFDE00), fontWeight: FontWeight.bold)),
                  ],
                ),
                actions: [
                  TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text("CANCELAR")),
                  ElevatedButton(onPressed: () => Navigator.pop(ctx, true), child: const Text("ACEPTAR")),
                ],
              ),
            ),
          );

          if (confirmed != true) { cancelled = true; break; }
          
          if (extraControllers > 0) {
            comboTotalPrice += (extraControllers * 15.0);
          }

          selections.add("Consola: $selectedConsole ${extraControllers > 0 ? '(+$extraControllers controles)' : ''}");
          
          // ✅ Guardar componente estructurado (para el timer de renta)
          structuredComponents.add({
            'name': item['name'],
            'category': 'Rentas',
            'consoleName': selectedConsole,
            'extraControllers': extraControllers,
            'minutes': item['name'].toString().contains('Hora') ? 60 : 30, // Detección simple por nombre
          });
          
        } else {
          selections.add("${item['name']} (x${item['quantity']})");
        }
      }
    }

    if (!cancelled && context.mounted) {
      cart.addItem(
        combo.name, 
        comboTotalPrice, 
        category: 'Combos',
        modifiers: selections,
        comboComponents: structuredComponents, // ✅ PASAR COMPONENTES REALES
      );
      _showAddedToCartFeedback(context, combo.name);
    }
  }

  Future<String?> _showConsolePicker(BuildContext context, String title) async {
    // Lista de consolas (podría venir de la DB, pero usamos la lista estándar por ahora)
    final consoles = ['Switch 1', 'Switch 2', 'Xbox A', 'Xbox B', 'Xbox C', 'Xbox D', 'PS5'];
    
    return showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF000F4D),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 18)),
        content: SizedBox(
          width: double.maxFinite,
          child: ListView(
            shrinkWrap: true,
            children: consoles.map((c) => ListTile(
              title: Text(c, style: const TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.videogame_asset, color: Color(0xFFFFDE00)),
              onTap: () => Navigator.pop(ctx, c),
            )).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildProductGrid() {
    final db = context.read<AppDatabase>();

    return StreamBuilder<List<Product>>(
      stream: db.productDao.watchActiveProducts(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

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
                  onTap: () async {
                    final cart = context.read<CartProvider>();

                    // Solo abrir personalización si es Bebida y NO es de la subcategoría 'Otros'
                    if (product.category == 'Bebidas' && product.subcategory != 'Otros') {
                      // Abrir diálogo de personalización de bebidas
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (context) => DrinkCustomizationDialog(
                          productName: product.name,
                          basePrice: product.price,
                          subcategory: product.subcategory ?? 'Bebida',
                        ),
                      );

                      if (result != null) {
                        cart.addItem(
                          product.name,
                          result['finalPrice'] as double,
                          category: product.category,
                          modifiers: List<String>.from(result['modifiers'] ?? []),
                        );
                        if (context.mounted) {
                          _showAddedToCartFeedback(context, product.name);
                        }
                      }
                    } else if (product.category == 'Comidas') {
                      // ✅ NUEVO: Abrir diálogo de personalización de comidas
                      final result = await showDialog<Map<String, dynamic>>(
                        context: context,
                        builder: (context) => FoodCustomizationDialog(
                          productName: product.name,
                          basePrice: product.price,
                          subcategory: product.subcategory ?? 'Comida',
                        ),
                      );

                      if (result != null) {
                        cart.addItem(
                          product.name,
                          result['finalPrice'] as double,
                          category: product.category,
                          modifiers: List<String>.from(result['modifiers'] ?? []),
                        );
                        if (context.mounted) {
                          _showAddedToCartFeedback(context, product.name);
                        }
                      }
                    } else if (product.category == 'Combos') {
                      // ✅ NUEVO: Lógica de Constructor de Combos Dinámicos
                      await _handleComboSelection(context, product);
                    } else {
                      // Agregar directamente para 'Otros'
                      cart.addItem(
                        product.name, 
                        product.price,
                        category: product.category, // ✅ Pasar categoría real
                      );
                      _showAddedToCartFeedback(context, product.name);
                    }
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
    String cleanName = fullName;

    // 1. Eliminar prefijos comunes redundantes de forma agresiva
    final prefixesToRemove = [
      'Bubble Tea ',
      'Soda Italiana ',
      'Tisana ',
      'Chamoyada de ',
    ];

    for (var prefix in prefixesToRemove) {
      if (cleanName.startsWith(prefix)) {
        cleanName = cleanName.replaceFirst(prefix, '');
      }
    }

    // 2. Si todavía queda el nombre de la subcategoría al inicio, quitarlo
    if (subcategory != null && cleanName.startsWith(subcategory)) {
      cleanName = cleanName.replaceFirst(subcategory, '').trim();
    }

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
