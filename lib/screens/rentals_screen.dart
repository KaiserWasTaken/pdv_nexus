import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../database/database.dart';
import '../providers/cart_provider.dart';
import '../providers/rental_provider.dart';

class RentalsScreen extends StatefulWidget {
  const RentalsScreen({super.key});

  @override
  State<RentalsScreen> createState() => _RentalsScreenState();
}

class _RentalsScreenState extends State<RentalsScreen> {
  final List<Map<String, dynamic>> _consoles = [
    {'name': 'Switch 1', 'type': 'Nintendo Switch', 'icon': Icons.sports_esports},
    {'name': 'Switch 2', 'type': 'Nintendo Switch', 'icon': Icons.sports_esports},
    {'name': 'Xbox A', 'type': 'Xbox Series S', 'icon': Icons.videogame_asset},
    {'name': 'Xbox B', 'type': 'Xbox Series S', 'icon': Icons.videogame_asset},
    {'name': 'Xbox C', 'type': 'Xbox Series S', 'icon': Icons.videogame_asset},
    {'name': 'Xbox D', 'type': 'Xbox Series S', 'icon': Icons.videogame_asset},
    {'name': 'PS5', 'type': 'PlayStation 5', 'icon': Icons.gamepad},
  ];

  @override
  Widget build(BuildContext context) {
    final rentalProvider = context.watch<RentalProvider>();
    final activeRentals = rentalProvider.activeRentals;

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "CENTRO DE RENTAS",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.2),
              ),
              // BOTÓN SECRETO DEV (Solo icono pequeño)
              IconButton(
                icon: Icon(Icons.bug_report, color: rentalProvider.isDevMode ? Colors.orange : Colors.white10),
                onPressed: () => rentalProvider.toggleDevMode(),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Expanded(
// ...
            child: GridView.builder(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                childAspectRatio: 1.1,
              ),
              itemCount: _consoles.length,
              itemBuilder: (context, index) {
                final console = _consoles[index];
                final activeRental = activeRentals.where((r) => r.consoleName == console['name']).firstOrNull;
                return _ConsoleCard(
                  name: console['name'],
                  type: console['type'],
                  icon: console['icon'],
                  activeRental: activeRental,
                  onTap: () => _handleConsoleTap(console, activeRental),
                );
              },
            ),
          ),

          const SizedBox(height: 16),

          // ✅ NUEVO: BOTÓN PARA VENDER CONTROL EXTRA SOLO
          SizedBox(
            width: double.infinity,
            height: 70,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00187A),
                foregroundColor: const Color(0xFFFFDE00),
                side: const BorderSide(color: Color(0xFFFFDE00), width: 2),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: () => _showExtraControllerDialog(),
              icon: const Icon(Icons.sports_esports, size: 32),
              label: const Text(
                "CONTROL EXTRA (\$15.00)",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showExtraControllerDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF00187A),
        title: const Text("Control Extra", style: TextStyle(color: Colors.white)),
        content: const Text("¿Deseas añadirlo al carrito o cobrarlo ahora mismo?",
            style: TextStyle(color: Colors.white70)),
        actions: [
          TextButton(
            onPressed: () {
              final cart = context.read<CartProvider>();
              cart.addItem(
                "Control Extra", 
                15.0, 
                category: 'Rentas', // ✅ Categoría correcta
                type: CartItemType.rental
              );
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text("Control extra añadido al carrito"), backgroundColor: Colors.blue),
              );
              Navigator.pop(ctx);
            },
            child: const Text("AÑADIR AL CARRITO", style: TextStyle(color: Color(0xFFFFDE00))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              final db = context.read<AppDatabase>();
              // Registrar venta inmediata
              await db.orderDao.insertOrder(
                "Control Extra (Venta rápida)",
                15.0,
                1,
                category: 'Rentas',
                date: DateTime.now(),
              );
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Venta de control registrada"), backgroundColor: Colors.green),
                );
                Navigator.of(context).pop();
              }
            },
            child: const Text("COBRAR (\$15)"),
          ),
        ],
      ),
    );
  }

  void _handleConsoleTap(Map<String, dynamic> console, Rental? activeRental) {
    if (activeRental == null) {
      _showStartRentalDialog(console['name']);
    } else {
      _showRentalOptionsDialog(activeRental);
    }
  }

  void _showStartRentalDialog(String consoleName) {
    int selectedMinutes = 60;
    int extraControllers = 0;
    final rentalProvider = context.read<RentalProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => AlertDialog(
          backgroundColor: const Color(0xFF00187A),
          title: Text("Venta: $consoleName", style: const TextStyle(color: Colors.white)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text("Tiempo deseado:", style: TextStyle(color: Colors.white70)),
                DropdownButton<int>(
                  value: selectedMinutes,
                  dropdownColor: const Color(0xFF000F4D),
                  items: [30, 60, 90, 120, 180].map((m) {
                    return DropdownMenuItem(value: m, child: Text("$m min", style: const TextStyle(color: Colors.white)));
                  }).toList(),
                  onChanged: (val) => setDialogState(() => selectedMinutes = val!),
                ),
                const SizedBox(height: 20),
                const Text("Controles adicionales (+15 c/u):", style: TextStyle(color: Colors.white70)),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.remove_circle, color: Colors.red),
                      onPressed: extraControllers > 0 ? () => setDialogState(() => extraControllers--) : null,
                    ),
                    Text("$extraControllers", style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                    IconButton(
                      icon: const Icon(Icons.add_circle, color: Colors.green),
                      onPressed: extraControllers < 3 ? () => setDialogState(() => extraControllers++) : null,
                    ),
                  ],
                ),
                const Divider(color: Colors.white24, height: 30),
                Text(
                  "A PAGAR: \$${rentalProvider.calculateCostForTime(selectedMinutes, extraControllers, isExtension: false).toStringAsFixed(0)}",
                  style: const TextStyle(color: Color(0xFFFFDE00), fontSize: 22, fontWeight: FontWeight.w900),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFFDE00)),
              onPressed: () {
                final cart = context.read<CartProvider>();
                final price = rentalProvider.calculateCostForTime(selectedMinutes, extraControllers, isExtension: false);
                
                cart.addRentalItem(
                  consoleName: consoleName,
                  minutes: selectedMinutes,
                  extraControllers: extraControllers,
                  price: price,
                );

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text("$consoleName añadido al carrito"), backgroundColor: Colors.blue),
                );
                Navigator.of(context).pop();
              },
              child: const Text("AÑADIR AL CARRITO", style: TextStyle(color: Color(0xFF00187A), fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showRentalOptionsDialog(Rental rental) {
    final rentalProvider = context.read<RentalProvider>();
    
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF00187A),
        title: Text(rental.consoleName, style: const TextStyle(color: Colors.white)),
        content: const Text("Gestión de renta activa", style: TextStyle(color: Colors.white70)),
        actions: [
          if (rentalProvider.isDevMode)
            TextButton(
              onPressed: () async {
                await rentalProvider.forceFinishTime(rental.id);
                Navigator.pop(ctx);
              },
              child: const Text("DEV: TERMINAR YA", style: TextStyle(color: Colors.orange)),
            ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showAddExtraTimeDialog(rental);
            },
            child: const Text("AÑADIR TIEMPO (COBRO)", style: TextStyle(color: Color(0xFFFFDE00))),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(ctx);
              _showFinishRentalConfirm(rental);
            },
            child: const Text("DETENER Y LIBERAR"),
          ),
        ],
      ),
    );
  }

  void _showAddExtraTimeDialog(Rental rental) {
    int extraMin = 30;
    final rentalProvider = context.read<RentalProvider>();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDS) => AlertDialog(
          backgroundColor: const Color(0xFF00187A),
          title: const Text("Venta de Tiempo Extra"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButton<int>(
                  value: extraMin,
                  dropdownColor: const Color(0xFF000F4D),
                  items: [15, 30, 60, 120].map((m) => DropdownMenuItem(value: m, child: Text("$m min", style: const TextStyle(color: Colors.white)))).toList(),
                  onChanged: (val) => setDS(() => extraMin = val!),
                ),
                const SizedBox(height: 20),
                Text(
                  "A COBRAR: \$${rentalProvider.calculateCostForTime(extraMin, 0, isExtension: true).toStringAsFixed(0)}",
                  style: const TextStyle(color: Color(0xFFFFDE00), fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("VOLVER")),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: () async {
                final db = context.read<AppDatabase>();
                final currentEnd = rental.expectedEndTime ?? DateTime.now();
                final cost = rentalProvider.calculateCostForTime(extraMin, 0, isExtension: true);
                
                // 1. REGISTRAR VENTA ÚNICA EN HISTORIAL
                await db.orderDao.insertOrder(
                  "${rental.consoleName} (Extra $extraMin min)",
                  cost,
                  1,
                  category: 'Rentas',
                  date: DateTime.now(),
                );

                // 2. ACTUALIZAR TIMER
                await db.rentalDao.addExtraTime(rental.id, currentEnd.add(Duration(minutes: extraMin)));
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Venta registrada y tiempo añadido"), backgroundColor: Colors.green),
                  );
                }
                if (mounted) Navigator.of(context).pop();
              },
              child: const Text("COBRAR Y APLICAR"),
            ),
          ],
        ),
      ),
    );
  }

  void _showFinishRentalConfirm(Rental rental) {
    final rentalProvider = context.read<RentalProvider>();
    final now = DateTime.now();
    final cost = rentalProvider.calculateCost(rental.startTime, now, rental.extraControllers);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF00187A),
        title: const Text("Cobro de Renta"),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text("Consola: ${rental.consoleName}", style: const TextStyle(color: Colors.white)),
              Text("Inicio: ${_formatTime(rental.startTime)}", style: const TextStyle(color: Colors.white70)),
              Text("Fin: ${_formatTime(now)}", style: const TextStyle(color: Colors.white70)),
              Text("Controles Extra: ${rental.extraControllers}", style: const TextStyle(color: Colors.white70)),
              const Divider(color: Colors.white24),
              Text("TOTAL A PAGAR: \$${cost.toStringAsFixed(2)}", style: const TextStyle(color: Color(0xFFFFDE00), fontSize: 24, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("CANCELAR")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            onPressed: () async {
              final db = context.read<AppDatabase>();
              await db.rentalDao.finishRental(rental.id, cost);
              if (mounted) Navigator.pop(ctx);
            },
            child: const Text("CONFIRMAR PAGO"),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dt) => "${dt.hour}:${dt.minute.toString().padLeft(2, '0')}";
}

class _ConsoleCard extends StatefulWidget {
  final String name;
  final String type;
  final IconData icon;
  final Rental? activeRental;
  final VoidCallback onTap;

  const _ConsoleCard({required this.name, required this.type, required this.icon, this.activeRental, required this.onTap});

  @override
  State<_ConsoleCard> createState() => _ConsoleCardState();
}

class _ConsoleCardState extends State<_ConsoleCard> {
  Timer? _timer;
  String _timeRemaining = "";
  Color _statusColor = Colors.green;

  @override
  void initState() {
    super.initState();
    _startTimer();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (widget.activeRental != null && widget.activeRental!.expectedEndTime != null) {
        final now = DateTime.now();
        final diff = widget.activeRental!.expectedEndTime!.difference(now);
        if (mounted) {
          setState(() {
            if (diff.isNegative) {
              _timeRemaining = "TIEMPO AGOTADO";
              _statusColor = Colors.red;
            } else {
              _timeRemaining = "${diff.inMinutes}:${(diff.inSeconds % 60).toString().padLeft(2, '0')}";
              _statusColor = diff.inMinutes < 5 ? Colors.orange : Colors.red;
            }
          });
        }
      } else {
        if (mounted) {
          setState(() {
            _timeRemaining = "DISPONIBLE";
            _statusColor = Colors.green;
          });
        }
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    const nexusBlue = Color(0xFF00187A);
    return InkWell(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(16),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        decoration: BoxDecoration(
          color: widget.activeRental != null ? _statusColor.withOpacity(0.2) : Colors.black26,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: widget.activeRental != null ? _statusColor : Colors.white24, width: 2),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(widget.icon, size: 40, color: widget.activeRental != null ? _statusColor : Colors.white54),
            const SizedBox(height: 10),
            Text(widget.name, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
            Text(widget.type, style: const TextStyle(color: Colors.white54, fontSize: 12)),
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(color: _statusColor, borderRadius: BorderRadius.circular(20)),
              child: Text(_timeRemaining, style: const TextStyle(color: nexusBlue, fontWeight: FontWeight.bold, fontSize: 14)),
            ),
          ],
        ),
      ),
    );
  }
}
