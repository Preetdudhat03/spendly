import 'dart:io';
import 'package:csv/csv.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:spendly/models/expense.dart';

class ReportService {
  /// Converts expenses list into a CSV and triggers the share sheet
  static Future<void> exportAndShareCsv(List<Expense> expenses) async {
    if (expenses.isEmpty) return;

    final csvData = [
      ['Date', 'Category', 'Description', 'Amount', 'Payment Method', 'Logged By'],
      ...expenses.map((e) => [
            DateFormat('yyyy-MM-dd').format(e.expenseDate),
            e.category,
            e.description,
            e.amount.toString(),
            e.paymentMethod,
            e.createdByName,
          ])
    ];

    final csvString = const ListToCsvConverter().convert(csvData);

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/family_expenses_history.csv');
    await file.writeAsString(csvString);

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Here is the family expense history report.',
    );
  }

  /// Generates a PDF summary report and triggers the share sheet
  static Future<void> exportAndSharePdf({
    required List<Expense> expenses,
    required String familyName,
    required double budgetLimit,
  }) async {
    final pdf = pw.Document();

    final now = DateTime.now();
    final monthStr = DateFormat('MMMM yyyy').format(now);
    final monthTotal = expenses
        .where((e) => e.expenseDate.year == now.year && e.expenseDate.month == now.month)
        .fold<double>(0, (sum, e) => sum + e.amount);

    final currencyFormat = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs ', decimalDigits: 0);

    // Group categories
    final Map<String, double> catTotals = {};
    for (var e in expenses.where((e) => e.expenseDate.year == now.year && e.expenseDate.month == now.month)) {
      catTotals[e.category] = (catTotals[e.category] ?? 0) + e.amount;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return [
            pw.Header(
              level: 0,
              child: pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('Spendly - Family Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                  pw.Text(monthStr, style: const pw.TextStyle(fontSize: 14)),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Text('Family Group: $familyName', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 18),

            // Summary grid/table
            pw.Text('Monthly Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Total Spent this Month:'),
                pw.Text(currencyFormat.format(monthTotal), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Monthly Budget Limit:'),
                pw.Text(currencyFormat.format(budgetLimit)),
              ],
            ),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Budget Status:'),
                pw.Text(
                  monthTotal > budgetLimit ? 'OVER BUDGET' : 'WITHIN BUDGET',
                  style: pw.TextStyle(
                    fontWeight: pw.FontWeight.bold,
                    color: monthTotal > budgetLimit ? PdfColors.red : PdfColors.green,
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 24),

            // Category Breakdown Table
            pw.Text('Category Breakdown', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Table(
              border: const pw.TableBorder(bottom: pw.BorderSide(color: PdfColors.grey300)),
              children: catTotals.entries.map((entry) {
                final percent = monthTotal > 0 ? (entry.value / monthTotal) * 100 : 0.0;
                return pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.symmetric(vertical: 4), child: pw.Text(entry.key)),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Text(currencyFormat.format(entry.value), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.symmetric(vertical: 4),
                      child: pw.Text('${percent.toStringAsFixed(1)}%'),
                    ),
                  ],
                );
              }).toList(),
            ),
            pw.SizedBox(height: 28),

            // Expenses History Table
            pw.Text('Recent Expenses List', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
            pw.Divider(),
            pw.Table(
              border: const pw.TableBorder(bottom: pw.BorderSide(color: PdfColors.grey300)),
              children: [
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Logged By', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...expenses.take(20).map((e) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(DateFormat('dd-MMM').format(e.expenseDate))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.category)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.description)),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(6),
                        child: pw.Text(currencyFormat.format(e.amount), style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.createdByName)),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/family_monthly_report.pdf');
    await file.writeAsBytes(await pdf.save());

    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Here is the family monthly PDF report.',
    );
  }
}
