import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'rental_dao.g.dart';

@DriftAccessor(tables: [Rentals])
class RentalDao extends DatabaseAccessor<AppDatabase> with _$RentalDaoMixin {
  RentalDao(AppDatabase db) : super(db);

  // ========================================
  // 1. OBTENER RENTAS ACTIVAS
  // ========================================
  Stream<List<Rental>> watchActiveRentals() {
    return (select(rentals)
          ..where((tbl) => tbl.isCompleted.equals(false))
          ..orderBy([(t) => OrderingTerm(expression: t.startTime)]))
        .watch();
  }

  // ========================================
  // 2. INICIAR RENTA
  // ========================================
  Future<int> startRental({
    required String consoleName,
    required DateTime startTime,
    DateTime? expectedEndTime,
    int extraControllers = 0,
  }) async {
    return await into(rentals).insert(
      RentalsCompanion.insert(
        consoleName: consoleName,
        startTime: startTime,
        expectedEndTime: Value(expectedEndTime),
        extraControllers: Value(extraControllers),
        isCompleted: const Value(false),
      ),
    );
  }

  // ========================================
  // 3. AGREGAR TIEMPO EXTRA
  // ========================================
  Future<bool> addExtraTime(int rentalId, DateTime newExpectedEndTime) async {
    final rowsAffected = await (update(rentals)
          ..where((tbl) => tbl.id.equals(rentalId)))
        .write(
      RentalsCompanion(
        expectedEndTime: Value(newExpectedEndTime),
      ),
    );
    return rowsAffected > 0;
  }

  // ========================================
  // 4. FINALIZAR RENTA
  // ========================================
  Future<bool> finishRental(int rentalId, double finalCost) async {
    final now = DateTime.now();
    final rowsAffected = await (update(rentals)
          ..where((tbl) => tbl.id.equals(rentalId)))
        .write(
      RentalsCompanion(
        endTime: Value(now),
        totalCost: Value(finalCost),
        isCompleted: const Value(true),
      ),
    );
    return rowsAffected > 0;
  }

  // ========================================
  // 5. BUSCAR RENTA ACTIVA POR CONSOLA
  // ========================================
  Future<Rental?> getActiveRentalByConsole(String consoleName) {
    return (select(rentals)
          ..where((tbl) =>
              tbl.consoleName.equals(consoleName) & tbl.isCompleted.equals(false)))
        .getSingleOrNull();
  }
}
