import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // ✅ Añadido para sonidos y vibración
import '../database/database.dart';

class RentalProvider extends ChangeNotifier {
  final AppDatabase _db;
  StreamSubscription<List<Rental>>? _subscription;
  List<Rental> _activeRentals = [];
  Timer? _timer;

  // Modo Developer: si está activo, se muestran botones extra
  bool _isDevMode = false;
  bool get isDevMode => _isDevMode;

  void toggleDevMode() {
    _isDevMode = !_isDevMode;
    notifyListeners();
  }

  // Alarma: Mapa de RentalId -> bool (si ya se activó la alarma)
  final Map<int, bool> _notifiedRentals = {};
  
  // Alerta actual para mostrar en la UI
  String? _currentAlert;
  String? get currentAlert => _currentAlert;

  RentalProvider(this._db) {
    _init();
  }

  void _init() {
    _subscription = _db.rentalDao.watchActiveRentals().listen((rentals) {
      _activeRentals = rentals;
      notifyListeners();
    });

    // Timer global cada segundo para verificar alarmas
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      _checkAlarms();
    });
  }

  List<Rental> get activeRentals => _activeRentals;

  void _checkAlarms() {
    final now = DateTime.now();
    bool changed = false;

    for (var rental in _activeRentals) {
      if (rental.expectedEndTime != null) {
        // Verificar si el tiempo ya terminó
        if (now.isAfter(rental.expectedEndTime!) && !(_notifiedRentals[rental.id] ?? false)) {
          _currentAlert = " ¡TIEMPO TERMINADO! - ${rental.consoleName}";
          _notifiedRentals[rental.id] = true;
          changed = true;
          _triggerAlertEffects(); // ✅ Sonido + Vibración
        }
      }
    }

    if (changed) notifyListeners();
  }

  void clearAlert() {
    _currentAlert = null;
    notifyListeners();
  }

  Future<void> _triggerAlertEffects() async {
    // 1. Patrón de Vibración Intenso (5 pulsos)
    for (int i = 0; i < 5; i++) {
      HapticFeedback.vibrate();
      await Future.delayed(const Duration(milliseconds: 200));
    }

    // 2. Sonido del sistema repetido
    SystemSound.play(SystemSoundType.click);
    await Future.delayed(const Duration(milliseconds: 100));
    SystemSound.play(SystemSoundType.click);
    
    debugPrint("ALERTA: Tiempo terminado ");
  }

  // ========================================
  // MODO DEVELOPER: FORZAR FINALIZACIÓN
  // ========================================
  Future<void> forceFinishTime(int rentalId) async {
    // Ponemos el tiempo de fin a "hace 1 segundo" para que la alarma se dispare
    final expiredTime = DateTime.now().subtract(const Duration(seconds: 1));
    await _db.rentalDao.addExtraTime(rentalId, expiredTime);
  }

  // ========================================
  // CÁLCULO DE COSTOS (ACTUALIZADO v10.1)
  // ========================================
  double calculateCostForTime(int minutes, int extraControllers, {bool isExtension = false}) {
    if (minutes <= 0) return 0.0;

    double cost = 0;

    if (isExtension) {
      // SI ES EXTENSIÓN: $20 por cada bloque de 30 min o fracción
      int blocks = (minutes / 30).ceil();
      cost = blocks * 20.0;
    } else {
      // SI ES COBRO INICIAL:
      int fullHours = minutes ~/ 60;
      int remainingMinutes = minutes % 60;

      // Cada hora completa sale en $35
      cost = fullHours * 35.0;

      if (remainingMinutes > 0) {
        if (fullHours == 0) {
          // Menos de una hora inicial
          if (remainingMinutes <= 30) {
            cost = 25.0; // 30 min o menos inicial
          } else {
            cost = 35.0; // De 31 a 60 min inicial
          }
        } else {
          // Fracción después de una hora completa: $20 por cada bloque de 30 min
          int extraBlocks = (remainingMinutes / 30).ceil();
          cost += extraBlocks * 20.0;
        }
      }
    }

    // Controles adicionales ($15 c/u)
    cost += extraControllers * 15.0;

    return cost;
  }

  double calculateCost(DateTime start, DateTime end, int extraControllers) {
    final duration = end.difference(start);
    // Para el cobro final al liberar la consola, usamos la lógica base
    return calculateCostForTime(duration.inMinutes, extraControllers, isExtension: false);
  }

  // ... rest of the class

  @override
  void dispose() {
    _subscription?.cancel();
    _timer?.cancel();
    super.dispose();
  }
}
