import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';

class OrderTicketWidget extends StatefulWidget {
  final String groupId;
  final List<OrderItem> items;
  final VoidCallback onDelivered;

  const OrderTicketWidget({
    super.key,
    required this.groupId,
    required this.items,
    required this.onDelivered,
  });

  @override
  State<OrderTicketWidget> createState() => _OrderTicketWidgetState();
}

class _OrderTicketWidgetState extends State<OrderTicketWidget> {
  // Estado local para los checkboxes de los productos
  final Map<int, bool> _itemChecked = {};

  @override
  void initState() {
    super.initState();
    for (var item in widget.items) {
      _itemChecked[item.id] = false;
    }
  }

  bool get _allChecked => _itemChecked.values.every((checked) => checked);

  @override
  Widget build(BuildContext context) {
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);

    // Agrupar items por categoría (Bebidas, Comidas, etc.)
    final Map<String, List<OrderItem>> grouped = {};
    for (var item in widget.items) {
      final cat = item.category ?? 'General';
      grouped.putIfAbsent(cat, () => []).add(item);
    }

    final String lastPart = widget.groupId.split('-').last;
    final String ticketNumber = lastPart.length > 4 
        ? lastPart.substring(lastPart.length - 4) 
        : lastPart; // Tomar últimos 4 dígitos o todo si es corto
    final String time = DateFormat('HH:mm').format(widget.items.first.orderDate.toLocal());

    return Card(
      elevation: 8,
      color: const Color(0xFF000F4D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: _allChecked ? Colors.green : nexusYellow, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(16), // Aumentado para mejor legibilidad
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("#$ticketNumber", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                Text(time, style: const TextStyle(color: nexusYellow, fontWeight: FontWeight.bold)),
              ],
            ),
            const Divider(color: Colors.white24),

            // CUERPO: CATEGORÍAS E ITEMS
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  children: grouped.entries.map((entry) {
                    return _buildCategorySection(entry.key, entry.value);
                  }).toList(),
                ),
              ),
            ),

            const SizedBox(height: 12),

            // FOOTER: BOTÓN ENTREGADO
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: _allChecked ? Colors.green : Colors.grey.shade800,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _allChecked ? widget.onDelivered : null,
                child: const Text("ENTREGADO", style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategorySection(String category, List<OrderItem> items) {
    IconData icon = Icons.fastfood;
    if (category.contains('Bebida')) icon = Icons.local_drink;
    if (category.contains('Combo')) icon = Icons.card_giftcard;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0),
          child: Row(
            children: [
              Icon(icon, color: const Color(0xFFFFDE00), size: 18),
              const SizedBox(width: 8),
              Text(category.toUpperCase(), style: const TextStyle(color: Color(0xFFFFDE00), fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        ...items.map((item) => _buildItemRow(item)),
      ],
    );
  }

  Widget _buildItemRow(OrderItem item) {
    // Los modificadores ya vienen con saltos de línea desde el checkout
    String displayModifiers = item.modifiers ?? "";

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12), // ✅ Aumentado para dar espacio a la multilínea
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.productName, 
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22)
                ),
                if (displayModifiers.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      displayModifiers, 
                      style: const TextStyle(
                        color: Color(0xFFFFDE00), 
                        fontSize: 20, // ✅ Un poco más grande para leer mejor la lista
                        fontStyle: FontStyle.italic, 
                        fontWeight: FontWeight.w600,
                        height: 1.3, // ✅ Más interlineado para que los renglones se separen bien
                      )
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text("x${item.quantity}", style: const TextStyle(color: Color(0xFFFFDE00), fontWeight: FontWeight.w900, fontSize: 20)),
          Transform.scale(
            scale: 1.3,
            child: Checkbox(
              value: _itemChecked[item.id] ?? false,
              activeColor: const Color(0xFFFFDE00),
              checkColor: Colors.black,
              onChanged: (val) {
                setState(() {
                  _itemChecked[item.id] = val!;
                });
              },
            ),
          ),
        ],
      ),
    );
  }
}
