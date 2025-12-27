import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';

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

                            // B. NOMBRE Y PRECIO (Expanded para llenar espacio)
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.name,
                                    style: const TextStyle(
                                        color: Colors.white, fontWeight: FontWeight.bold),
                                    maxLines: 1, // Fuerza una sola línea
                                    overflow: TextOverflow.ellipsis, // Pone "..." si no cabe
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    "\$${(item.price * item.quantity).toStringAsFixed(2)}",
                                    style: const TextStyle(color: nexusYellow, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),

                            // C. BOTÓN BORRAR (Sin márgenes extra)
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: nexusRed),
                              padding: EdgeInsets.zero, // Quita relleno interno
                              constraints: const BoxConstraints(), // Quita tamaño mínimo
                              iconSize: 24,
                              onPressed: () {
                                cart.removeItem(item.name);
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
                        // Previene overflow si el precio es muy grande
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
                            : () {
                          print("Ir a pagar \$${cart.totalAmount}");
                        },
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
}