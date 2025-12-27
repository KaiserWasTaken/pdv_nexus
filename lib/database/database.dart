import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables.dart'; // Importamos las tablas que acabamos de crear

// Esto es magia de Drift: Generará un archivo 'database.g.dart' automáticamente
part 'database.g.dart';

@DriftDatabase(tables: [Products, Rentals, DailyReports])
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;
}

// Función para abrir la base de datos en el archivo físico de la tablet
LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'gamer_cafe.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}