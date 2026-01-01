import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final double price;
  final String category;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.category,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Card(
        color: nexusBlue.withOpacity(0.8),
        elevation: 4,
        shape: RoundedRectangleBorder(
          side: const BorderSide(color: nexusYellow, width: 2.5),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // ICONO
              Flexible(
                flex: 2,
                child: Icon(
                  category == 'Bebida' ? Icons.local_drink : Icons.fastfood,
                  size: 32,
                  color: Colors.white70,
                ),
              ),

              const SizedBox(height: 8),

              // NOMBRE DEL PRODUCTO
              Flexible(
                flex: 2,
                child: Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 11,
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),

              const SizedBox(height: 4),

              // PRECIO
              Text(
                '\$${price.toStringAsFixed(0)}',
                style: const TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 16,
                  color: nexusYellow,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}