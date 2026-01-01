import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';
import 'daos/order_dao.dart';
import 'daos/product_dao.dart'; // ← NUEVO

part 'database.g.dart';

@DriftDatabase(
  tables: [Products, Rentals, DailyReports, OrderItems, PackageItems, ProductModifiers],
  daos: [OrderDao, ProductDao], // ← AGREGAR ProductDao
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 3; // ← INCREMENTAR VERSIÓN

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          await m.createTable(orderItems);
        }
        if (from < 3) {
          // Recrear tabla Products con nuevos campos
          await m.deleteTable(products.actualTableName);
          await m.createTable(products);
          await m.createTable(packageItems);
          await m.createTable(productModifiers);

          // Insertar productos de ejemplo
          await _insertSampleProducts();
        }
      },
    );
  }

  // ========================================
  // PRODUCTOS DE EJEMPLO
  // ========================================
  Future<void> _insertSampleProducts() async {
    await batch((batch) {
      // Bubble Teas
      batch.insert(
        products,
        ProductsCompanion.insert(
          name: 'Bubble Tea Conejos',
          price: 89,
          category: 'Bebida',
          subcategory: const Value('Bubble Tea Base Agua'),
          description: const Value('Refrescante bubble tea con sabor a frutas'),
        ),
      );

      batch.insert(
        products,
        ProductsCompanion.insert(
          name: 'Bubble Tea Taro',
          price: 89,
          category: 'Bebida',
          subcategory: const Value('Bubble Tea Base Leche'),
          description: const Value('Cremoso bubble tea de taro con perlas'),
        ),
      );

      // Sodas
      batch.insert(
        products,
        ProductsCompanion.insert(
          name: 'Soda Italiana Fresa',
          price: 45,
          category: 'Bebida',
          subcategory: const Value('Soda Italiana'),
        ),
      );

      // Comidas
      batch.insert(
        products,
        ProductsCompanion.insert(
          name: 'Nexuleta Clásica',
          price: 45,
          category: 'Comida',
          subcategory: const Value('Nexuleta Salada'),
        ),
      );

      batch.insert(
        products,
        ProductsCompanion.insert(
          name: 'Frappé Oreo',
          price: 65,
          category: 'Bebida',
          subcategory: const Value('Frappé'),
        ),
      );

      batch.insert(
        products,
        ProductsCompanion.insert(
          name: 'Pizza Individual',
          price: 50,
          category: 'Comida',
          subcategory: const Value('Pizza'),
        ),
      );

      batch.insert(
        products,
        ProductsCompanion.insert(
          name: 'Combo Gamer',
          price: 120,
          category: 'Comida',
          subcategory: const Value('Combo'),
          description: const Value('Palomitas + Refresco + Dulce'),
        ),
      );
    });
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gamer_cafe.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}