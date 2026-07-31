import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';
import 'daos/order_dao.dart';
import 'daos/product_dao.dart';
import 'daos/rental_dao.dart'; // ✅ NUEVO

part 'database.g.dart';

@DriftDatabase(
  tables: [Products, Rentals, DailyReports, OrderItems, PackageItems, ProductModifiers],
  daos: [OrderDao, ProductDao, RentalDao], // ✅ AGREGAR RentalDao
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 9; // ← INCREMENTAR VERSIÓN

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _insertSampleProducts();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) await m.createTable(orderItems);
        if (from < 3) {
          await m.deleteTable(products.actualTableName);
          await m.createTable(products);
          await m.createTable(packageItems);
          await m.createTable(productModifiers);
        }
        if (from < 4) {
          await m.deleteTable(products.actualTableName);
          await m.createTable(products);
          await _insertSampleProducts();
        }
        if (from < 5) {
          await m.deleteTable(products.actualTableName);
          await m.createTable(products);
          await _insertSampleProducts();
        }
        if (from < 6) {
          await m.addColumn(rentals, rentals.expectedEndTime);
          await m.addColumn(rentals, rentals.extraControllers);
        }
        if (from < 7) {
          await m.addColumn(orderItems, orderItems.category);
        }
        if (from < 8) {
          // Recrear OrderItems para asegurar currentDateAndTime y tipo correcto de category
          await m.deleteTable(orderItems.actualTableName);
          await m.createTable(orderItems);
        }
        if (from < 9) {
          await m.addColumn(orderItems, orderItems.reportId);
        }
      },
    );
  }

  // ========================================
  // CATÁLOGO REAL DE PRODUCTOS
  // ========================================
  Future<void> _insertSampleProducts() async {
    await batch((batch) {
      // --- BEBIDAS ($70) ---
      final bubbleTeas = [
        'Oreo', 'Fresas con crema', 'Taro purple', 'Mora azul',
        'Moka intenso', 'Mazapán', 'Horchata', 'Red velvet',
        'Algodón de azúcar', 'Matcha', 'Ferrero'
      ];
      for (var name in bubbleTeas) {
        batch.insert(products, ProductsCompanion.insert(
          name: 'Bubble Tea $name',
          price: 70,
          category: 'Bebidas',
          subcategory: const Value('Bubble Tea'),
          description: const Value('Delicioso frappe de bubble tea con ricas tapiocas'),
        ));
      }

      final chamoyadas = ['Tamarindo', 'Fresa', 'Pelón Pelorico', 'Mango'];
      for (var name in chamoyadas) {
        batch.insert(products, ProductsCompanion.insert(
          name: 'Chamoyada de $name',
          price: 70,
          category: 'Bebidas',
          subcategory: const Value('Chamoyada'),
          description: const Value('Rica chamoyada con salsa o chamoy, miguelito o tajín'),
        ));
      }

      final smoothies = ['Pepino Limón', 'Frutos Rojos', 'Fresa Sandía'];
      for (var name in smoothies) {
        batch.insert(products, ProductsCompanion.insert(
          name: 'Smoothie de $name',
          price: 70,
          category: 'Bebidas',
          subcategory: const Value('Smoothie'),
          description: const Value('Refrescante smoothie frutal'),
        ));
      }

      final sodas = ['Maracuya', 'Fruta Del Dragón', 'Berry', 'Manzana Verde', 'Blue Berry'];
      for (var name in sodas) {
        batch.insert(products, ProductsCompanion.insert(
          name: name == 'Fruta Del Dragón' ? name : 'Soda Italiana $name',
          price: 70,
          category: 'Bebidas',
          subcategory: const Value('Soda Italiana'),
          description: const Value('Rica soda italiana con deliciosas perlas explosivas'),
        ));
      }

      // --- COMIDAS ---
      // Palomitas
      batch.insert(products, ProductsCompanion.insert(
        name: 'Palomitas Chicas',
        price: 45,
        category: 'Comidas',
        subcategory: const Value('Palomitas'),
      ));
      batch.insert(products, ProductsCompanion.insert(
        name: 'Palomitas Grandes',
        price: 75,
        category: 'Comidas',
        subcategory: const Value('Palomitas'),
      ));
      batch.insert(products, ProductsCompanion.insert(
        name: 'Palomitas Jumbo Prime',
        price: 100,
        category: 'Comidas',
        subcategory: const Value('Palomitas'),
      ));

      // Mini Hot Cakes
      batch.insert(products, ProductsCompanion.insert(
        name: '12 Mini Hot Cakes',
        price: 85,
        category: 'Comidas',
        subcategory: const Value('Mini Hot Cakes'),
      ));
      batch.insert(products, ProductsCompanion.insert(
        name: '24 Mini Hot Cakes',
        price: 145,
        category: 'Comidas',
        subcategory: const Value('Mini Hot Cakes'),
      ));

      // Nexuletas (NUEVO)
      batch.insert(products, ProductsCompanion.insert(
        name: 'Nexuleta (1 pza)',
        price: 40,
        category: 'Comidas',
        subcategory: const Value('Nexuletas'),
        description: const Value('Banderilla con toppings a elegir'),
      ));
      batch.insert(products, ProductsCompanion.insert(
        name: 'Nexuletas (2 pzas)',
        price: 80,
        category: 'Comidas',
        subcategory: const Value('Nexuletas'),
        description: const Value('2 Banderillas con toppings a elegir'),
      ));
      batch.insert(products, ProductsCompanion.insert(
        name: 'Nexuletas (3 pzas)',
        price: 120,
        category: 'Comidas',
        subcategory: const Value('Nexuletas'),
        description: const Value('3 Banderillas con toppings a elegir'),
      ));

      // --- COMBOS ---
      batch.insert(products, ProductsCompanion.insert(
        name: 'Pa k te despiertes (12 pcs)',
        price: 105,
        category: 'Combos',
        subcategory: const Value('Combo'),
        description: const Value('12 Mini hot cakes + Café Americano'),
      ));
      batch.insert(products, ProductsCompanion.insert(
        name: 'Pa k te despiertes (24 pcs)',
        price: 145,
        category: 'Combos',
        subcategory: const Value('Combo'),
        description: const Value('24 Mini hot cakes + Café Americano'),
      ));
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