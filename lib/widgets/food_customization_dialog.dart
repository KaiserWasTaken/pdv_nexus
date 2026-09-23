import 'package:flutter/material.dart';

class FoodCustomizationDialog extends StatefulWidget {
  final String productName;
  final double basePrice;
  final String subcategory;

  const FoodCustomizationDialog({
    super.key,
    required this.productName,
    required this.basePrice,
    required this.subcategory,
  });

  @override
  State<FoodCustomizationDialog> createState() => _FoodCustomizationDialogState();
}

class _FoodCustomizationDialogState extends State<FoodCustomizationDialog> {
  // --- ESTADO GENERAL ---
  bool _nexuletaExtraQuesoGlobal = false;

  // --- ESTADO MINI HOT CAKES ---
  String _selectedSyrup = 'Maple';
  final Map<String, bool> _toppings = {
    'Mazapán': false,
    'Confeti': false,
    'Chispas Chocolate': false,
    'Oreo': false,
    'Nuez': false,
    'Almendras': false,
    'Arándano': false,
    'M&Ms': false,
    'Bombones': false,
    'Coco Rallado': false,
  };

  // --- ESTADO NEXULETAS ---
  late List<NexuletaConfig> _nexuletaConfigs;

  // --- ESTADO NACHOS ---
  bool _nachosExtraQueso = false;
  bool _nachosExtraChile = false;
  String _nachosConsumo = 'Consumir aquí';

  // --- ESTADO PALOMITAS ---
  String _palomitasSabor = 'Mantequilla';

  // --- ESTADO MARUCHAN ---
  String _maruchanChile = 'Chile Piquín';

  @override
  void initState() {
    super.initState();
    _initNexuletas();
  }

  void _initNexuletas() {
    int count = 1;
    if (widget.productName.contains('2')) count = 2;
    if (widget.productName.contains('3')) count = 3;
    _nexuletaConfigs = List.generate(count, (index) => NexuletaConfig(index + 1));
  }

  double get _totalPrice {
    double extra = 0;

    if (widget.subcategory == 'Mini Hot Cakes') {
      int selectedToppings = _toppings.values.where((v) => v).length;
      if (selectedToppings > 2) {
        extra += (selectedToppings - 2) * 5.0;
      }
    } else if (widget.subcategory == 'Nexuleta') {
      if (_nexuletaExtraQuesoGlobal) extra += 10.0;
    } else if (widget.subcategory == 'Nachos') {
      if (_nachosExtraQueso) extra += 10.0;
      if (_nachosExtraChile) extra += 5.0;
    } else if (widget.subcategory == 'Palomitas') {
      if (_palomitasSabor != 'Mantequilla') {
        if (widget.productName.contains('Mediana')) extra += 5.0;
      }
    }

    return widget.basePrice + extra;
  }

  List<String> _buildModifiers() {
    final List<String> mods = [];

    if (widget.subcategory == 'Mini Hot Cakes') {
      mods.add("Jarabe: $_selectedSyrup");
      final selectedT = _toppings.entries.where((e) => e.value).map((e) => e.key).toList();
      if (selectedT.isNotEmpty) mods.add("Toppings: ${selectedT.join(', ')}");
    } else if (widget.subcategory == 'Nexuleta') {
      for (var config in _nexuletaConfigs) {
        String filling = config.relleno;
        String powder = config.polvo == 'Ninguno' ? 'sin polvo' : config.polvo.toLowerCase();
        
        String nexuletaMod = "${config.id}: $filling, $powder";
        
        // Añadir aderezos faltantes individualmente con "sin"
        final missingDressings = config.aderezos.entries
            .where((e) => !e.value)
            .map((e) => "sin ${e.key.toLowerCase()}")
            .toList();
            
        if (missingDressings.isNotEmpty) {
          nexuletaMod += ", ${missingDressings.join(', ')}";
        }
        
        mods.add(nexuletaMod);
      }
      if (_nexuletaExtraQuesoGlobal) mods.add("CON QUESO DERRETIDO");
    } else if (widget.subcategory == 'Nachos') {
      mods.add(_nachosConsumo);
      if (_nachosExtraQueso) mods.add("Extra Queso (+\$10)");
      if (_nachosExtraChile) mods.add("Extra Chile (+\$5)");
    } else if (widget.subcategory == 'Palomitas') {
      mods.add("Sabor: $_palomitasSabor");
    } else if (widget.subcategory == 'Maruchan') {
      mods.add("Con: $_maruchanChile");
    }

    return mods;
  }

  @override
  Widget build(BuildContext context) {
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);

    return AlertDialog(
      backgroundColor: const Color(0xFF000F4D),
      contentPadding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24), side: const BorderSide(color: nexusYellow, width: 2)),
      title: Column(
        children: [
          Text(widget.productName.toUpperCase(), textAlign: TextAlign.center, 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 24)), // Aumentado a 24
          Text(widget.subcategory, style: const TextStyle(color: nexusYellow, fontSize: 16, fontWeight: FontWeight.bold)), // Aumentado a 16
        ],
      ),
      content: SizedBox(
        width: 550, // Un poco más ancho
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Divider(color: Colors.white24, height: 10),
              _buildContentBySubcategory(),
              const SizedBox(height: 20),
              _buildTotalSection(),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text("CANCELAR", 
          style: TextStyle(color: Colors.white54, fontSize: 18, fontWeight: FontWeight.bold))),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: nexusYellow, 
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 15),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))
          ),
          onPressed: () => Navigator.pop(context, {'modifiers': _buildModifiers(), 'finalPrice': _totalPrice}),
          child: const Text("AGREGAR", style: TextStyle(color: nexusBlue, fontWeight: FontWeight.w900, fontSize: 20)),
        ),
      ],
    );
  }

  Widget _buildContentBySubcategory() {
    switch (widget.subcategory) {
      case 'Mini Hot Cakes': return _buildHotCakesView();
      case 'Nexuleta': return _buildNexuletaView();
      case 'Nachos': return _buildNachosView();
      case 'Palomitas': return _buildPalomitasView();
      case 'Maruchan': return _buildMaruchanView();
      default: return const Text("Sin opciones", style: TextStyle(color: Colors.white54, fontSize: 18));
    }
  }

  // --- VISTAS ESPECÍFICAS ---

  Widget _buildHotCakesView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("JARABE (ELIGE 1)"),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: ['Maple', 'Caramelo', 'Nutella', 'Lechera', 'Cajeta', 'Ninguno'].map((s) => ChoiceChip(
            label: Text(s, style: const TextStyle(fontSize: 16)),
            selected: _selectedSyrup == s,
            onSelected: (val) => setState(() => _selectedSyrup = s),
            selectedColor: const Color(0xFFFFDE00),
            labelStyle: TextStyle(color: _selectedSyrup == s ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
          )).toList(),
        ),
        const SizedBox(height: 25),
        _buildSectionTitle("TOPPINGS (2 INCLUIDOS)"),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: _toppings.keys.map((t) => FilterChip(
            label: Text(t, style: const TextStyle(fontSize: 16)),
            selected: _toppings[t]!,
            onSelected: (val) => setState(() => _toppings[t] = val),
            selectedColor: const Color(0xFFFFDE00),
            labelStyle: TextStyle(color: _toppings[t]! ? Colors.black : Colors.white, fontWeight: FontWeight.bold),
          )).toList(),
        ),
      ],
    );
  }

  Widget _buildNexuletaView() {
    return Column(
      children: [
        ..._nexuletaConfigs.map((config) {
          return Card(
            color: Colors.white.withOpacity(0.05),
            margin: const EdgeInsets.only(bottom: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: const BorderSide(color: Colors.white10)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("BANDERILLA #${config.id}", style: const TextStyle(color: Color(0xFFFFDE00), fontWeight: FontWeight.w900, fontSize: 20)),
                  const SizedBox(height: 12),
                  const Text("RELLENO:", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                  Row(
                    children: ['Mixta', 'Queso', 'Salchicha'].map((r) => Expanded(
                      child: RadioListTile<String>(
                        title: Text(r, style: const TextStyle(fontSize: 14, color: Colors.white, fontWeight: FontWeight.bold)),
                        value: r, groupValue: config.relleno, dense: true, contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => config.relleno = val!),
                        activeColor: const Color(0xFFFFDE00),
                      ),
                    )).toList(),
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  const Text("ADEREZOS:", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                  Row(
                    children: config.aderezos.keys.map((a) => Expanded(
                      child: CheckboxListTile(
                        title: Text(a, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                        value: config.aderezos[a], dense: true, contentPadding: EdgeInsets.zero, controlAffinity: ListTileControlAffinity.leading,
                        onChanged: (val) => setState(() => config.aderezos[a] = val!),
                        activeColor: const Color(0xFFFFDE00),
                        checkColor: Colors.black,
                      ),
                    )).toList(),
                  ),
                  const Divider(color: Colors.white10, height: 20),
                  const Text("POLVO:", style: TextStyle(color: Colors.white70, fontSize: 14, fontWeight: FontWeight.bold)),
                  Wrap(
                    children: ['Flamin', 'Takis', 'Cheddar', 'Ninguno'].map((p) => SizedBox(
                      width: 130,
                      child: RadioListTile<String>(
                        title: Text(p, style: const TextStyle(fontSize: 13, color: Colors.white, fontWeight: FontWeight.bold)),
                        value: p, groupValue: config.polvo, dense: true, contentPadding: EdgeInsets.zero,
                        onChanged: (val) => setState(() => config.polvo = val!),
                        activeColor: const Color(0xFFFFDE00),
                      ),
                    )).toList(),
                  ),
                ],
              ),
            ),
          );
        }),
        const SizedBox(height: 10),
        // OPCIÓN GLOBAL DE QUESO
        Container(
          decoration: BoxDecoration(
            color: const Color(0xFFFFDE00).withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFFFDE00), width: 2),
          ),
          child: CheckboxListTile(
            title: const Text("QUESO DERRETIDO", style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.w900)),
            subtitle: const Text("\$10.00", style: TextStyle(color: Color(0xFFFFDE00), fontWeight: FontWeight.bold)),
            value: _nexuletaExtraQuesoGlobal,
            onChanged: (val) => setState(() => _nexuletaExtraQuesoGlobal = val!),
            activeColor: const Color(0xFFFFDE00),
            checkColor: Colors.black,
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ],
    );
  }

  Widget _buildNachosView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("¿DÓNDE SE CONSUME?"),
        _buildRadioOption("Consumir aquí", _nachosConsumo, (val) => setState(() => _nachosConsumo = val!)),
        _buildRadioOption("Para llevar", _nachosConsumo, (val) => setState(() => _nachosConsumo = val!)),
        const SizedBox(height: 20),
        _buildSectionTitle("EXTRAS"),
        _buildLargeCheckbox("Queso Extra (+\$10)", _nachosExtraQueso, (val) => setState(() => _nachosExtraQueso = val!)),
        _buildLargeCheckbox("Chile Extra (+\$5)", _nachosExtraChile, (val) => setState(() => _nachosExtraChile = val!)),
      ],
    );
  }

  Widget _buildPalomitasView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("ELAN EL SABOR"),
        ...['Mantequilla', 'Cheddar', 'Takis Fuego', 'Flamin Hot'].map((s) => _buildRadioOption(s, _palomitasSabor, 
          (val) => setState(() => _palomitasSabor = val!))).toList(),
      ],
    );
  }

  Widget _buildMaruchanView() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle("TIPO DE CHILE"),
        _buildRadioOption("Chile Piquín", _maruchanChile, (val) => setState(() => _maruchanChile = val!)),
        _buildRadioOption("Habanero", _maruchanChile, (val) => setState(() => _maruchanChile = val!)),
      ],
    );
  }

  // --- HELPERS DE UI CON FUENTES GRANDES ---

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        title,
        style: const TextStyle(color: Color(0xFFFFDE00), fontWeight: FontWeight.w900, fontSize: 20, letterSpacing: 1.1),
      ),
    );
  }

  Widget _buildRadioOption(String value, String groupValue, ValueChanged<String?> onChanged) {
    return RadioListTile<String>(
      title: Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      value: value,
      groupValue: groupValue,
      onChanged: onChanged,
      activeColor: const Color(0xFFFFDE00),
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildLargeCheckbox(String label, bool value, ValueChanged<bool?> onChanged) {
    return CheckboxListTile(
      title: Text(label, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
      value: value,
      onChanged: onChanged,
      activeColor: const Color(0xFFFFDE00),
      checkColor: Colors.black,
      controlAffinity: ListTileControlAffinity.leading,
      dense: true,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildTotalSection() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: const Color(0xFF00187A).withOpacity(0.5), borderRadius: BorderRadius.circular(16)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text("TOTAL A COBRAR:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 20)),
          Text("\$${_totalPrice.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFFFDE00), fontWeight: FontWeight.w900, fontSize: 32)),
        ],
      ),
    );
  }
}

class NexuletaConfig {
  final int id;
  String relleno = 'Mixta';
  String polvo = 'Ninguno';
  Map<String, bool> aderezos = {'Catsup': true, 'Mayo': true, 'Mostaza': true};

  NexuletaConfig(this.id);

  String getMissingDressings() {
    final missing = aderezos.entries.where((e) => !e.value).map((e) => e.key).toList();
    return missing.isEmpty ? "Ninguno" : missing.join(', ');
  }
}
