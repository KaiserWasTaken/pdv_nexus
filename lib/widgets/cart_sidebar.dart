import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' hide Column; // ✅ Añadido para Value
import '../providers/cart_provider.dart';
import '../database/database.dart';

class CartSidebar extends StatelessWidget {
  const CartSidebar({super.key});

  @override
  Widget build(BuildContext context) {
    // Colores Nexus
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);
    const nexusRed = Color(0xFFE62117);

    return Container(
      // width: 320, // Eliminado para ser responsivo
      color: Colors.black26,
      child: Column(
        children: [
          // ---------------------------------------------
          // 1. ENCABEZADO
          // ---------------------------------------------
          Container(
            padding: const EdgeInsets.all(20),
            color: nexusBlue,
            width: double.infinity,
            child: const Text(
              "ORDEN ACTUAL",
              style: TextStyle(
                color: nexusYellow,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.0,
              ),
              textAlign: TextAlign.center,
            ),
          ),

          // ---------------------------------------------
          // 2. LISTA DE ITEMS (DISEÑO COMPACTO)
          // ---------------------------------------------
          Expanded(
            child: Consumer<CartProvider>(
              builder: (context, cart, child) {
                if (cart.items.isEmpty) {
                  return const Center(
                    child: Text(
                      "Carrito Vacío",
                      style: TextStyle(color: Colors.white54, fontSize: 18),
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: cart.items.length,
                  itemBuilder: (context, index) {
                    final item = cart.items[index];

                    return Card(
                      color: nexusBlue.withOpacity(0.5),
                      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
                        child: Row(
                          children: [
                            // A. CANTIDAD
                            CircleAvatar(
                              radius: 14,
                              backgroundColor: nexusYellow,
                              child: Text(
                                "${item.quantity}",
                                style: const TextStyle(
                                  color: nexusBlue,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                            const SizedBox(width: 10),

                            // B. NOMBRE Y PRECIO
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  if (item.modifiers.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2),
                                      child: Text(
                                        item.modifiers.join(' • '),
                                        style: const TextStyle(color: Colors.white54, fontSize: 10, fontStyle: FontStyle.italic),
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "\$${(item.price * item.quantity).toStringAsFixed(2)}",
                                    style: const TextStyle(color: nexusYellow, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),

                            // C. BOTÓN RESTAR (-1)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: nexusRed),
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(),
                              iconSize: 24,
                              onPressed: () {
                                cart.decrementItem(item.name, item.type, item.modifiers);
                              },
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),

          // ---------------------------------------------
          // 3. TOTAL Y BOTÓN DE COBRAR
          // ---------------------------------------------
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: const BoxDecoration(
                  color: nexusBlue,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          "TOTAL:",
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerRight,
                            child: Text(
                              "\$${cart.totalAmount.toStringAsFixed(2)}",
                              style: const TextStyle(
                                  color: nexusYellow,
                                  fontSize: 32,
                                  fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: nexusYellow,
                          padding: const EdgeInsets.symmetric(vertical: 20),
                        ),
                        onPressed: cart.items.isEmpty
                            ? null
                            : () => _processCheckout(context, cart),
                        icon: const Icon(Icons.payment, color: nexusBlue, size: 28),
                        label: const Text(
                          "COBRAR",
                          style: TextStyle(
                              color: nexusBlue,
                              fontSize: 24,
                              fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ========================================
  // LÓGICA DEL CHECKOUT (ACTUALIZADA)
  // ========================================
  Future<void> _processCheckout(BuildContext context, CartProvider cart) async {
    // 1. Mostrar diálogo de método de pago
    final paymentMethod = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF00187A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: Color(0xFFFFDE00), width: 2),
        ),
        title: const Text(
          "MÉTODO DE PAGO",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
          textAlign: TextAlign.center,
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "Total a cobrar: \$${cart.totalAmount.toStringAsFixed(2)}",
              style: const TextStyle(color: Color(0xFFFFDE00), fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            const Text("¿Cómo pagará el cliente?", style: TextStyle(color: Colors.white70)),
          ],
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR", style: TextStyle(color: Colors.white54)),
          ),
          const SizedBox(width: 10),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade700),
            onPressed: () => Navigator.pop(ctx, 'Efectivo'),
            icon: const Icon(Icons.money, color: Colors.white),
            label: const Text("EFECTIVO", style: TextStyle(color: Colors.white)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.blue.shade700),
            onPressed: () => Navigator.pop(ctx, 'Tarjeta'),
            icon: const Icon(Icons.credit_card, color: Colors.white),
            label: const Text("TARJETA", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (paymentMethod == null) return;

    try {
      final db = context.read<AppDatabase>();
      final items = cart.items;

      // 2. Registrar todo en el historial de ventas
      final now = DateTime.now();
      final orderGroupId = "ORD-${now.millisecondsSinceEpoch}"; 

      final List<OrderItemsCompanion> allCompanions = [];

      for (var item in items) {
        // CASO A: ES UN COMBO CON COMPONENTES ESTRUCTURADOS
        if (item.category == 'Combos' && item.comboComponents != null) {
          // 1. Insertar Cabecera del Combo (Paga el dinero, no sale en monitor)
          allCompanions.add(OrderItemsCompanion.insert(
            productName: item.name,
            priceAtSale: item.price,
            quantity: Value(item.quantity),
            status: const Value('entregado'), // ✅ Ya cobrado/entregado para monitor
            category: const Value('Combos'),
            orderDate: Value(now),
            modifiers: Value(item.modifiers.join('\n')),
            orderGroupId: Value(orderGroupId),
            paymentMethod: Value(paymentMethod),
          ));

          // 2. Insertar Componentes Individuales (Precio $0, salen en monitor)
          for (var comp in item.comboComponents!) {
            allCompanions.add(OrderItemsCompanion.insert(
              productName: comp['name'],
              priceAtSale: 0.0, // ✅ Precio cero para no duplicar ingresos
              quantity: const Value(1),
              status: Value(comp['category'] == 'Rentas' ? 'entregado' : 'pendiente'), 
              category: Value(comp['category']),
              orderDate: Value(now),
              modifiers: Value(comp['modifiers'] ?? ''),
              orderGroupId: Value(orderGroupId),
              paymentMethod: Value(paymentMethod),
            ));

            // Lógica especial de rentas dentro de combos
            if (comp['category'] == 'Rentas') {
              await db.rentalDao.startRental(
                consoleName: comp['consoleName'],
                startTime: now,
                expectedEndTime: now.add(Duration(minutes: comp['minutes'] ?? 60)),
                extraControllers: comp['extraControllers'] ?? 0,
              );
            }
          }
        } 
        // CASO B: ITEM NORMAL O RENTA INDIVIDUAL
        else {
          allCompanions.add(OrderItemsCompanion.insert(
            productName: item.name,
            priceAtSale: item.price,
            quantity: Value(item.quantity),
            status: Value(item.type == CartItemType.rental ? 'entregado' : 'pendiente'),
            category: Value(item.category),
            orderDate: Value(now),
            modifiers: Value(item.modifiers.join('\n')),
            orderGroupId: Value(orderGroupId),
            paymentMethod: Value(paymentMethod),
          ));

          if (item.type == CartItemType.rental && item.consoleName != null) {
            await db.rentalDao.startRental(
              consoleName: item.consoleName!,
              startTime: now,
              expectedEndTime: now.add(Duration(minutes: item.minutes ?? 0)),
              extraControllers: item.extraControllers ?? 0,
            );
          }
        }
      }

      await db.orderDao.insertCompanions(allCompanions);

      final total = cart.totalAmount;

      // 3. Limpiar el carrito
      cart.clearCart();

      // 4. Confirmación
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Venta completada: \$${total.toStringAsFixed(2)} - Timers iniciados'),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al cobrar: $e'), backgroundColor: Colors.red.shade700),
        );
      }
    }
  }
}