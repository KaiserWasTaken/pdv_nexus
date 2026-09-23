import 'package:flutter/material.dart';
import '../database/database.dart';

class ComboDrinkDialog extends StatelessWidget {
  final List<Product> eligibleDrinks;
  final String comboName;

  const ComboDrinkDialog({
    super.key,
    required this.eligibleDrinks,
    required this.comboName,
  });

  @override
  Widget build(BuildContext context) {
    const nexusYellow = Color(0xFFFFDE00);
    const nexusBlue = Color(0xFF00187A);

    return Dialog(
      backgroundColor: const Color(0xFF000F4D),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: nexusYellow, width: 2),
      ),
      child: Container(
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.8,
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ENCABEZADO COMPACTO
            Row(
              children: [
                const Icon(Icons.local_drink, color: nexusYellow, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "ELIGE TU BEBIDA",
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 18),
                      ),
                      Text(
                        comboName.toUpperCase(),
                        style: const TextStyle(color: nexusYellow, fontSize: 12, fontWeight: FontWeight.bold),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: Colors.white54),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const Divider(color: Colors.white24, height: 20),
            
            // LISTA DE BEBIDAS (GRID PARA MEJOR ESPACIO)
            Flexible(
              child: eligibleDrinks.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.all(20.0),
                      child: Text(
                        "No hay bebidas configuradas.",
                        style: TextStyle(color: Colors.white70),
                      ),
                    )
                  : GridView.builder(
                      shrinkWrap: true,
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        crossAxisSpacing: 10,
                        mainAxisSpacing: 10,
                        childAspectRatio: 2.5,
                      ),
                      itemCount: eligibleDrinks.length,
                      itemBuilder: (context, index) {
                        final drink = eligibleDrinks[index];
                        return InkWell(
                          onTap: () => Navigator.pop(context, drink.name),
                          borderRadius: BorderRadius.circular(12),
                          child: Container(
                            decoration: BoxDecoration(
                              color: nexusBlue.withOpacity(0.4),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.white10),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            alignment: Alignment.center,
                            child: Text(
                              drink.name,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
