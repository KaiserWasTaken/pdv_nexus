import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:intl/intl.dart';
import '../database/database.dart';

class ReportService {
  final AppDatabase _db;

  ReportService(this._db);

  Future<void> generateDailyReport() async {
    final now = DateTime.now();
    
    // 1. Obtener SÓLO las órdenes activas (no cerradas)
    final orders = await _db.orderDao.getActiveOrders();

    if (orders.isEmpty) {
      throw Exception("No hay ventas activas para cerrar el día.");
    }

    final pdf = pw.Document();
    
    // Agrupación de datos
    final Map<String, int> productCounts = {};
    final Map<String, double> productRevenue = {};
    final Map<String, int> rentalCounts = {'Xbox': 0, 'Switch': 0, 'PS5': 0};
    final Map<String, double> rentalRevenue = {'Xbox': 0.0, 'Switch': 0.0, 'PS5': 0.0};
    double grandTotal = 0;

    for (var order in orders) {
      grandTotal += order.priceAtSale * order.quantity;

      final category = (order.category ?? 'Otros').trim();

      if (category.toLowerCase() == 'rentas') {
        String type = 'Otros';
        final name = order.productName;
        if (name.contains('Xbox')) {
          type = 'Xbox';
        } else if (name.contains('Switch')) {
          type = 'Switch';
        } else if (name.contains('PS5')) {
          type = 'PS5';
        }
        
        rentalCounts[type] = (rentalCounts[type] ?? 0) + order.quantity;
        rentalRevenue[type] = (rentalRevenue[type] ?? 0.0) + (order.priceAtSale * order.quantity);
      } else {
        productCounts[order.productName] = (productCounts[order.productName] ?? 0) + order.quantity;
        productRevenue[order.productName] = (productRevenue[order.productName] ?? 0.0) + (order.priceAtSale * order.quantity);
      }
    }

    // 2. CREAR REGISTRO DE REPORTE DIARIO EN BD
    final reportId = await _db.into(_db.dailyReports).insert(
      DailyReportsCompanion.insert(
        date: now,
        totalCash: grandTotal,
        pdfPath: 'generado_${now.millisecondsSinceEpoch}.pdf',
      ),
    );

    // 3. VINCULAR ÓRDENES AL REPORTE (CERRAR DÍA)
    await _db.orderDao.closeActiveOrders(reportId);

    // 4. GENERAR PDF
    pdf.addPage(
// ...
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("NEXUS POS - REPORTE DIARIO", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24)),
                pw.Text(DateFormat('dd/MM/yyyy').format(now)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          pw.Text("RESUMEN DE PRODUCTOS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
          pw.Divider(),
          pw.TableHelper.fromTextArray(
            headers: ['Cant', 'Producto', 'Total'],
            data: productCounts.entries.map((e) => [
              e.value.toString(),
              e.key,
              "\$${productRevenue[e.key]!.toStringAsFixed(2)}"
            ]).toList(),
          ),
          pw.SizedBox(height: 20),

          pw.Text("RESUMEN DE RENTAS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
          pw.Divider(),
          pw.TableHelper.fromTextArray(
            headers: ['Cant', 'Consola', 'Total'],
            data: rentalCounts.entries.where((e) => e.value > 0).map((e) => [
              e.value.toString(),
              e.key,
              "\$${rentalRevenue[e.key]!.toStringAsFixed(2)}"
            ]).toList(),
          ),
          pw.SizedBox(height: 30),

          pw.Container(
            alignment: pw.Alignment.centerRight,
            child: pw.Text("TOTAL DEL DÍA: \$${grandTotal.toStringAsFixed(2)}", 
              style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 22, color: PdfColors.blue900)),
          ),
          
          pw.SizedBox(height: 40),
          pw.Text("DETALLE CRONOLÓGICO", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14)),
          pw.Divider(),
          pw.TableHelper.fromTextArray(
            headers: ['Hora', 'Item', 'Precio', 'Cant', 'Subtotal'],
            data: orders.map((o) => [
              DateFormat('HH:mm').format(o.orderDate.toLocal()), // ✅ Asegurar hora local
              o.productName,
              "\$${o.priceAtSale.toStringAsFixed(0)}",
              o.quantity.toString(),
              "\$${(o.priceAtSale * o.quantity).toStringAsFixed(0)}"
            ]).toList(),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
