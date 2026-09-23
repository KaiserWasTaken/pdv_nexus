import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'expense_dao.g.dart';

@DriftAccessor(tables: [Expenses])
class ExpenseDao extends DatabaseAccessor<AppDatabase> with _$ExpenseDaoMixin {
  ExpenseDao(AppDatabase db) : super(db);

  // Insertar un nuevo gasto
  Future<int> insertExpense(ExpensesCompanion entry) {
    return into(expenses).insert(entry);
  }

  // Obtener gastos activos (que no están en un reporte cerrado)
  Stream<List<Expense>> watchActiveExpenses() {
    return (select(expenses)..where((tbl) => tbl.reportId.isNull())).watch();
  }

  Future<List<Expense>> getActiveExpenses() {
    return (select(expenses)..where((tbl) => tbl.reportId.isNull())).get();
  }

  // Eliminar un gasto
  Future<int> deleteExpense(int id) {
    return (delete(expenses)..where((tbl) => tbl.id.equals(id))).go();
  }

  // Vincular gastos a un reporte al cerrar el día
  Future<int> closeActiveExpenses(int reportId) {
    return (update(expenses)..where((tbl) => tbl.reportId.isNull())).write(
      ExpensesCompanion(reportId: Value(reportId)),
    );
  }

  // Obtener el total de gastos activos como Stream
  Stream<double> watchActiveExpensesTotal() {
    return watchActiveExpenses().map((expenses) {
      return expenses.fold(0.0, (sum, item) => sum + item.amount);
    });
  }
}