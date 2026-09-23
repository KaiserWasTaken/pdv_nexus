import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';
import 'daos/order_dao.dart';
import 'daos/product_dao.dart';
import 'daos/rental_dao.dart';
import 'daos/expense_dao.dart'; // ✅ Añadido

part 'database.g.dart';

@DriftDatabase(
  tables: [Products, Rentals, DailyReports, OrderItems, PackageItems, ProductModifiers, Expenses, ComboEligibleDrinks],
  daos: [OrderDao, ProductDao, RentalDao, ExpenseDao], // ✅ Añadido ExpenseDao
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 18; // ← Incrementado para Constructor de Combos Dinámico

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
        await _insertSampleProducts();
        await _insertModifiers();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        // ... (existing migrations)
        if (from < 17) {
          await m.createTable(comboEligibleDrinks);
        }
        if (from < 18) {
          // Usamos nombres de columna directos o cast para evitar errores si la generación falla
          await m.addColumn(packageItems, (packageItems as dynamic).isPlaceholder as GeneratedColumn);
          await m.addColumn(packageItems, (packageItems as dynamic).placeholderCategory as GeneratedColumn);
          await m.addColumn(packageItems, (packageItems as dynamic).placeholderName as GeneratedColumn);
          
          // Permitir productId nulo
          await m.alterTable(TableMigration(packageItems));
        }
      },
    );
  }

  // ========================================
  // CATÁLOGO REAL DE PRODUCTOS (ACTUALIZADO v10)
  // ========================================
  Future<void> _insertSampleProducts() async {
    await batch((batch) {
      // --- 1. BEBIDAS ---
      
      // BUBBLE TEA ($75) - Base Leche
      final btLeche = [
        'Taro Purple', 'Oreo', 'Matcha', 'Fresas con crema', 
        'Horchata', 'Mazapán', 'Ferrero', 'Mora Azul', 
        'Algodón de Azúcar', 'Red Velvet', 'Moka Intenso', 'Turin'
      ];
      for (var name in btLeche) {
        batch.insert(products, ProductsCompanion.insert(
          name: 'Bubble Tea $name',
          price: 75,
          category: 'Bebidas',
          subcategory: const Value('Bubble Tea Base Leche'),
          description: const Value('Incluye tapioca'),
        ));
      }

      // BUBBLE TEA ($75) - Base Agua
      final btAgua = ['Pepino Limón', 'Frutos Rojos', 'Fresa Sandia', 'Frambuesa'];
      for (var name in btAgua) {
        batch.insert(products, ProductsCompanion.insert(
          name: 'Bubble Tea $name',
          price: 75,
          category: 'Bebidas',
          subcategory: const Value('Bubble Tea Base Agua'),
          description: const Value('Incluye tapioca'),
        ));
      }

      // SODAS ITALIANAS ($60)
      final sodas = ['Berries', 'Blueberry', 'Maracuya', 'Manzana Verde', 'Fruta del Dragón'];
      for (var name in sodas) {
        batch.insert(products, ProductsCompanion.insert(
          name: 'Soda Italiana $name',
          price: 60,
          category: 'Bebidas',
          subcategory: const Value('Soda Italiana'),
          description: const Value('Incluye perlitas explosivas'),
        ));
      }

      // TISANAS ($60)
      final tisanas = [
        'Pasión y Pétalos', 'Arándano / Fresa / Pétalos de rosa', 
        'Dulce Legado', 'Guayaba / Canela', 'Frutos Reales', 
        'Piña / Durazno / Mango'
      ];
      for (var name in tisanas) {
        batch.insert(products, ProductsCompanion.insert(
          name: 'Tisana $name',
          price: 60,
          category: 'Bebidas',
          subcategory: const Value('Tisana'),
          description: const Value('Caliente, frío o frappeado'),
        ));
      }

      // CHAMOYADAS ($60 - Asumiendo precio base similar a sodas/tisanas)
      final chamoyadas = ['Tamarindo', 'Mango', 'Fresa', 'Pelón pelo rico'];
      for (var name in chamoyadas) {
        batch.insert(products, ProductsCompanion.insert(
          name: 'Chamoyada de $name',
          price: 60,
          category: 'Bebidas',
          subcategory: const Value('Chamoyada'),
          description: const Value('Servida con chamoy, salsa, tajín y miguelito'),
        ));
      }

      // OTRAS BEBIDAS
      batch.insert(products, ProductsCompanion.insert(name: 'Refresco 355ml', price: 20, category: 'Bebidas', subcategory: const Value('Otros')));
      batch.insert(products, ProductsCompanion.insert(name: 'Agua Embotellada', price: 20, category: 'Bebidas', subcategory: const Value('Otros')));
      batch.insert(products, ProductsCompanion.insert(name: 'Café Americano', price: 30, category: 'Bebidas', subcategory: const Value('Otros')));

      // --- 2. SNACKS Y ALIMENTOS ---

      // NEXULETAS
      batch.insert(products, ProductsCompanion.insert(
        name: '1 pieza',
        price: 40,
        category: 'Comidas',
        subcategory: const Value('Nexuleta'),
        description: const Value('Salchicha, queso o mixta'),
      ));
      batch.insert(products, ProductsCompanion.insert(
        name: '2 piezas',
        price: 70,
        category: 'Comidas',
        subcategory: const Value('Nexuleta'),
      ));
      batch.insert(products, ProductsCompanion.insert(
        name: '3 piezas',
        price: 110,
        category: 'Comidas',
        subcategory: const Value('Nexuleta'),
      ));

      // NACHOS
      batch.insert(products, ProductsCompanion.insert(name: 'Nachos', price: 55, category: 'Comidas', subcategory: const Value('Nachos')));

      // MINI HOT CAKES
      batch.insert(products, ProductsCompanion.insert(name: '12 Mini Hot Cakes', price: 55, category: 'Comidas', subcategory: const Value('Mini Hot Cakes'), description: const Value('Incluye 1 untable + 2 toppings')));
      batch.insert(products, ProductsCompanion.insert(name: '24 Mini Hot Cakes', price: 100, category: 'Comidas', subcategory: const Value('Mini Hot Cakes'), description: const Value('Incluye 1 untable + 2 toppings')));

      // PALOMITAS
      batch.insert(products, ProductsCompanion.insert(name: 'Palomitas Chicas', price: 25, category: 'Comidas', subcategory: const Value('Palomitas')));
      batch.insert(products, ProductsCompanion.insert(name: 'Palomitas Medianas', price: 45, category: 'Comidas', subcategory: const Value('Palomitas'), description: const Value('Sabor extra +\$5')));

      // OTROS
      batch.insert(products, ProductsCompanion.insert(name: 'Maruchan', price: 30, category: 'Comidas', subcategory: const Value('Maruchan')));

      // --- 3. COMBOS NEXUS ---
      
      final combos = [
        {'name': 'Combo Nachos', 'price': 210.0, 'desc': '1h 2 controles + 2 bebidas + 1 nachos'},
        {'name': 'Nexus Duo', 'price': 200.0, 'desc': '1h 2 controles + 2 bebidas + 1 palomitas grandes'},
        {'name': 'Nexus de Compas', 'price': 285.0, 'desc': '2h 2 controles + 2 bebidas + 1 palomitas grandes + 2 sopas'},
        {'name': 'Combo Nachos XL', 'price': 275.0, 'desc': '1h 2 controles + 2 bebidas + 1 nachos + 2 nexuletas'},
        {'name': 'Nexus Squad', 'price': 360.0, 'desc': '2h 4 controles 2 consolas + 4 bebidas + 1 palomitas grandes'},
        {'name': 'Nexus Lovers', 'price': 220.0, 'desc': '24 mini hot cakes + 2 bubble tea o café'},
        {'name': 'Pa k Compartas', 'price': 265.0, 'desc': '3 bebidas + 1 palomitas grandes + 1 sopa'},
        {'name': 'Nexuletas pah Todos', 'price': 200.0, 'desc': '2 bebidas + 2 nexuletas'},
        {'name': 'Nachos de Compas', 'price': 175.0, 'desc': '2 bebidas + 1 nachos'},
      ];

      for (var c in combos) {
        batch.insert(products, ProductsCompanion.insert(
          name: c['name'] as String,
          price: c['price'] as double,
          category: 'Combos',
          subcategory: const Value('Combo'),
          description: Value(c['desc'] as String),
        ));
      }
    });
  }

  Future<void> _insertModifiers() async {
    await batch((batch) {
      // Modificadores de Bebidas
      batch.insert(productModifiers, ProductModifiersCompanion.insert(name: 'Tapioca Extra', extraPrice: const Value(10.0), applicableCategory: 'Bebidas'));
      batch.insert(productModifiers, ProductModifiersCompanion.insert(name: 'Perlitas Extra', extraPrice: const Value(10.0), applicableCategory: 'Bebidas'));
      
      // Modificadores de Comidas
      batch.insert(productModifiers, ProductModifiersCompanion.insert(name: 'Queso Extra', extraPrice: const Value(10.0), applicableCategory: 'Comidas'));
      batch.insert(productModifiers, ProductModifiersCompanion.insert(name: 'Chiles Extra', extraPrice: const Value(10.0), applicableCategory: 'Comidas'));
      batch.insert(productModifiers, ProductModifiersCompanion.insert(name: 'Polvito Sabor (Snacks)', extraPrice: const Value(5.0), applicableCategory: 'Comidas'));
      batch.insert(productModifiers, ProductModifiersCompanion.insert(name: 'Queso Amarillo Derretido (Nexuleta)', extraPrice: const Value(10.0), applicableCategory: 'Comidas'));
      
      // Modificadores de Combos
      batch.insert(productModifiers, ProductModifiersCompanion.insert(name: 'Convertir Palomitas Sabor', extraPrice: const Value(10.0), applicableCategory: 'Combos'));
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