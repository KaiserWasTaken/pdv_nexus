import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'product_dao.g.dart';

@DriftAccessor(tables: [Products, PackageItems, ProductModifiers])
class ProductDao extends DatabaseAccessor<AppDatabase> with _$ProductDaoMixin {
  ProductDao(AppDatabase db) : super(db);

  // ========================================
  // 1. OBTENER TODOS LOS PRODUCTOS ACTIVOS
  // ========================================
  Stream<List<Product>> watchActiveProducts() {
    return (select(products)
      ..where((tbl) => tbl.isActive.equals(true))
      ..orderBy([
            (t) => OrderingTerm(expression: t.category),
            (t) => OrderingTerm(expression: t.name),
      ]))
        .watch();
  }

  Future<List<Product>> getActiveProducts() {
    return (select(products)
      ..where((tbl) => tbl.isActive.equals(true))
      ..orderBy([
            (t) => OrderingTerm(expression: t.category),
            (t) => OrderingTerm(expression: t.name),
      ]))
        .get();
  }

  // ========================================
  // 2. OBTENER PRODUCTOS POR CATEGORÍA
  // ========================================
  Stream<List<Product>> watchProductsByCategory(String category) {
    return (select(products)
      ..where((tbl) => tbl.category.equals(category) & tbl.isActive.equals(true))
      ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch();
  }

  // ========================================
  // 3. INSERTAR PRODUCTO SIMPLE
  // ========================================
  Future<int> insertProduct({
    required String name,
    required double price,
    required String category,
    String? subcategory,
    String? description,
    String? imagePath,
    int stock = 0,
  }) async {
    return await into(products).insert(
      ProductsCompanion.insert(
        name: name,
        price: price,
        category: category,
        subcategory: Value(subcategory),
        description: Value(description),
        imagePath: Value(imagePath),
        stock: Value(stock),
        productType: const Value('simple'),
      ),
    );
  }

  // ========================================
  // 4. INSERTAR PRODUCTO PAQUETE
  // ========================================
  Future<int> insertPackage({
    required String name,
    required double price,
    required String description,
    String? imagePath,
    required List<Map<String, int>> items, // [{productId: 1, quantity: 2}, ...]
  }) async {
    // Insertar el paquete
    final packageId = await into(products).insert(
      ProductsCompanion.insert(
        name: name,
        price: price,
        category: 'Paquete',
        description: Value(description),
        imagePath: Value(imagePath),
        productType: const Value('paquete'),
      ),
    );

    // Insertar los items del paquete
    await batch((batch) {
      for (var item in items) {
        batch.insert(
          packageItems,
          PackageItemsCompanion.insert(
            packageId: packageId,
            productId: item['productId']!,
            quantity: Value(item['quantity']!),
          ),
        );
      }
    });

    return packageId;
  }

  // ========================================
  // 5. OBTENER ITEMS DE UN PAQUETE
  // ========================================
  Future<List<Map<String, dynamic>>> getPackageItems(int packageId) async {
    final query = select(packageItems).join([
      innerJoin(products, products.id.equalsExp(packageItems.productId))
    ])
      ..where(packageItems.packageId.equals(packageId));

    final results = await query.get();

    return results.map((row) {
      final item = row.readTable(packageItems);
      final product = row.readTable(products);

      return {
        'productId': product.id,
        'productName': product.name,
        'quantity': item.quantity,
        'price': product.price,
      };
    }).toList();
  }

  // ========================================
  // 6. ACTUALIZAR PRODUCTO
  // ========================================
  Future<bool> updateProduct(int id, ProductsCompanion updates) async {
    final rowsAffected = await (update(products)
      ..where((tbl) => tbl.id.equals(id)))
        .write(updates);
    return rowsAffected > 0;
  }

  // ========================================
  // 7. DESACTIVAR/ACTIVAR PRODUCTO
  // ========================================
  Future<bool> toggleProductStatus(int id, bool isActive) async {
    return await updateProduct(
      id,
      ProductsCompanion(isActive: Value(isActive)),
    );
  }

  // ========================================
  // 8. ELIMINAR PRODUCTO (Soft delete)
  // ========================================
  Future<bool> deleteProduct(int id) async {
    return await toggleProductStatus(id, false);
  }

  // ========================================
  // 9. BUSCAR PRODUCTOS
  // ========================================
  Future<List<Product>> searchProducts(String query) async {
    return (select(products)
      ..where((tbl) =>
      tbl.name.contains(query) |
      tbl.description.contains(query))
      ..where((tbl) => tbl.isActive.equals(true)))
        .get();
  }

  // ========================================
  // 10. GESTIÓN DE MODIFICADORES
  // ========================================
  Future<int> insertModifier({
    required String name,
    required double extraPrice,
    required String applicableCategory,
  }) async {
    return await into(productModifiers).insert(
      ProductModifiersCompanion.insert(
        name: name,
        extraPrice: Value(extraPrice),
        applicableCategory: applicableCategory,
      ),
    );
  }

  Stream<List<ProductModifier>> watchModifiersByCategory(String category) {
    return (select(productModifiers)
      ..where((tbl) =>
      tbl.applicableCategory.equals(category) &
      tbl.isActive.equals(true)))
        .watch();
  }

  // ========================================
  // 11. OBTENER PRODUCTO POR ID
  // ========================================
  Future<Product?> getProductById(int id) async {
    return (select(products)..where((tbl) => tbl.id.equals(id))).getSingleOrNull();
  }

  // ========================================
  // 12. ACTUALIZAR STOCK
  // ========================================
  Future<bool> updateStock(int productId, int newStock) async {
    return await updateProduct(
      productId,
      ProductsCompanion(stock: Value(newStock)),
    );
  }

  // ========================================
  // 13. ESTADÍSTICAS DE PRODUCTOS
  // ========================================
  Future<Map<String, dynamic>> getProductStats() async {
    final allProducts = await (select(products)
      ..where((tbl) => tbl.isActive.equals(true)))
        .get();

    final bebidas = allProducts.where((p) => p.category == 'Bebida').length;
    final comidas = allProducts.where((p) => p.category == 'Comida').length;
    final paquetes = allProducts.where((p) => p.productType == 'paquete').length;

    return {
      'total': allProducts.length,
      'bebidas': bebidas,
      'comidas': comidas,
      'paquetes': paquetes,
    };
  }
}