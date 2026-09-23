import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:drift/drift.dart' as drift;
import '../database/database.dart';

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

  late String _productType;
  late String _selectedCategory;
  String? _selectedSubcategory;

  // Lista de items que componen el combo
  List<Map<String, dynamic>> _comboItems = []; 

  final Map<String, List<String>> _subcategories = {
    'Bebidas': [
      'Bubble Tea Base Leche',
      'Bubble Tea Base Agua',
      'Soda Italiana',
      'Tisana',
      'Chamoyada',
      'Otros',
    ],
    'Comidas': [
      'Nexuleta',
      'Nachos',
      'Mini Hot Cakes',
      'Palomitas',
      'Otros Snacks',
    ],
    'Combos': [
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
    
    if (_productType == 'paquete') {
      _loadComboItems();
    }
  }

  Future<void> _loadComboItems() async {
    final db = context.read<AppDatabase>();
    final items = await db.productDao.getPackageItems(widget.product.id);
    setState(() {
      _comboItems = List<Map<String, dynamic>>.from(items);
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _showProductPicker() async {
    final db = context.read<AppDatabase>();
    final allProducts = await db.productDao.getActiveProducts();

    if (!mounted) return;

    String? currentCat;
    String? currentSub;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setPickerState) {
          List<Widget> content = [];

          if (currentCat == null) {
            final cats = [
              {'name': 'Bebidas', 'icon': Icons.local_drink},
              {'name': 'Comidas', 'icon': Icons.fastfood},
              {'name': 'Rentas', 'icon': Icons.videogame_asset},
            ];
            
            content = cats.map((c) => ListTile(
              leading: Icon(c['icon'] as IconData, color: Colors.white),
              title: Text(c['name'] as String, style: const TextStyle(color: Colors.white)),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white24),
              onTap: () => setPickerState(() => currentCat = c['name'] as String),
            )).toList();

          } else if (currentCat == 'Rentas') {
            content = [
              _buildPickerItem(
                name: "1 Hora de Juego (Cualquier Consola)",
                cat: 'Rentas',
                isPlaceholder: true,
                onSelected: (item) {
                  setState(() => _comboItems.add(item));
                  Navigator.pop(ctx);
                },
              ),
              _buildPickerItem(
                name: "30 Minutos de Juego",
                cat: 'Rentas',
                isPlaceholder: true,
                onSelected: (item) {
                  setState(() => _comboItems.add(item));
                  Navigator.pop(ctx);
                },
              ),
            ];
          } else if (currentSub == null) {
            final subs = _subcategories[currentCat!] ?? [];
            content = [
              if (currentCat == 'Bebidas')
                _buildPickerItem(
                  name: "Bebida Libre (Cualquiera)",
                  cat: 'Bebidas',
                  isPlaceholder: true,
                  onSelected: (item) {
                    setState(() => _comboItems.add(item));
                    Navigator.pop(ctx);
                  },
                ),

              ...subs.map((s) => ListTile(
                title: Text(s, style: const TextStyle(color: Colors.white)),
                onTap: () => setPickerState(() => currentSub = s),
              )),
            ];
          } else {
            final products = allProducts.where((p) => p.category == currentCat && p.subcategory == currentSub).toList();
            content = products.map((p) => _buildPickerItem(
              name: p.name,
              productId: p.id,
              cat: currentCat!,
              isPlaceholder: false,
              onSelected: (item) {
                setState(() => _comboItems.add(item));
                Navigator.pop(ctx);
              },
            )).toList();
          }

          return AlertDialog(
            backgroundColor: const Color(0xFF000F4D),
            title: Row(
              children: [
                if (currentCat != null)
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white70),
                    onPressed: () => setPickerState(() {
                      if (currentSub != null) currentSub = null;
                      else currentCat = null;
                    }),
                  ),
                Text(currentSub ?? currentCat ?? "AÑADIR AL COMBO", style: const TextStyle(color: Colors.white)),
              ],
            ),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(shrinkWrap: true, children: content),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPickerItem({
    required String name,
    int? productId,
    required String cat,
    required bool isPlaceholder,
    required Function(Map<String, dynamic>) onSelected,
  }) {
    return ListTile(
      title: Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      subtitle: Text(isPlaceholder ? "Espacio configurable" : "Producto fijo"),
      trailing: const Icon(Icons.add_circle, color: Color(0xFFFFDE00)),
      onTap: () => onSelected({
        'productId': productId,
        'name': name,
        'quantity': 1,
        'isPlaceholder': isPlaceholder,
        'category': cat,
      }),
    );
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

            Expanded(
              child: SingleChildScrollView(
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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

                      if (_productType == 'paquete') ...[
                        const Divider(color: Colors.white24, height: 40),
                        const Text(
                          "CONTENIDO DEL COMBO",
                          style: TextStyle(
                            color: nexusYellow,
                            fontSize: 18,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 12),
                        
                        if (_comboItems.isEmpty)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 20),
                            child: Center(
                              child: Text(
                                "El combo está vacío.\nAñade productos o espacios libres.",
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.white24),
                              ),
                            ),
                          )
                        else
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _comboItems.length,
                            itemBuilder: (context, index) {
                              final item = _comboItems[index];
                              return Card(
                                color: Colors.white.withOpacity(0.05),
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  leading: Icon(
                                    item['isPlaceholder'] ? Icons.help_outline : Icons.check_circle,
                                    color: item['isPlaceholder'] ? nexusYellow : Colors.greenAccent,
                                  ),
                                  title: Text(
                                    item['name'],
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                  ),
                                  subtitle: Text(
                                    "Cantidad: ${item['quantity']} • ${item['category']}",
                                    style: const TextStyle(color: Colors.white60),
                                  ),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.redAccent, size: 20),
                                    onPressed: () => setState(() => _comboItems.removeAt(index)),
                                  ),
                                ),
                              );
                            },
                          ),

                        const SizedBox(height: 10),

                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _showProductPicker,
                            icon: const Icon(Icons.add_circle_outline),
                            label: const Text("AÑADIR PRODUCTO / ESPACIO LIBRE"),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: nexusYellow,
                              side: const BorderSide(color: nexusYellow, width: 2),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30),
                      ],

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
                          items: ['Bebidas', 'Comidas'].map((category) {
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

                      _buildTextField(
                        controller: _descriptionController,
                        label: "Descripción (Opcional)",
                        hint: "Ej: Cremoso bubble tea con perlas de tapioca",
                        maxLines: 3,
                      ),

                      const SizedBox(height: 40),

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
      String description = _descriptionController.text.trim();

      // Generar descripción automática para combos si está vacía
      if (_productType == 'paquete' && description.isEmpty) {
        description = _comboItems.map((item) => "${item['quantity']}x ${item['name']}").join(" + ");
      }

      await db.productDao.updateProduct(
        widget.product.id,
        ProductsCompanion(
          name: drift.Value(name),
          price: drift.Value(price),
          category: drift.Value(_selectedCategory),
          subcategory: drift.Value(_selectedSubcategory),
          description: drift.Value(description.isEmpty ? null : description),
        ),
      );

      if (_productType == 'paquete') {
        await db.productDao.setEligibleDrinksForCombo(widget.product.id, []); // Limpiar viejo
        // En este caso, deberíamos tener un DAO que actualice los items del paquete
        // Por ahora, actualicemos solo los metadatos. 
        // Nota: El sistema de items dinámicos necesita que se actualice la tabla PackageItems.
        // Implementemos esa lógica en el DAO.
        await db.productDao.updatePackageItems(widget.product.id, _comboItems);
      }

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
