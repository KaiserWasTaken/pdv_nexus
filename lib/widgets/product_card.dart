import 'dart:io';
import 'package:flutter/material.dart';

class ProductCard extends StatelessWidget {
  final String name;
  final double price;
  final String category;
  final String? imagePath; // ✅ NUEVO: Ruta de imagen
  final VoidCallback onTap;

  const ProductCard({
    super.key,
    required this.name,
    required this.price,
    required this.category,
    this.imagePath, // ✅ NUEVO: Parámetro opcional
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
              // ✅ IMAGEN O ÍCONO
              Flexible(
                flex: 3,
                child: _buildImageOrIcon(category),
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

  // ✅ NUEVO: Construir imagen o ícono según disponibilidad
  Widget _buildImageOrIcon(String category) {
    // Si hay imagen, mostrarla
    if (imagePath != null && imagePath!.isNotEmpty) {
      final imageFile = File(imagePath!);

      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(
          imageFile,
          fit: BoxFit.cover,
          width: double.infinity,
          errorBuilder: (context, error, stackTrace) {
            // Si la imagen no se puede cargar, mostrar ícono
            return _buildFallbackIcon(category);
          },
        ),
      );
    }

    // Si no hay imagen, mostrar ícono por categoría
    return _buildFallbackIcon(category);
  }

  // ✅ NUEVO: Ícono de respaldo por categoría
  Widget _buildFallbackIcon(String category) {
    IconData icon;

    switch (category.toLowerCase()) {
      case 'bebida':
        icon = Icons.local_drink;
        break;
      case 'comida':
        icon = Icons.fastfood;
        break;
      case 'paquete':
        icon = Icons.card_giftcard;
        break;
      default:
        icon = Icons.inventory_2;
    }

    return Icon(
      icon,
      size: 48,
      color: Colors.white70,
    );
  }
}