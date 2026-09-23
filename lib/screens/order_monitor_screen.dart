import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../widgets/order_ticket_widget.dart'; // ✅ Nuevo

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
                "MONITOR DE BARRA",
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: 1.2,
                ),
              ),

              // Indicador de tickets pendientes
              StreamBuilder<List<OrderItem>>(
                stream: db.orderDao.watchPendingOrders(),
                builder: (context, snapshot) {
                  final orders = snapshot.data ?? [];
                  // Contar grupos únicos
                  final uniqueGroups = orders.map((o) => o.orderGroupId ?? 'none').toSet();
                  final pendingCount = uniqueGroups.contains('none') ? orders.length : uniqueGroups.length;
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: pendingCount > 0 ? nexusRed : Colors.green,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        Icon(pendingCount > 0 ? Icons.pending_actions : Icons.check_circle, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          pendingCount > 0 ? "$pendingCount Tickets" : "¡Todo Listo!",
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
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
          // GRID DE TICKETS DE ORDEN
          // ============================================
          Expanded(
            child: StreamBuilder<List<OrderItem>>(
              stream: db.orderDao.watchPendingOrders(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: nexusYellow));
                }

                final allPending = snapshot.data ?? [];

                if (allPending.isEmpty) {
                  return const _EmptyState();
                }

                // Agrupar items por orderGroupId
                final Map<String, List<OrderItem>> tickets = {};
                for (var item in allPending) {
                  final String groupId = item.orderGroupId ?? "S-${item.id}"; // Fallback para registros viejos
                  tickets.putIfAbsent(groupId, () => []).add(item);
                }

                return GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // ✅ Cambiado de 3 a 2 para tickets más grandes
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9, // Ajustado ligeramente para mayor ancho
                  ),
                  itemCount: tickets.length,
                  itemBuilder: (context, index) {
                    final groupId = tickets.keys.elementAt(index);
                    final ticketItems = tickets[groupId]!;

                    return OrderTicketWidget(
                      key: ValueKey(groupId), // ✅ Asegurar que el estado no se comparta
                      groupId: groupId,
                      items: ticketItems,
                      onDelivered: () async {
                        // Si tiene groupId, marcar todo el grupo
                        if (groupId.startsWith('ORD')) {
                          await db.orderDao.markOrderGroupAsDelivered(groupId);
                        } else {
                          // Si es individual (viejo), marcar solo ese
                          await db.orderDao.markAsDelivered(ticketItems.first.id);
                        }
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
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline, size: 100, color: Colors.green.withOpacity(0.3)),
          const SizedBox(height: 20),
          const Text("¡Todo entregado!", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white54)),
        ],
      ),
    );
  }
}
