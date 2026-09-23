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

  String _productType = 'simple';
  String _selectedCategory = 'Bebidas';
  String? _selectedSubcategory;
  
  // ✅ Lista de items que componen el combo
  final List<Map<String, dynamic>> _comboItems = []; 

  // Subcategorías por categoría
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
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  // ========================================
  // LÓGICA DEL SELECTOR DE PRODUCTOS PARA COMBO
  // ========================================
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
                      Row(
                        children: [
                          Expanded(
                            child: _TypeButton(
                              label: "Producto Simple",
                              icon: Icons.inventory_2,
                              isSelected: _productType == 'simple',
                              onTap: () {
                                setState(() {
                                  _productType = 'simple';
                                  _selectedCategory = 'Bebidas';
                                  _selectedSubcategory = null;
                                });
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
                                  _selectedCategory = 'Combos';
                                  _selectedSubcategory = null;
                                });
                              },
                            ),
                          ),
                        ],
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
      String description = _descriptionController.text.trim();

      if (_productType == 'simple') {
        await db.productDao.insertProduct(
          name: name,
          price: price,
          category: _selectedCategory,
          subcategory: _selectedSubcategory,
          description: description.isEmpty ? null : description,
        );
      } else {
        // Generar descripción automática si está vacía para mostrar en la tarjeta
        if (description.isEmpty) {
          description = _comboItems.map((item) => "${item['quantity']}x ${item['name']}").join(" + ");
        }

        await db.productDao.insertPackage(
          name: name,
          price: price,
          description: description,
          items: _comboItems,
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
