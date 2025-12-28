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
  Future<void> insertOrder(String productName, double price, int quantity) async {
    await into(orderItems).insert(
      OrderItemsCompanion.insert(
        productName: productName,
        priceAtSale: price,
        quantity: Value(quantity), // ← ENVUELTO EN Value()
        // status y orderDate usan valores por defecto
      ),
    );
  }

  // Método para insertar múltiples items (desde el carrito)
  Future<void> insertMultipleOrders(List<Map<String, dynamic>> items) async {
    await batch((batch) {
      for (var item in items) {
        batch.insert(
          orderItems,
          OrderItemsCompanion.insert(
            productName: item['name'] as String,
            priceAtSale: item['price'] as double,
            quantity: Value(item['quantity'] as int), // ← ENVUELTO EN Value()
          ),
        );
      }
    });
  }

  // ========================================
  // 2. OBTENER ÓRDENES PENDIENTES
  // ========================================
  // Stream que se actualiza automáticamente cuando cambia la BD
  Stream<List<OrderItem>> watchPendingOrders() {
    return (select(orderItems)
      ..where((tbl) => tbl.status.equals('pendiente'))
      ..orderBy([
            (t) => OrderingTerm(expression: t.orderDate, mode: OrderingMode.desc)
      ]))
        .watch();
  }

  // Método de consulta única (sin stream)
  Future<List<OrderItem>> getPendingOrders() {
    return (select(orderItems)
      ..where((tbl) => tbl.status.equals('pendiente'))
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
      ..where((tbl) => tbl.status.equals('entregado'))
      ..orderBy([
            (t) => OrderingTerm(expression: t.orderDate, mode: OrderingMode.desc)
      ]))
        .watch();
  }

  // ========================================
  // 5. ESTADÍSTICAS DEL DÍA
  // ========================================
  Future<Map<String, dynamic>> getTodayStats() async {
    final today = DateTime.now();
    final startOfDay = DateTime(today.year, today.month, today.day);

    // Obtener todas las órdenes del día
    final todaysOrders = await (select(orderItems)
      ..where((tbl) => tbl.orderDate.isBiggerOrEqualValue(startOfDay)))
        .get();

    // Calcular totales
    double totalSales = 0;
    int totalItems = 0;
    int pendingCount = 0;
    int deliveredCount = 0;

    for (var order in todaysOrders) {
      totalSales += order.priceAtSale * order.quantity;
      totalItems += order.quantity;

      if (order.status == 'pendiente') {
        pendingCount++;
      } else if (order.status == 'entregado') {
        deliveredCount++;
      }
    }

    return {
      'totalSales': totalSales,
      'totalItems': totalItems,
      'pendingOrders': pendingCount,
      'deliveredOrders': deliveredCount,
      'ordersCount': todaysOrders.length,
    };
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