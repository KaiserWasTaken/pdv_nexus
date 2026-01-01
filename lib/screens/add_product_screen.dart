import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _descriptionController = TextEditingController();

  String _productType = 'simple'; // 'simple' o 'paquete'
  String _selectedCategory = 'Bebida';
  String? _selectedSubcategory;

  // Subcategorías por categoría
  final Map<String, List<String>> _subcategories = {
    'Bebida': [
      'Bubble Tea Base Agua',
      'Bubble Tea Base Leche',
      'Soda Italiana',
      'Tisana',
      'Refresco',
      'Agua Embotellada',
      'Frappé',
    ],
    'Comida': [
      'Mini Hot Cakes',
      'Nexuleta Salada',
      'Nexuleta Dulce',
      'Nachos',
      'Palomitas',
      'Maruchan',
      'Pizza',
      'Combo',
    ],
  };

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);

    return Scaffold(
      backgroundColor: const Color(0xFF000F4D),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ENCABEZADO
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Colors.white),
                  onPressed: () => Navigator.pop(context),
                ),
                const SizedBox(width: 10),
                const Text(
                  "AGREGAR PRODUCTO",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),

            // FORMULARIO
            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TIPO DE PRODUCTO
                      const Text(
                        "Tipo de Producto",
                        style: TextStyle(
                          color: nexusYellow,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _TypeButton(
                              label: "Producto Simple",
                              icon: Icons.inventory_2,
                              isSelected: _productType == 'simple',
                              onTap: () {
                                setState(() => _productType = 'simple');
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: _TypeButton(
                              label: "Paquete/Combo",
                              icon: Icons.card_giftcard,
                              isSelected: _productType == 'paquete',
                              onTap: () {
                                setState(() {
                                  _productType = 'paquete';
                                  _selectedCategory = 'Paquete';
                                });
                              },
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 30),

                      // NOMBRE
                      _buildTextField(
                        controller: _nameController,
                        label: "Nombre del Producto",
                        hint: "Ej: Bubble Tea Taro",
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El nombre es obligatorio';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // PRECIO
                      _buildTextField(
                        controller: _priceController,
                        label: "Precio",
                        hint: "Ej: 89.00",
                        keyboardType: TextInputType.number,
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'El precio es obligatorio';
                          }
                          if (double.tryParse(value) == null) {
                            return 'Ingresa un número válido';
                          }
                          return null;
                        },
                      ),

                      const SizedBox(height: 20),

                      // CATEGORÍA (Solo si es producto simple)
                      if (_productType == 'simple') ...[
                        const Text(
                          "Categoría",
                          style: TextStyle(
                            color: nexusYellow,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _selectedCategory,
                          dropdownColor: nexusBlue,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: nexusBlue.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: nexusYellow),
                            ),
                          ),
                          style: const TextStyle(color: Colors.white),
                          items: ['Bebida', 'Comida'].map((category) {
                            return DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedCategory = value!;
                              _selectedSubcategory = null;
                            });
                          },
                        ),

                        const SizedBox(height: 20),

                        // SUBCATEGORÍA
                        const Text(
                          "Subcategoría (Opcional)",
                          style: TextStyle(
                            color: nexusYellow,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 10),
                        DropdownButtonFormField<String>(
                          value: _selectedSubcategory,
                          dropdownColor: nexusBlue,
                          decoration: InputDecoration(
                            filled: true,
                            fillColor: nexusBlue.withOpacity(0.3),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: nexusYellow),
                            ),
                            hintText: 'Selecciona una subcategoría',
                            hintStyle: const TextStyle(color: Colors.white54),
                          ),
                          style: const TextStyle(color: Colors.white),
                          items: _subcategories[_selectedCategory]!.map((sub) {
                            return DropdownMenuItem(
                              value: sub,
                              child: Text(sub),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() => _selectedSubcategory = value);
                          },
                        ),

                        const SizedBox(height: 20),
                      ],

                      // DESCRIPCIÓN
                      _buildTextField(
                        controller: _descriptionController,
                        label: "Descripción (Opcional)",
                        hint: "Ej: Cremoso bubble tea con perlas de tapioca",
                        maxLines: 3,
                      ),

                      const SizedBox(height: 20),

                      // IMAGEN (Placeholder)
                      const Text(
                        "Imagen del Producto",
                        style: TextStyle(
                          color: nexusYellow,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      InkWell(
                        onTap: () {
                          // TODO: Implementar selector de imagen
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text("Selector de imagen próximamente..."),
                            ),
                          );
                        },
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: nexusBlue.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: nexusYellow,
                              width: 2,
                              style: BorderStyle.solid,
                            ),
                          ),
                          child: const Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.add_photo_alternate,
                                size: 48,
                                color: Colors.white54,
                              ),
                              SizedBox(height: 10),
                              Text(
                                "Toca para agregar imagen",
                                style: TextStyle(color: Colors.white54),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 40),

                      // BOTÓN GUARDAR
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: nexusYellow,
                            foregroundColor: nexusBlue,
                          ),
                          onPressed: _saveProduct,
                          icon: const Icon(Icons.save, size: 28),
                          label: const Text(
                            "GUARDAR PRODUCTO",
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: nexusYellow,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white54),
            filled: true,
            fillColor: nexusBlue.withOpacity(0.3),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: nexusYellow),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: nexusYellow),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: nexusYellow, width: 2),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final db = context.read<AppDatabase>();

    try {
      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final description = _descriptionController.text.trim();

      if (_productType == 'simple') {
        await db.productDao.insertProduct(
          name: name,
          price: price,
          category: _selectedCategory,
          subcategory: _selectedSubcategory,
          description: description.isEmpty ? null : description,
        );
      } else {
        // TODO: Implementar lógica de paquetes
        await db.productDao.insertPackage(
          name: name,
          price: price,
          description: description,
          items: [], // Por ahora vacío
        );
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Producto guardado exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}

// ============================================
// WIDGET: BOTÓN DE TIPO
// ============================================
class _TypeButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _TypeButton({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected
              ? nexusYellow.withOpacity(0.2)
              : nexusBlue.withOpacity(0.3),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? nexusYellow : Colors.white30,
            width: isSelected ? 3 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              size: 40,
              color: isSelected ? nexusYellow : Colors.white54,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: isSelected ? nexusYellow : Colors.white70,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}