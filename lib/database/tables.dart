import 'package:drift/drift.dart';

// --- 1. PRODUCTOS (Catálogo Mejorado) ---
class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().withLength(min: 1, max: 100)();
  RealColumn get price => real()();
  IntColumn get stock => integer().withDefault(const Constant(0))();

  // Categoría principal: "Bebida", "Comida", "Paquete"
  TextColumn get category => text()();

  // Subcategoría: "Bubble Tea Base Agua", "Bubble Tea Base Leche", "Soda Italiana", etc.
  TextColumn get subcategory => text().nullable()();

  // Descripción del producto
  TextColumn get description => text().nullable()();

  // Ruta de la imagen (almacenada localmente)
  TextColumn get imagePath => text().nullable()();

  // Tipo: "simple" o "paquete"
  TextColumn get productType => text().withDefault(const Constant('simple'))();

  BoolColumn get isActive => boolean().withDefault(const Constant(true))();

  // Fecha de creación
  DateTimeColumn get createdAt => dateTime().withDefault(currentDateAndTime)();
}

// --- 2. ITEMS DE PAQUETE (Para combos) ---
class PackageItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  // ID del producto paquete
  IntColumn get packageId => integer().references(Products, #id, onDelete: KeyAction.cascade)();

  // ID del producto individual incluido
  IntColumn get productId => integer().references(Products, #id, onDelete: KeyAction.cascade)();

  // Cantidad de este producto en el paquete
  IntColumn get quantity => integer().withDefault(const Constant(1))();
}

// --- 3. TOPPINGS/MODIFICADORES ---
class ProductModifiers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()(); // "Extra Tapioca", "Oreo", "Nutella"
  RealColumn get extraPrice => real().withDefault(const Constant(0.0))(); // Precio adicional
  TextColumn get applicableCategory => text()(); // "Bubble Tea", "Nexuleta", "Hot Cakes"
  BoolColumn get isActive => boolean().withDefault(const Constant(true))();
}

// --- 4. RENTAS (Consolas) ---
class Rentals extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get consoleName => text()(); // "Mesa 1", "Xbox A"
  DateTimeColumn get startTime => dateTime()();
  DateTimeColumn get endTime => dateTime().nullable()(); // null = Jugando
  RealColumn get totalCost => real().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
}

// --- 5. ITEMS DE VENTA (Para el Monitor de Cocina) ---
class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get productName => text()();
  RealColumn get priceAtSale => real()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();

  // Modificadores aplicados (JSON string: ["Extra Tapioca", "Sin Azúcar"])
  TextColumn get modifiers => text().nullable()();

  // Estatus: 'pendiente' (rojo) o 'entregado' (verde)
  TextColumn get status => text().withDefault(const Constant('pendiente'))();

  // Fecha exacta para saber qué se vendió hoy
  DateTimeColumn get orderDate => dateTime().withDefault(currentDate)();
}

// --- 6. REPORTES DIARIOS (Historial) ---
class DailyReports extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get totalCash => real()();
  TextColumn get pdfPath => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}