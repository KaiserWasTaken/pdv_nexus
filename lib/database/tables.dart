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

// --- 2. ITEMS DE PAQUETE (Constructor de Combos Dinámico) ---
class PackageItems extends Table {
  IntColumn get id => integer().autoIncrement()();

  // ID del combo (el producto padre)
  IntColumn get packageId => integer().references(Products, #id, onDelete: KeyAction.cascade)();

  // ID del producto fijo (opcional si es un espacio libre)
  IntColumn get productId => integer().nullable().references(Products, #id, onDelete: KeyAction.cascade)();

  // Cantidad incluida
  IntColumn get quantity => integer().withDefault(const Constant(1))();

  // ✅ NUEVO: Lógica de espacios libres
  BoolColumn get isPlaceholder => boolean().withDefault(const Constant(false))();
  TextColumn get placeholderCategory => text().nullable()(); // "Bebidas", "Rentas", etc.
  TextColumn get placeholderName => text().nullable()(); // "Bebida Libre", "Hora de Juego"
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
  DateTimeColumn get expectedEndTime => dateTime().nullable()(); // ✅ NUEVO: Para alarmas
  IntColumn get extraControllers => integer().withDefault(const Constant(0))(); // ✅ NUEVO: Cobro extra
  RealColumn get totalCost => real().nullable()();
  BoolColumn get isCompleted => boolean().withDefault(const Constant(false))();
}

// --- 5. ITEMS DE VENTA (Para el Monitor de Cocina) ---
class OrderItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get productName => text()();
  RealColumn get priceAtSale => real()();
  IntColumn get quantity => integer().withDefault(const Constant(1))();
  TextColumn get category => text().nullable()(); // ✅ NUEVO: Para reportes
  IntColumn get reportId => integer().nullable().references(DailyReports, #id)(); // ✅ NUEVO: Cierre de día
  TextColumn get orderGroupId => text().nullable()(); // ✅ NUEVO: Para agrupar tickets en monitor

  // Modificadores aplicados (JSON string: ["Extra Tapioca", "Sin Azúcar"])
  TextColumn get modifiers => text().nullable()();

  // Estatus: 'pendiente' (rojo) o 'entregado' (verde)
  TextColumn get status => text().withDefault(const Constant('pendiente'))();

  // Fecha exacta para saber qué se vendió hoy
  DateTimeColumn get orderDate => dateTime().withDefault(currentDateAndTime)();

  // Método de pago: 'Efectivo' o 'Tarjeta'
  TextColumn get paymentMethod => text().withDefault(const Constant('Efectivo'))();
}

// --- 6. REPORTES DIARIOS (Historial) ---
class DailyReports extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get date => dateTime()();
  RealColumn get totalCash => real()();
  TextColumn get pdfPath => text()();
  BoolColumn get isSynced => boolean().withDefault(const Constant(false))();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get description => text()();
  RealColumn get amount => real()();
  TextColumn get category => text()();
  TextColumn get paymentMethod => text()();
  DateTimeColumn get date => dateTime().withDefault(currentDateAndTime)();
  IntColumn get reportId => integer().nullable().references(DailyReports, #id)();
}

// --- 8. BEBIDAS ELEGIBLES PARA COMBOS ---
class ComboEligibleDrinks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get comboId => integer().references(Products, #id, onDelete: KeyAction.cascade)();
  IntColumn get drinkId => integer().references(Products, #id, onDelete: KeyAction.cascade)();
}
