import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import 'package:image_picker/image_picker.dart';
import '../database/database.dart';
import '../services/image_service.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({
    super.key,
    required this.product,
  });

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _priceController;
  late TextEditingController _descriptionController;
  final ImageService _imageService = ImageService();

  late String _productType;
  late String _selectedCategory;
  String? _selectedSubcategory;

  // ✅ NUEVO: Manejo de imágenes
  String? _currentImagePath; // Imagen actual del producto
  File? _newImage; // Nueva imagen seleccionada (si se cambia)
  bool _deleteCurrentImage = false; // Flag para eliminar imagen actual

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
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.product.name);
    _priceController = TextEditingController(text: widget.product.price.toString());
    _descriptionController = TextEditingController(text: widget.product.description ?? '');

    _productType = widget.product.productType;
    _selectedCategory = widget.product.category;
    _selectedSubcategory = widget.product.subcategory;
    _currentImagePath = widget.product.imagePath; // ✅ Cargar imagen actual
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ✅ NUEVO: Seleccionar nueva imagen
  Future<void> _pickImage() async {
    final source = await ImageService.showImageSourceDialog(context);
    if (source == null) return;

    final image = await _imageService.pickAndCropImage(source: source);
    if (image != null) {
      setState(() {
        _newImage = image;
        _deleteCurrentImage = false; // Si selecciona nueva, no eliminar la actual
      });
    }
  }

  // ✅ NUEVO: Eliminar imagen (marcar para eliminar)
  void _removeImage() {
    setState(() {
      if (_newImage != null) {
        // Si hay imagen nueva seleccionada, eliminarla
        _newImage = null;
      } else if (_currentImagePath != null) {
        // Si hay imagen actual, marcarla para eliminar
        _deleteCurrentImage = true;
      }
    });
  }

  // ✅ NUEVO: Cancelar eliminación
  void _undoRemoveImage() {
    setState(() {
      _deleteCurrentImage = false;
    });
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
                  "EDITAR PRODUCTO",
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
                      // TIPO DE PRODUCTO (SOLO VISUAL, NO EDITABLE)
                      const Text(
                        "Tipo de Producto",
                        style: TextStyle(
                          color: nexusYellow,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: nexusYellow.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: nexusYellow, width: 2),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              _productType == 'simple'
                                  ? Icons.inventory_2
                                  : Icons.card_giftcard,
                              color: nexusYellow,
                              size: 32,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _productType == 'simple'
                                  ? 'Producto Simple'
                                  : 'Paquete/Combo',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const Spacer(),
                            const Text(
                              '(No editable)',
                              style: TextStyle(
                                color: Colors.white54,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
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
                              if (_selectedSubcategory != null &&
                                  !_subcategories[_selectedCategory]!
                                      .contains(_selectedSubcategory)) {
                                _selectedSubcategory = null;
                              }
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

                      // ✅ IMAGEN DEL PRODUCTO (ACTUALIZADO)
                      const Text(
                        "Imagen del Producto",
                        style: TextStyle(
                          color: nexusYellow,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 10),

                      // Contenedor de imagen
                      InkWell(
                        onTap: (_newImage == null && !_deleteCurrentImage)
                            ? _pickImage
                            : null,
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          height: 200,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: nexusBlue.withOpacity(0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _deleteCurrentImage ? Colors.red : nexusYellow,
                              width: 2,
                            ),
                          ),
                          child: _buildImageContent(),
                        ),
                      ),

                      // Botones de acción de imagen
                      const SizedBox(height: 10),
                      _buildImageActions(),

                      const SizedBox(height: 40),

                      // BOTÓN GUARDAR CAMBIOS
                      SizedBox(
                        width: double.infinity,
                        height: 60,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: nexusYellow,
                            foregroundColor: nexusBlue,
                          ),
                          onPressed: _updateProduct,
                          icon: const Icon(Icons.save, size: 28),
                          label: const Text(
                            "GUARDAR CAMBIOS",
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

  // ✅ NUEVO: Construir contenido de imagen según estado
  Widget _buildImageContent() {
    // Caso 1: Hay nueva imagen seleccionada
    if (_newImage != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          _newImage!,
          fit: BoxFit.cover,
        ),
      );
    }

    // Caso 2: Imagen actual marcada para eliminar
    if (_deleteCurrentImage && _currentImagePath != null) {
      return Stack(
        children: [
          Opacity(
            opacity: 0.3,
            child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.file(
                File(_currentImagePath!),
                fit: BoxFit.cover,
              ),
            ),
          ),
          const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delete_forever, size: 64, color: Colors.red),
                SizedBox(height: 8),
                Text(
                  "Se eliminará al guardar",
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    // Caso 3: Hay imagen actual (sin cambios)
    if (_currentImagePath != null) {
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.file(
          File(_currentImagePath!),
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.broken_image, size: 48, color: Colors.white54),
                SizedBox(height: 8),
                Text(
                  "Imagen no encontrada",
                  style: TextStyle(color: Colors.white54),
                ),
              ],
            ),
          ),
        ),
      );
    }

    // Caso 4: Sin imagen
    return const Column(
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
    );
  }

  // ✅ NUEVO: Construir botones de acción según estado
  Widget _buildImageActions() {
    const nexusYellow = Color(0xFFFFDE00);

    // Si hay nueva imagen seleccionada
    if (_newImage != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.edit, size: 20),
              label: const Text("Cambiar"),
              style: OutlinedButton.styleFrom(
                foregroundColor: nexusYellow,
                side: const BorderSide(color: nexusYellow),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _removeImage,
              icon: const Icon(Icons.close, size: 20),
              label: const Text("Cancelar"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      );
    }

    // Si imagen actual está marcada para eliminar
    if (_deleteCurrentImage && _currentImagePath != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _undoRemoveImage,
              icon: const Icon(Icons.undo, size: 20),
              label: const Text("Deshacer"),
              style: OutlinedButton.styleFrom(
                foregroundColor: nexusYellow,
                side: const BorderSide(color: nexusYellow),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.add_photo_alternate, size: 20),
              label: const Text("Nueva imagen"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.green,
                side: const BorderSide(color: Colors.green),
              ),
            ),
          ),
        ],
      );
    }

    // Si hay imagen actual (sin cambios)
    if (_currentImagePath != null) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _pickImage,
              icon: const Icon(Icons.edit, size: 20),
              label: const Text("Cambiar"),
              style: OutlinedButton.styleFrom(
                foregroundColor: nexusYellow,
                side: const BorderSide(color: nexusYellow),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _removeImage,
              icon: const Icon(Icons.delete, size: 20),
              label: const Text("Eliminar"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                side: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      );
    }

    // Sin imagen - solo botón para agregar
    return OutlinedButton.icon(
      onPressed: _pickImage,
      icon: const Icon(Icons.add_photo_alternate, size: 20),
      label: const Text("Agregar Imagen"),
      style: OutlinedButton.styleFrom(
        foregroundColor: nexusYellow,
        side: const BorderSide(color: nexusYellow),
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

  Future<void> _updateProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final db = context.read<AppDatabase>();

    try {
      final name = _nameController.text.trim();
      final price = double.parse(_priceController.text.trim());
      final description = _descriptionController.text.trim();

      // ✅ Determinar ruta de imagen final
      String? finalImagePath;

      if (_newImage != null) {
        // Usar nueva imagen
        finalImagePath = _newImage!.path;
        // Eliminar imagen anterior si existía
        if (_currentImagePath != null) {
          await _imageService.deleteImage(_currentImagePath!);
        }
      } else if (_deleteCurrentImage) {
        // Eliminar imagen actual
        if (_currentImagePath != null) {
          await _imageService.deleteImage(_currentImagePath!);
        }
        finalImagePath = null;
      } else {
        // Mantener imagen actual
        finalImagePath = _currentImagePath;
      }

      // Actualizar producto
      await db.productDao.updateProduct(
        widget.product.id,
        ProductsCompanion(
          name: drift.Value(name),
          price: drift.Value(price),
          category: drift.Value(_selectedCategory),
          subcategory: drift.Value(_selectedSubcategory),
          description: drift.Value(description.isEmpty ? null : description),
          imagePath: drift.Value(finalImagePath), // ✅ Actualizar ruta de imagen
        ),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Producto actualizado exitosamente'),
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