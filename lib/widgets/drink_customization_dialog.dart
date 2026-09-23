import 'package:flutter/material.dart';

class DrinkCustomizationDialog extends StatefulWidget {
  final String productName;
  final double basePrice;
  final String subcategory;

  const DrinkCustomizationDialog({
    super.key,
    required this.productName,
    required this.basePrice,
    required this.subcategory,
  });

  @override
  State<DrinkCustomizationDialog> createState() => _DrinkCustomizationDialogState();
}

class _DrinkCustomizationDialogState extends State<DrinkCustomizationDialog> {
  // LÓGICA DE BASES
  String _selectedBase = 'Tapioca';
  bool _extraTapioca = false;
  bool _extraPerlas = false;

  // LÓGICA TISANAS
  String _preparacionTisana = 'Frío';

  // LÓGICA CHAMOYADAS (ADEREZOS)
  final Map<String, bool> _chamoyadaExtras = {
    'Chile': true,
    'Chamoy': true,
    'Tajín': true,
    'Miguelito': true,
  };

  @override
  void initState() {
    super.initState();
    // Configuración inicial por defecto según subcategoría
    if (widget.subcategory == 'Soda Italiana') {
      _selectedBase = 'Perlas';
    }
  }

  double get _currentPrice {
    double total = widget.basePrice;
    if (_extraTapioca) total += 10;
    if (_extraPerlas) total += 10;
    return total;
  }

  List<String> get _selectedModifiers {
    final List<String> mods = [];

    // 1. Base
    mods.add("Base: $_selectedBase");

    // 2. Preparación (Solo Tisanas)
    if (widget.subcategory == 'Tisana') {
      mods.add("Prep: $_preparacionTisana");
    }

    // 3. Aderezos (Solo Chamoyadas)
    if (widget.subcategory == 'Chamoyada') {
      final selectedChamoy = _chamoyadaExtras.entries
          .where((e) => e.value)
          .map((e) => e.key)
          .toList();
      if (selectedChamoy.isNotEmpty) {
        mods.add("Aderezos: ${selectedChamoy.join(', ')}");
      }
    }

    // 4. Extras
    if (_extraTapioca) mods.add("Extra Tapioca (+\$10)");
    if (_extraPerlas) mods.add("Extra Perlas (+\$10)");

    return mods;
  }

  @override
  Widget build(BuildContext context) {
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);

    return AlertDialog(
      backgroundColor: const Color(0xFF000F4D),
      contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10), // Reducido
      insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 20), // Reducido
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
        side: const BorderSide(color: nexusYellow, width: 2),
      ),
      title: Column(
        children: [
          Text(
            widget.productName.toUpperCase(),
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 20), // Un poco más pequeño
          ),
          Text(
            widget.subcategory,
            style: const TextStyle(color: nexusYellow, fontSize: 13, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SizedBox(
        width: 450,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: Colors.white24, height: 10), // Menos altura

              // --- SECCIÓN: PREPARACIÓN (Solo Tisanas) ---
              if (widget.subcategory == 'Tisana') ...[
                _buildSectionTitle("PREPARACIÓN"),
                Row( // En fila para ahorrar espacio vertical
                  children: [
                    Expanded(child: _buildRadioOption("Frío", _preparacionTisana, (val) => setState(() => _preparacionTisana = val!))),
                    Expanded(child: _buildRadioOption("Caliente", _preparacionTisana, (val) => setState(() => _preparacionTisana = val!))),
                    Expanded(child: _buildRadioOption("Frappeado", _preparacionTisana, (val) => setState(() => _preparacionTisana = val!))),
                  ],
                ),
                const SizedBox(height: 10),
              ],

              // --- SECCIÓN: ADEREZOS (Solo Chamoyadas) ---
              if (widget.subcategory == 'Chamoyada') ...[
                _buildSectionTitle("ADEREZOS (GRATIS)"),
                Wrap(
                  spacing: 10,
                  runSpacing: 0, // Pegados verticalmente
                  children: _chamoyadaExtras.keys.map((key) {
                    return SizedBox(
                      width: 130, // Ancho fijo para 3 por fila aprox
                      child: _buildLargeCheckbox(
                        label: key,
                        value: _chamoyadaExtras[key]!,
                        onChanged: (val) => setState(() => _chamoyadaExtras[key] = val!),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 10),
              ],

              // --- SECCIÓN: BASE (Tapioca/Perlas) ---
              if (widget.subcategory != 'Soda Italiana') ...[
                _buildSectionTitle("BASE"),
                Row(
                  children: [
                    Expanded(child: _buildRadioOption("Tapioca", _selectedBase, (val) => setState(() => _selectedBase = val!))),
                    Expanded(child: _buildRadioOption("Perlas", _selectedBase, (val) => setState(() => _selectedBase = val!))),
                  ],
                ),
              ] else ...[
                _buildSectionTitle("BASE"),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 4),
                  child: Text("• Perlas Explosivas", style: TextStyle(color: Colors.white70, fontSize: 14)),
                ),
              ],

              const SizedBox(height: 10),

              // --- SECCIÓN: EXTRAS ---
              _buildSectionTitle("EXTRAS (+\$10)"),
              Row( // En fila para ahorrar espacio vertical
                children: [
                  Expanded(
                    child: _buildLargeCheckbox(
                      label: "Extra Tapioca",
                      value: _extraTapioca,
                      onChanged: (val) => setState(() => _extraTapioca = val!),
                      showPrice: false,
                    ),
                  ),
                  Expanded(
                    child: _buildLargeCheckbox(
                      label: "Extra Perlas",
                      value: _extraPerlas,
                      onChanged: (val) => setState(() => _extraPerlas = val!),
                      showPrice: false,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 15),

              // --- TOTAL ---
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: nexusBlue.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("TOTAL:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    Text("\$${_currentPrice.toStringAsFixed(2)}", style: const TextStyle(color: nexusYellow, fontWeight: FontWeight.w900, fontSize: 22)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 15), // Reducido
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("CANCELAR", style: TextStyle(color: Colors.white54, fontWeight: FontWeight.bold)),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: nexusYellow,
            padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            Navigator.pop(context, {
              'modifiers': _selectedModifiers,
              'finalPrice': _currentPrice,
            });
          },
          child: const Text(
            "AGREGAR",
            style: TextStyle(color: nexusBlue, fontWeight: FontWeight.w900, fontSize: 18),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFFFFDE00), fontWeight: FontWeight.bold, fontSize: 16, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildRadioOption(String value, String groupValue, ValueChanged<String?> onChanged) {
    return RadioListTile<String>(
      title: Text(value, style: const TextStyle(color: Colors.white, fontSize: 16)),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: const Color(0xFFFFDE00),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildLargeCheckbox({
    required String label,
    required bool value,
    required ValueChanged<bool?> onChanged,
    bool showPrice = false,
  }) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 16)),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFFFFDE00),
      checkColor: const Color(0xFF00187A),
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
      secondary: showPrice ? const Text("+\$10", style: TextStyle(color: Colors.white54, fontSize: 14)) : null,
    );
  }
}
