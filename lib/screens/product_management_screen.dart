import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import 'add_product_screen.dart';

class ProductManagementScreen extends StatelessWidget {
  const ProductManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);

    final db = context.read<AppDatabase>();

    return Scaffold(
      backgroundColor: const Color(0xFF000F4D),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ENCABEZADO
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const SizedBox(width: 10),
                    const Text(
                      "GESTIÓN DE PRODUCTOS",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),

                // BOTÓN AGREGAR
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: nexusYellow,
                    foregroundColor: nexusBlue,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const AddProductScreen(),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text(
                    "NUEVO PRODUCTO",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // ESTADÍSTICAS RÁPIDAS
            FutureBuilder<Map<String, dynamic>>(
              future: db.productDao.getProductStats(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const SizedBox();

                final stats = snapshot.data!;
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: nexusBlue.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: nexusYellow, width: 1.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _StatChip(
                        icon: Icons.inventory_2,
                        label: "Total",
                        value: "${stats['total']}",
                        color: Colors.white,
                      ),
                      _StatChip(
                        icon: Icons.local_drink,
                        label: "Bebidas",
                        value: "${stats['bebidas']}",
                        color: Colors.blue,
                      ),
                      _StatChip(
                        icon: Icons.fastfood,
                        label: "Comidas",
                        value: "${stats['comidas']}",
                        color: Colors.orange,
                      ),
                      _StatChip(
                        icon: Icons.card_giftcard,
                        label: "Paquetes",
                        value: "${stats['paquetes']}",
                        color: Colors.purple,
                      ),
                    ],
                  ),
                );
              },
            ),

            const SizedBox(height: 20),

            // LISTA DE PRODUCTOS
            Expanded(
              child: StreamBuilder<List<Product>>(
                stream: db.productDao.watchActiveProducts(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(color: nexusYellow),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        "Error: ${snapshot.error}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    );
                  }

                  final products = snapshot.data ?? [];

                  if (products.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.inventory_2_outlined,
                            size: 80,
                            color: Colors.white.withOpacity(0.3),
                          ),
                          const SizedBox(height: 20),
                          const Text(
                            "No hay productos",
                            style: TextStyle(
                              color: Colors.white54,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  // Agrupar por categoría
                  final grouped = <String, List<Product>>{};
                  for (var product in products) {
                    grouped.putIfAbsent(product.category, () => []).add(product);
                  }

                  return ListView(
                    children: grouped.entries.map((entry) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // TÍTULO DE CATEGORÍA
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            child: Text(
                              entry.key.toUpperCase(),
                              style: const TextStyle(
                                color: nexusYellow,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),

                          // PRODUCTOS DE LA CATEGORÍA
                          ...entry.value.map((product) {
                            return _ProductCard(
                              product: product,
                              onEdit: () {
                                // TODO: Implementar edición
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Edición próximamente..."),
                                  ),
                                );
                              },
                              onDelete: () async {
                                final confirm = await showDialog<bool>(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    backgroundColor: nexusBlue,
                                    title: const Text(
                                      "Confirmar",
                                      style: TextStyle(color: Colors.white),
                                    ),
                                    content: Text(
                                      "¿Desactivar '${product.name}'?",
                                      style: const TextStyle(color: Colors.white70),
                                    ),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.pop(ctx, false),
                                        child: const Text("Cancelar"),
                                      ),
                                      ElevatedButton(
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.red,
                                        ),
                                        onPressed: () => Navigator.pop(ctx, true),
                                        child: const Text("Desactivar"),
                                      ),
                                    ],
                                  ),
                                );

                                if (confirm == true) {
                                  await db.productDao.deleteProduct(product.id);
                                }
                              },
                            );
                          }),

                          const SizedBox(height: 10),
                        ],
                      );
                    }).toList(),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================
// WIDGET: CHIP DE ESTADÍSTICA
// ============================================
class _StatChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatChip({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: color, size: 28),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

// ============================================
// WIDGET: TARJETA DE PRODUCTO
// ============================================
class _ProductCard extends StatelessWidget {
  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ProductCard({
    required this.product,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);

    return Card(
      color: nexusBlue.withOpacity(0.5),
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: product.imagePath != null
              ? ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              // TODO: Implementar carga de imagen
              File(product.imagePath!),
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                product.category == 'Bebida'
                    ? Icons.local_drink
                    : Icons.fastfood,
                color: Colors.white70,
              ),
            ),
          )
              : Icon(
            product.category == 'Bebida'
                ? Icons.local_drink
                : Icons.fastfood,
            color: Colors.white70,
          ),
        ),
        title: Text(
          product.name,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (product.subcategory != null)
              Text(
                product.subcategory!,
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
            Text(
              "\$${product.price.toStringAsFixed(2)}",
              style: const TextStyle(
                color: nexusYellow,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            // BOTÓN EDITAR
            IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: onEdit,
            ),
            // BOTÓN ELIMINAR
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: onDelete,
            ),
          ],
        ),
      ),
    );
  }
}