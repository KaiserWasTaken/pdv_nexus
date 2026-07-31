import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';

class StatsPanel extends StatelessWidget {
  const StatsPanel({super.key});

  @override
  Widget build(BuildContext context) {
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);

    final db = context.read<AppDatabase>();

    return StreamBuilder<Map<String, dynamic>>(
      stream: db.orderDao.watchTodayStats(),
      builder: (context, snapshot) {
        // Estado de carga
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: Color(0xFFFFDE00)),
          );
        }

        // Manejo de errores
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'Error: ${snapshot.error}',
              style: const TextStyle(color: Colors.red),
            ),
          );
        }

        // Extraer datos
        final stats = snapshot.data ?? {};
        final totalSales = stats['totalSales'] as double? ?? 0.0;
        final totalItems = stats['totalItems'] as int? ?? 0;

        return Container(
          padding: const EdgeInsets.all(12), // Reducido de 16 a 12
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                nexusBlue.withOpacity(0.8),
                nexusBlue.withOpacity(0.4),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: nexusYellow, width: 2),
          ),
          child: Column(
            children: [
              // TÍTULO
              Row(
                children: [
                  const Icon(Icons.analytics, color: nexusYellow, size: 24),
                  const SizedBox(width: 10),
                  const Text(
                    "ESTADÍSTICAS DEL DÍA",
                    style: TextStyle(
                      color: nexusYellow,
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 1.0,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 12), // Reducido de 20 a 12

              // GRID DE STATS (SÓLO PRINCIPALES)
              Row(
                children: [
                  // TOTAL VENDIDO
                  Expanded(
                    child: _StatCard(
                      icon: Icons.attach_money,
                      label: "Total Vendido",
                      value: "\$${totalSales.toStringAsFixed(2)}",
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // ITEMS VENDIDOS
                  Expanded(
                    child: _StatCard(
                      icon: Icons.shopping_cart,
                      label: "Items Vendidos",
                      value: "$totalItems",
                      color: nexusYellow,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================
// WIDGET AUXILIAR: TARJETA DE ESTADÍSTICA
// ============================================
class _StatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black26,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 24,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 11,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}