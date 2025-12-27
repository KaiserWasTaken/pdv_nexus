import 'package:drift/drift.dart';

// --- TABLA 1: PRODUCTOS (Cafetería) ---
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)(); // Ej: "Capuchino"
  RealColumn get price => real()(); // Ej: 45.50
  IntColumn get stock => integer().withDefault(const Constant(0))(); // Inventario
  TextColumn get category => text()(); // "Bebida", "Snack", "Dulce"
  BoolColumn get isActive => boolean().withDefault(const Constant(true))(); // Para "borrar" sin perder historial
}

// --- TABLA 2: RENTAS (Videojuegos) ---
class Rentals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get consoleName => text()(); // Ej: "Xbox Mesa 1"
  DateTimeColumn get startTime => dateTime()(); // A qué hora empezó
  DateTimeColumn get endTime => dateTime().nullable()(); // A qué hora terminó (null si sigue jugando)
  RealColumn get totalCost => real().nullable()(); // Cuánto pagó al final
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))(); // ¿Ya pagó?
}

// --- TABLA 3: VENTAS DIARIAS (Para el reporte PDF) ---
class DailyReports extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()(); // Fecha del reporte
  RealColumn get totalCash => real()(); // Total vendido en el día
  TextColumn get pdfPath => text()(); // Dónde se guardó el PDF en la tablet
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))(); // ¿Ya se subió a Drive?
}