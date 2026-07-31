import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';

class DayPreviewScreen extends StatelessWidget {
  const DayPreviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);
    const nexusDarkBg = Color(0xFF000F4D);

    final db = context.read<AppDatabase>();

    return Scaffold(
      backgroundColor: nexusDarkBg,
      body: SafeArea(
        child: Column(
          children: [
            // BARRA SUPERIOR PERSONALIZADA (OCUPA TODO EL ANCHO)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              color: nexusBlue,
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.close, color: Colors.white, size: 30),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const SizedBox(width: 16),
                  const Expanded(
                    child: Text(
                      "AVANCE DEL TURNO ACTUAL",
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  Text(
                    DateFormat('dd/MM/yyyy').format(DateTime.now()),
                    style: const TextStyle(color: nexusYellow, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),

            // CONTENIDO DEL REPORTE
            Expanded(
              child: FutureBuilder<List<OrderItem>>(
                future: db.orderDao.getActiveOrders(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator(color: nexusYellow));
                  }

                  final orders = snapshot.data!;
                  if (orders.isEmpty) {
                    return const Center(
                      child: Text(
                        "No hay ventas registradas en este turno.",
                        style: TextStyle(color: Colors.white54, fontSize: 18),
                      ),
                    );
                  }

                  // Lógica de agrupación igual al PDF
                  final Map<String, int> productCounts = {};
                  final Map<String, double> productRevenue = {};
                  final Map<String, int> rentalCounts = {'Xbox': 0, 'Switch': 0, 'PS5': 0};
                  final Map<String, double> rentalRevenue = {'Xbox': 0.0, 'Switch': 0.0, 'PS5': 0.0};
                  double grandTotal = 0;

                  for (var order in orders) {
                    grandTotal += order.priceAtSale * order.quantity;
                    final cat = (order.category ?? 'Otros').trim().toLowerCase();

                    if (cat == 'rentas') {
                      String type = 'Otros';
                      if (order.productName.contains('Xbox')) type = 'Xbox';
                      else if (order.productName.contains('Switch')) type = 'Switch';
                      else if (order.productName.contains('PS5')) type = 'PS5';
                      
                      rentalCounts[type] = (rentalCounts[type] ?? 0) + order.quantity;
                      rentalRevenue[type] = (rentalRevenue[type] ?? 0.0) + (order.priceAtSale * order.quantity);
                    } else {
                      productCounts[order.productName] = (productCounts[order.productName] ?? 0) + order.quantity;
                      productRevenue[order.productName] = (productRevenue[order.productName] ?? 0.0) + (order.priceAtSale * order.quantity);
                    }
                  }

                  return Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // COLUMNA IZQUIERDA: RESUMEN DE PRODUCTOS Y RENTAS
                        Expanded(
                          flex: 5,
                          child: SingleChildScrollView(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildSectionTitle("RESUMEN DE PRODUCTOS"),
                                _buildSummaryTable(['CANT', 'PRODUCTO', 'TOTAL'], productCounts.entries.map((e) => [
                                  e.value.toString(),
                                  e.key,
                                  "\$${productRevenue[e.key]!.toStringAsFixed(2)}"
                                ]).toList()),
                                
                                const SizedBox(height: 40),
                                
                                _buildSectionTitle("RESUMEN DE RENTAS"),
                                _buildSummaryTable(['CANT', 'CONSOLA', 'TOTAL'], rentalCounts.entries.where((e) => e.value > 0).map((e) => [
                                  e.value.toString(),
                                  e.key,
                                  "\$${rentalRevenue[e.key]!.toStringAsFixed(2)}"
                                ]).toList()),
                              ],
                            ),
                          ),
                        ),

                        const SizedBox(width: 40),

                        // COLUMNA DERECHA: TOTAL Y CRONOLOGÍA
                        Expanded(
                          flex: 4,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: nexusBlue.withOpacity(0.3),
                                  borderRadius: BorderRadius.circular(16),
                                  border: Border.all(color: nexusYellow, width: 2),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Text("TOTAL ACUMULADO", style: TextStyle(color: Colors.white70, fontSize: 16)),
                                    Text(
                                      "\$${grandTotal.toStringAsFixed(2)}",
                                      style: const TextStyle(color: nexusYellow, fontSize: 42, fontWeight: FontWeight.w900),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 30),
                              const Expanded(child: SizedBox()), // Espaciador
                              const Text("Los datos se resetearán al generar el PDF final.", style: TextStyle(color: Colors.white24, fontSize: 12)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFFFFDE00), fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildSummaryTable(List<String> headers, List<List<String>> rows) {
    return Table(
      columnWidths: const {
        0: IntrinsicColumnWidth(),
        1: FlexColumnWidth(),
        2: IntrinsicColumnWidth(),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white24))),
          children: headers.map((h) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(h, style: const TextStyle(color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 12)),
          )).toList(),
        ),
        ...rows.map((row) => TableRow(
          decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white10))),
          children: row.map((cell) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(cell, style: const TextStyle(color: Colors.white, fontSize: 15)),
          )).toList(),
        )),
      ],
    );
  }
}
