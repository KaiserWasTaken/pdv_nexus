import 'package:drift/drift.dart';
import '../database.dart';
import '../tables.dart';

part 'order_dao.g.dart';

@DriftAccessor(tables: [OrderItems])
class OrderDao extends DatabaseAccessor<AppDatabase> with _$OrderDaoMixin {
  OrderDao(AppDatabase db) : super(db);

  // ========================================
  // 1. INSERTAR ORDEN COMPLETA
  // ========================================
  Future<void> insertOrder(String productName, double price, int quantity, {String? category, DateTime? date}) async {
    await into(orderItems).insert(
      OrderItemsCompanion.insert(
        productName: productName,
        priceAtSale: price,
        quantity: Value(quantity),
        category: Value(category),
        orderDate: Value(date ?? DateTime.now()), // ← Preferimos la hora de Dart
      ),
    );
  }

  // Método para insertar múltiples items con sus estatus específicos
  Future<void> insertCompanions(List<OrderItemsCompanion> companions) async {
    await batch((batch) {
      batch.insertAll(orderItems, companions);
    });
  }

  // ========================================
  // 2. OBTENER ÓRDENES PENDIENTES
  // ========================================
  // Stream que se actualiza automáticamente cuando cambia la BD
  Stream<List<OrderItem>> watchPendingOrders() {
    return (select(orderItems)
      ..where((tbl) => tbl.status.equals('pendiente') & tbl.reportId.isNull())
      ..orderBy([
            (t) => OrderingTerm(expression: t.orderDate, mode: OrderingMode.desc)
      ]))
        .watch();
  }

  // Método de consulta única (sin stream)
  Future<List<OrderItem>> getPendingOrders() {
    return (select(orderItems)
      ..where((tbl) => tbl.status.equals('pendiente') & tbl.reportId.isNull())
      ..orderBy([
            (t) => OrderingTerm(expression: t.orderDate, mode: OrderingMode.desc)
      ]))
        .get();
  }

  // ========================================
  // 3. MARCAR COMO ENTREGADO
  // ========================================
  Future<bool> markAsDelivered(int orderId) async {
    final rowsAffected = await (update(orderItems)
      ..where((tbl) => tbl.id.equals(orderId)))
        .write(
      const OrderItemsCompanion(
        status: Value('entregado'),
      ),
    );
    return rowsAffected > 0;
  }

  // ========================================
  // 4. OBTENER ÓRDENES ENTREGADAS (HISTORIAL)
  // ========================================
  Stream<List<OrderItem>> watchDeliveredOrders() {
    return (select(orderItems)
      ..where((tbl) => tbl.status.equals('entregado') & tbl.reportId.isNull())
      ..orderBy([
            (t) => OrderingTerm(expression: t.orderDate, mode: OrderingMode.desc)
      ]))
        .watch();
  }

  // ========================================
  // 5. ESTADÍSTICAS DEL DÍA (SÓLO ACTIVAS)
  // ========================================
  Stream<Map<String, dynamic>> watchTodayStats() {
    return (select(orderItems)..where((tbl) => tbl.reportId.isNull()))
        .watch()
        .map((orders) {
      double totalSales = 0;
      int totalItems = 0;

      for (var order in orders) {
        totalSales += order.priceAtSale * order.quantity;
        totalItems += order.quantity;
      }

      return {
        'totalSales': totalSales,
        'totalItems': totalItems,
        'ordersCount': orders.length,
      };
    });
  }

  Future<Map<String, dynamic>> getTodayStats() async {
    // Obtener todas las órdenes que no han sido cerradas en un reporte
    final activeOrders = await (select(orderItems)
      ..where((tbl) => tbl.reportId.isNull()))
        .get();

    // Calcular totales
    double totalSales = 0;
    int totalItems = 0;

    for (var order in activeOrders) {
      totalSales += order.priceAtSale * order.quantity;
      totalItems += order.quantity;
    }

    return {
      'totalSales': totalSales,
      'totalItems': totalItems,
      'ordersCount': activeOrders.length,
    };
  }

  // Método para obtener todas las ventas del día (para el reporte PDF) - SÓLO ACTIVAS
  Future<List<OrderItem>> getActiveOrders() {
    return (select(orderItems)
          ..where((tbl) => tbl.reportId.isNull())
          ..orderBy([(t) => OrderingTerm(expression: t.orderDate)]))
        .get();
  }

  // CERRAR ÓRDENES: Vincularlas a un reporte
  Future<int> closeActiveOrders(int reportId) async {
    return await (update(orderItems)..where((tbl) => tbl.reportId.isNull())).write(
      OrderItemsCompanion(reportId: Value(reportId)),
    );
  }

  // ========================================
  // 6. ELIMINAR ORDEN (opcional, para testing)
  // ========================================
  Future<bool> deleteOrder(int orderId) async {
    final rowsDeleted = await (delete(orderItems)
      ..where((tbl) => tbl.id.equals(orderId)))
        .go();
    return rowsDeleted > 0;
  }

  // ========================================
  // 7. LIMPIAR ÓRDENES ANTIGUAS (mantenimiento)
  // ========================================
  Future<int> deleteOldOrders({int daysOld = 30}) async {
    final cutoffDate = DateTime.now().subtract(Duration(days: daysOld));

    return await (delete(orderItems)
      ..where((tbl) => tbl.orderDate.isSmallerThanValue(cutoffDate)))
        .go();
  }
}