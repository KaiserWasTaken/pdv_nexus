// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'product_dao.dart';

// ignore_for_file: type=lint
mixin _$ProductDaoMixin on DatabaseAccessor<AppDatabase> {
  $ProductsTable get products => attachedDatabase.products;
  $PackageItemsTable get packageItems => attachedDatabase.packageItems;
  $ProductModifiersTable get productModifiers =>
      attachedDatabase.productModifiers;
  ProductDaoManager get managers => ProductDaoManager(this);
}

class ProductDaoManager {
  final _$ProductDaoMixin _db;
  ProductDaoManager(this._db);
  $$ProductsTableTableManager get products =>
      $$ProductsTableTableManager(_db.attachedDatabase, _db.products);
  $$PackageItemsTableTableManager get packageItems =>
      $$PackageItemsTableTableManager(_db.attachedDatabase, _db.packageItems);
  $$ProductModifiersTableTableManager get productModifiers =>
      $$ProductModifiersTableTableManager(
        _db.attachedDatabase,
        _db.productModifiers,
      );
}
