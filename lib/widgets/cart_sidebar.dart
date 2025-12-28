import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
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
      width: 320,
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
                                cart.decrementItem(item.name); // ← CORREGIDO
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
  // LÓGICA DEL CHECKOUT (NUEVA)
  // ========================================
  Future<void> _processCheckout(BuildContext context, CartProvider cart) async {
    try {
      // 1. Obtener acceso a la base de datos
      final db = context.read<AppDatabase>();

      // 2. Guardar todos los items en la BD
      final itemsToSave = cart.getItemsForDatabase();
      await db.orderDao.insertMultipleOrders(itemsToSave);

      // 3. Calcular total para el mensaje
      final total = cart.totalAmount;
      final itemCount = cart.totalItems;

      // 4. Limpiar el carrito
      cart.clearCart();

      // 5. Mostrar confirmación (MEJORADA)
      if (context.mounted) {
        // Cerrar cualquier SnackBar anterior
        ScaffoldMessenger.of(context).clearSnackBars();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Orden registrada - $itemCount items - \${total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.green.shade700,
            duration: const Duration(seconds: 2), // Reducido de 3 a 2
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            margin: const EdgeInsets.only(
              bottom: 70,
              left: 20,
              right: 20,
            ),
            dismissDirection: DismissDirection.horizontal,
          ),
        );
      }

      // TODO FUTURO: Aquí conectaremos Mercado Pago
      // await _processMercadoPagoPayment(total);

    } catch (e) {
      // Manejo de errores
      if (context.mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error, color: Colors.white),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Error al procesar orden: $e'),
                ),
              ],
            ),
            backgroundColor: Colors.red.shade700,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            dismissDirection: DismissDirection.horizontal,
          ),
        );
      }
      debugPrint('Error en checkout: $e');
    }
  }
}