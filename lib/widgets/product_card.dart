import 'dart:io';
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final double price;
  final String category;
  final String? description; // ✅ NUEVO: Para mostrar contenido de combos
  final String? imagePath;
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.category,
    this.description, // ✅ NUEVO
    this.imagePath,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);

    bool isCombo = category == 'Combos' && description != null;

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
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // NOMBRE DEL PRODUCTO
              Text(
                name,
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: isCombo ? 20 : 24, // Un poco más pequeño si es combo para dar espacio
                  color: Colors.white,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),

              if (isCombo) ...[
                const SizedBox(height: 8),
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _buildDescriptionBullets(description!),
                    ),
                  ),
                ),
              ] else
                const Expanded(child: SizedBox()),

              const SizedBox(height: 8),

              // PRECIO
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  '\$${price.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.w900,
                    fontSize: 22,
                    color: nexusYellow,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDescriptionBullets(String desc) {
    // Dividir por "+" o "," o "." para crear viñetas
    final items = desc.split(RegExp(r'[+\.\n]')).map((s) => s.trim()).where((s) => s.isNotEmpty).toList();

    return items.map((item) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 4), // Aumentado de 2 a 4
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("• ",
                style: TextStyle(
                  color: Color(0xFFFFDE00),
                  fontWeight: FontWeight.bold,
                  fontSize: 20, // Viñeta más grande
                )),
            Expanded(
              child: Text(
                item,
                style: const TextStyle(
                  color: Colors.white, // De blanco70 a blanco puro para mejor contraste
                  fontSize: 18, // Aumentado de 14 a 18
                  fontWeight: FontWeight.w600, // Un poco más de peso
                  height: 1.1,
                ),
              ),
            ),
          ],
        ),
      );
    }).toList();
  }
}
