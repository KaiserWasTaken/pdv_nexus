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
    
    // 1. Obtener SÓLO las órdenes y gastos activos (no cerrados)
    final orders = await _db.orderDao.getActiveOrders();
    final expenses = await _db.expenseDao.getActiveExpenses();

    if (orders.isEmpty && expenses.isEmpty) {
      throw Exception("No hay ventas ni gastos activos para cerrar el día.");
    }

    final pdf = pw.Document();
    
    // Agrupación de datos de ventas
    final Map<String, int> productCounts = {};
    final Map<String, double> productRevenue = {};
    final Map<String, double> productCash = {};
    final Map<String, double> productCard = {};
    final Map<String, int> rentalCounts = {'Xbox': 0, 'Switch': 0, 'PS5': 0};
    final Map<String, double> rentalRevenue = {'Xbox': 0.0, 'Switch': 0.0, 'PS5': 0.0};
    final Map<String, double> rentalCash = {'Xbox': 0.0, 'Switch': 0.0, 'PS5': 0.0, 'Otros': 0.0}; 
    final Map<String, double> rentalCard = {'Xbox': 0.0, 'Switch': 0.0, 'PS5': 0.0, 'Otros': 0.0}; 
    double grandTotalSales = 0; // ✅ Restaurado
    double cashSales = 0;       // ✅ Restaurado
    double cardSales = 0;       // ✅ Restaurado

    for (var order in orders) {
      final subtotal = order.priceAtSale * order.quantity;
      grandTotalSales += subtotal;

      if (order.paymentMethod == 'Tarjeta') {
        cardSales += subtotal;
      } else {
        cashSales += subtotal;
      }
      
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
        rentalRevenue[type] = (rentalRevenue[type] ?? 0.0) + subtotal;
        
        // ✅ Desglose de rentas por método
        if (order.paymentMethod == 'Tarjeta') {
          rentalCard[type] = (rentalCard[type] ?? 0.0) + subtotal;
        } else {
          rentalCash[type] = (rentalCash[type] ?? 0.0) + subtotal;
        }
      } else {
        productCounts[order.productName] = (productCounts[order.productName] ?? 0) + order.quantity;
        productRevenue[order.productName] = (productRevenue[order.productName] ?? 0.0) + subtotal;
        
        if (order.paymentMethod == 'Tarjeta') {
          productCard[order.productName] = (productCard[order.productName] ?? 0.0) + subtotal;
        } else {
          productCash[order.productName] = (productCash[order.productName] ?? 0.0) + subtotal;
        }
      }
    }

    // Agrupación de datos de gastos
    double grandTotalExpenses = 0;
    for (var exp in expenses) {
      grandTotalExpenses += exp.amount;
    }

    // 2. CREAR REGISTRO DE REPORTE DIARIO EN BD
    final reportId = await _db.into(_db.dailyReports).insert(
      DailyReportsCompanion.insert(
        date: now,
        totalCash: grandTotalSales - grandTotalExpenses, // Balance Neto
        pdfPath: 'generado_${now.millisecondsSinceEpoch}.pdf',
      ),
    );

    // 3. VINCULAR ÓRDENES Y GASTOS AL REPORTE (CERRAR DÍA)
    await _db.orderDao.closeActiveOrders(reportId);
    await _db.expenseDao.closeActiveExpenses(reportId);

    // ✅ Preparar Resumen de Productos Ordenado por Ventas
    final sortedProductSummary = productCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Estilos para el PDF
    final headerStyle = pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 10);
    final headerDecoration = const pw.BoxDecoration(color: PdfColor.fromInt(0xFF00187A)); // Nexus Blue
    final oddRowDecoration = const pw.BoxDecoration(color: PdfColors.grey100);
    final baseTextStyle = const pw.TextStyle(fontSize: 9);

    // 4. GENERAR PDF
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) => [
          pw.Header(
            level: 0,
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("NEXUS POS - REPORTE DIARIO", 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 24, color: PdfColor.fromInt(0xFF00187A))),
                pw.Text(DateFormat('dd/MM/yyyy').format(now), style: const pw.TextStyle(fontSize: 16)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          pw.Text("RESUMEN DE PRODUCTOS (ORDENADO POR VENTAS)", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blueGrey800)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Cant', 'Producto', 'EFE', 'TAR', 'Total'],
            data: sortedProductSummary.map((e) => [
              e.value.toString(),
              e.key,
              "\$${(productCash[e.key] ?? 0.0).toStringAsFixed(0)}",
              "\$${(productCard[e.key] ?? 0.0).toStringAsFixed(0)}",
              "\$${productRevenue[e.key]!.toStringAsFixed(2)}"
            ]).toList(),
            headerStyle: headerStyle,
            headerDecoration: headerDecoration,
            oddRowDecoration: oddRowDecoration,
            cellStyle: baseTextStyle,
            cellAlignment: pw.Alignment.centerLeft,
            headerAlignment: pw.Alignment.centerLeft,
          ),
          pw.SizedBox(height: 20),

          pw.Text("RESUMEN DE RENTAS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blueGrey800)),
          pw.SizedBox(height: 8),
          pw.TableHelper.fromTextArray(
            headers: ['Cant', 'Consola', 'EFE', 'TAR', 'Total'],
            data: rentalCounts.entries.where((e) => e.value > 0).map((e) => [
              e.value.toString(),
              e.key,
              "\$${(rentalCash[e.key] ?? 0.0).toStringAsFixed(0)}",
              "\$${(rentalCard[e.key] ?? 0.0).toStringAsFixed(0)}",
              "\$${rentalRevenue[e.key]!.toStringAsFixed(2)}"
            ]).toList(),
            headerStyle: headerStyle,
            headerDecoration: headerDecoration,
            oddRowDecoration: oddRowDecoration,
            cellStyle: baseTextStyle,
          ),
          pw.SizedBox(height: 20),

          pw.Container(
            padding: const pw.EdgeInsets.all(10),
            decoration: const pw.BoxDecoration(color: PdfColors.blue50),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text("Ventas en Efectivo: \$${cashSales.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 12, color: PdfColors.green900)),
                pw.Text("Ventas con Tarjeta: \$${cardSales.toStringAsFixed(2)}", style: const pw.TextStyle(fontSize: 12, color: PdfColors.blue900)),
                pw.Divider(color: PdfColors.blueGrey),
                pw.Text("TOTAL VENTAS: \$${grandTotalSales.toStringAsFixed(2)}", 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 16, color: PdfColor.fromInt(0xFF00187A))),
              ],
            ),
          ),
          
          if (expenses.isNotEmpty) ...[
            pw.SizedBox(height: 30),
            pw.Text("RESUMEN DE GASTOS", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.red900)),
            pw.SizedBox(height: 8),
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey300),
              children: [
                // Header manual
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.red900),
                  children: ['Descripción', 'Categoría', 'Método', 'Monto'].map((h) => 
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(5),
                      child: pw.Text(h, style: headerStyle),
                    )
                  ).toList(),
                ),
                // Filas con color por categoría
                ...expenses.map((e) {
                  final bool isEmpresa = e.category.toLowerCase().contains('empresa');
                  return pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: isEmpresa ? PdfColors.red50 : PdfColors.purple50,
                    ),
                    children: [
                      e.description,
                      e.category,
                      e.paymentMethod,
                      "\$${e.amount.toStringAsFixed(2)}"
                    ].map((val) => 
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(5),
                        child: pw.Text(val, style: baseTextStyle),
                      )
                    ).toList(),
                  );
                }),
              ],
            ),
            pw.SizedBox(height: 10),
            pw.Container(
              alignment: pw.Alignment.centerRight,
              child: pw.Text("TOTAL GASTOS: \$${grandTotalExpenses.toStringAsFixed(2)}", 
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.red900)),
            ),
          ],

          pw.SizedBox(height: 30),
          pw.Container(
            padding: const pw.EdgeInsets.all(15),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: (grandTotalSales - grandTotalExpenses) >= 0 ? PdfColors.green : PdfColors.red, width: 2),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(10)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text("BALANCE FINAL NETO:", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 18)),
                pw.Text("\$${(grandTotalSales - grandTotalExpenses).toStringAsFixed(2)}", 
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 22, 
                    color: (grandTotalSales - grandTotalExpenses) >= 0 ? PdfColors.green900 : PdfColors.red900)),
              ],
            ),
          ),
          
          pw.SizedBox(height: 40),
          pw.Text("DETALLE CRONOLÓGICO DE OPERACIONES", style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14, color: PdfColors.blueGrey800)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300),
            children: [
              // Header
              pw.TableRow(
                decoration: headerDecoration,
                children: ['Hora', 'Item', 'Precio', 'Cant', 'Método', 'Subtotal'].map((h) => 
                  pw.Padding(
                    padding: const pw.EdgeInsets.all(5),
                    child: pw.Text(h, style: headerStyle),
                  )
                ).toList(),
              ),
              // Filas con color por método (Excluyendo $0)
              ...orders.where((o) => o.priceAtSale > 0).map((o) {
                final bool isTarjeta = o.paymentMethod == 'Tarjeta';
                return pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: isTarjeta ? PdfColors.blue50 : PdfColors.green50,
                  ),
                  children: [
                    DateFormat('HH:mm').format(o.orderDate.toLocal()),
                    o.productName,
                    "\$${o.priceAtSale.toStringAsFixed(0)}",
                    o.quantity.toString(),
                    isTarjeta ? 'TAR' : 'EFE',
                    "\$${(o.priceAtSale * o.quantity).toStringAsFixed(0)}"
                  ].map((val) => 
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(4),
                      child: pw.Text(val, style: const pw.TextStyle(fontSize: 8)),
                    )
                  ).toList(),
                );
              }),
            ],
          ),
        ],
      ),
    );

    await Printing.layoutPdf(onLayout: (PdfPageFormat format) async => pdf.save());
  }
}
