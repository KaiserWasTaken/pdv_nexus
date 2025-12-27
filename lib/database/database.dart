import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart';

part 'database.g.dart';

// AQUÍ AGREGAMOS 'OrderItems' A LA LISTA  ↓↓↓↓
@DriftDatabase(tables: [Products, Rentals, DailyReports, OrderItems])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  // Aumentamos la versión porque cambiamos la estructura (de 1 a 2)
  @override
  int get schemaVersion => 2;

  // Esto ayuda a Drift a saber qué hacer cuando subimos de versión (migración)
  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      onCreate: (Migrator m) async {
        await m.createAll();
      },
      onUpgrade: (Migrator m, int from, int to) async {
        if (from < 2) {
          // Si el usuario tenía la versión 1, creamos la tabla nueva
          await m.createTable(orderItems);
        }
      },
    );
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gamer_cafe.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}