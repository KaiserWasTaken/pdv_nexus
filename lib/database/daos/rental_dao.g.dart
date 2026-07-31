// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rental_dao.dart';

// ignore_for_file: type=lint
mixin _$RentalDaoMixin on DatabaseAccessor<AppDatabase> {
  $RentalsTable get rentals => attachedDatabase.rentals;
  RentalDaoManager get managers => RentalDaoManager(this);
}

class RentalDaoManager {
  final _$RentalDaoMixin _db;
  RentalDaoManager(this._db);
  $$RentalsTableTableManager get rentals =>
      $$RentalsTableTableManager(_db.attachedDatabase, _db.rentals);
}
