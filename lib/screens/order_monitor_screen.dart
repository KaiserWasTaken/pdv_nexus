import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';

class OrderMonitorScreen extends StatelessWidget {
  const OrderMonitorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);
    const nexusRed = Color(0xFFE62117);

    final db = context.read<AppDatabase>();

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ============================================
          // ENCABEZADO
          // ============================================
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "MONITOR DE PEDIDOS",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),

              // Indicador de órdenes pendientes
              StreamBuilder<List<OrderItem>>(
                stream: db.orderDao.watchPendingOrders(),
                builder: (context, snapshot) {
                  final pendingCount = snapshot.data?.length ?? 0;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: pendingCount > 0 ? nexusRed : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: pendingCount > 0
                          ? [
                        BoxShadow(
                          color: nexusRed.withOpacity(0.5),
                          blurRadius: 10,
                          spreadRadius: 2,
                        ),
                      ]
                          : null,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          pendingCount > 0 ? Icons.pending_actions : Icons.check_circle,
                          color: Colors.white,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          pendingCount > 0
                              ? "$pendingCount Pendientes"
                              : "¡Todo Entregado!",
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ============================================
          // LISTA DE ÓRDENES PENDIENTES
          // ============================================
          Expanded(
            child: StreamBuilder<List<OrderItem>>(
              stream: db.orderDao.watchPendingOrders(),
              builder: (context, snapshot) {
                // Estados de carga
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: nexusYellow),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 64, color: nexusRed),
                        const SizedBox(height: 16),
                        Text(
                          "Error: ${snapshot.error}",
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  );
                }

                final pendingOrders = snapshot.data ?? [];

                // Si no hay órdenes pendientes
                if (pendingOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle_outline,
                          size: 100,
                          color: Colors.green.withOpacity(0.5),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          "¡Todo entregado!",
                          style: TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "No hay pedidos pendientes",
                          style: TextStyle(color: Colors.white54),
                        ),
                      ],
                    ),
                  );
                }

                // Lista de órdenes con Dismissible (swipe para marcar)
                return ListView.builder(
                  itemCount: pendingOrders.length,
                  itemBuilder: (context, index) {
                    final order = pendingOrders[index];

                    return Dismissible(
                      key: Key('order_${order.id}'),
                      direction: DismissDirection.endToStart,
                      confirmDismiss: (direction) async {
                        return await _showConfirmDialog(context, order);
                      },
                      onDismissed: (direction) async {
                        await db.orderDao.markAsDelivered(order.id);

                        if (context.mounted) {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      '"${order.productName}" entregado',
                                      style: const TextStyle(fontSize: 13),
                                    ),
                                  ),
                                ],
                              ),
                              backgroundColor: Colors.green.shade700,
                              duration: const Duration(milliseconds: 1500),
                              behavior: SnackBarBehavior.floating,
                              margin: const EdgeInsets.only(
                                bottom: 70,
                                left: 20,
                                right: 20,
                              ),
                              dismissDirection: DismissDirection.horizontal,
                            ),
                          );
                        }
                      },
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        color: Colors.green,
                        child: const Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 40),
                            SizedBox(height: 8),
                            Text(
                              "ENTREGAR",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      child: Card(
                        color: nexusBlue.withOpacity(0.7),
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          side: const BorderSide(color: nexusYellow, width: 2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Row(
                            children: [
                              // Indicador visual
                              Container(
                                width: 8,
                                height: 60,
                                decoration: BoxDecoration(
                                  color: nexusRed,
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),

                              const SizedBox(width: 16),

                              // Información del pedido
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      order.productName,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "Cantidad: ${order.quantity} | \$${order.priceAtSale.toStringAsFixed(2)} c/u",
                                      style: const TextStyle(
                                        color: Colors.white70,
                                        fontSize: 14,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      _formatTime(order.orderDate),
                                      style: const TextStyle(
                                        color: nexusYellow,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              // Botón alternativo (además del swipe)
                              IconButton(
                                icon: const Icon(Icons.check_circle, color: Colors.green),
                                iconSize: 32,
                                onPressed: () async {
                                  final confirm = await _showConfirmDialog(context, order);
                                  if (confirm == true) {
                                    await db.orderDao.markAsDelivered(order.id);

                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).clearSnackBars();
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(Icons.check_circle, color: Colors.white, size: 18),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Text(
                                                  '"${order.productName}" entregado',
                                                  style: const TextStyle(fontSize: 13),
                                                ),
                                              ),
                                            ],
                                          ),
                                          backgroundColor: Colors.green.shade700,
                                          duration: const Duration(milliseconds: 1500),
                                          behavior: SnackBarBehavior.floating,
                                          margin: const EdgeInsets.only(
                                            bottom: 70,
                                            left: 20,
                                            right: 20,
                                          ),
                                          dismissDirection: DismissDirection.horizontal,
                                        ),
                                      );
                                    }
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================
  // DIÁLOGO DE CONFIRMACIÓN
  // ============================================
  Future<bool?> _showConfirmDialog(BuildContext context, OrderItem order) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF00187A),
        title: const Text(
          "Confirmar Entrega",
          style: TextStyle(color: Colors.white),
        ),
        content: Text(
          '¿Marcar "${order.productName}" (x${order.quantity}) como entregado?',
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text("Cancelar", style: TextStyle(color: Colors.white54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text("Confirmar"),
          ),
        ],
      ),
    );
  }

  // ============================================
  // FORMATEAR TIEMPO
  // ============================================
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inMinutes < 1) {
      return "Hace unos segundos";
    } else if (difference.inMinutes < 60) {
      return "Hace ${difference.inMinutes} min";
    } else if (difference.inHours < 24) {
      return "Hace ${difference.inHours}h ${difference.inMinutes % 60}min";
    } else {
      return "${dateTime.day}/${dateTime.month} ${dateTime.hour}:${dateTime.minute.toString().padLeft(2, '0')}";
    }
  }
}