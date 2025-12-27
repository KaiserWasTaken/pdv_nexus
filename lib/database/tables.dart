import 'package:drift/drift.dart';

// --- 1. PRODUCTOS (Catálogo) ---
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 50)();
  RealColumn get price => real()();
  IntColumn get stock => integer().withDefault(const Constant(0))();
  TextColumn get category => text()(); // "Bebida", "Snack"
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

// --- 2. RENTAS (Consolas) ---
class Rentals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get consoleName => text()(); // "Mesa 1", "Xbox A"
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()(); // null = Jugando
  RealColumn get totalCost => real().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
}

// --- 3. ITEMS DE VENTA (NUEVA TABLA - Para el Monitor de Cocina) ---
class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  // Guardamos el nombre y precio "congelados" por si después cambian en el catálogo
  TextColumn get productName => text()();
  RealColumn get priceAtSale => real()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();

  // Estatus: 'pendiente' (rojo) o 'entregado' (verde)
  TextColumn get status => text().withDefault(const Constant('pendiente'))();

  // Fecha exacta para saber qué se vendió hoy
  DateTimeColumn get orderDate => dateTime().withDefault(currentDate)();
}

// --- 4. REPORTES DIARIOS (Historial) ---
class DailyReports extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get totalCash => real()();
  TextColumn get pdfPath => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}