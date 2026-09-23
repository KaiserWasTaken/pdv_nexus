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
      builder: (context, salesSnapshot) {
        return StreamBuilder<double>(
          stream: db.expenseDao.watchActiveExpensesTotal(),
          builder: (context, expensesSnapshot) {
            // Estado de carga
            if (salesSnapshot.connectionState == ConnectionState.waiting || 
                expensesSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Color(0xFFFFDE00)),
              );
            }

            // Manejo de errores
            if (salesSnapshot.hasError || expensesSnapshot.hasError) {
              return Center(
                child: Text(
                  'Error: ${salesSnapshot.error ?? expensesSnapshot.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              );
            }

            // Extraer datos
            final stats = salesSnapshot.data ?? {};
            final totalSales = stats['totalSales'] as double? ?? 0.0;
            final cashSales = stats['cashSales'] as double? ?? 0.0;
            final cardSales = stats['cardSales'] as double? ?? 0.0;
            final totalExpenses = expensesSnapshot.data ?? 0.0;
            final netProfit = totalSales - totalExpenses;

            return Container(
              padding: const EdgeInsets.all(12),
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
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.analytics, color: nexusYellow, size: 24),
                          const SizedBox(width: 10),
                          const Text(
                            "RESUMEN DEL DÍA",
                            style: TextStyle(
                              color: nexusYellow,
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ],
                      ),
                      // Desglose rápido Efectivo/Tarjeta
                      Row(
                        children: [
                          _MiniStat(label: "EFE", value: cashSales, color: Colors.greenAccent),
                          const SizedBox(width: 10),
                          _MiniStat(label: "TAR", value: cardSales, color: Colors.lightBlueAccent),
                        ],
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // GRID DE STATS
                  Row(
                    children: [
                      // VENTAS
                      Expanded(
                        child: _StatCard(
                          icon: Icons.trending_up,
                          label: "Total Ventas",
                          value: "\$${totalSales.toStringAsFixed(0)}",
                          color: Colors.blueAccent,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // GASTOS
                      Expanded(
                        child: _StatCard(
                          icon: Icons.trending_down,
                          label: "Total Gastos",
                          value: "\$${totalExpenses.toStringAsFixed(0)}",
                          color: Colors.redAccent,
                        ),
                      ),
                      const SizedBox(width: 8),

                      // TOTAL GANADO (BALANCE)
                      Expanded(
                        child: _StatCard(
                          icon: Icons.account_balance_wallet,
                          label: "Ganancia Neta",
                          value: "\$${netProfit.toStringAsFixed(0)}",
                          color: netProfit >= 0 ? Colors.greenAccent : Colors.red,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final double value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text("$label: ", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.bold)),
        Text("\$${value.toStringAsFixed(0)}", style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w900)),
      ],
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