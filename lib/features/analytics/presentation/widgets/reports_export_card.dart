import 'dart:io';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:csv/csv.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:spendly/features/analytics/providers/analytics_providers.dart';

class ReportsExportCard extends StatelessWidget {
  final AnalyticsState state;

  const ReportsExportCard({super.key, required this.state});

  Future<void> _exportCSV(BuildContext context) async {
    try {
      final List<List<dynamic>> rows = [
        ['Transaction ID', 'Date', 'Description', 'Category', 'Logged By', 'Amount', 'Payment Method']
      ];

      for (var e in state.filteredExpenses) {
        rows.add([
          e.id,
          DateFormat('yyyy-MM-dd HH:mm:ss').format(e.expenseDate),
          e.description.isEmpty ? e.category : e.description,
          e.category,
          e.createdByName,
          e.amount,
          e.paymentMethod,
        ]);
      }

      final csvString = const ListToCsvConverter().convert(rows);
      final directory = await getTemporaryDirectory();
      final file = File('${directory.path}/spendly_expense_report.csv');
      await file.writeAsString(csvString);

      await Share.shareXFiles([XFile(file.path)], text: 'Spendly Family Expense CSV Report');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export CSV: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _exportPDF(BuildContext context) async {
    try {
      final pdf = pw.Document();
      final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: 'Rs. ', decimalDigits: 0);

      pdf.addPage(
        pw.MultiPage(
          pageFormat: PdfPageFormat.a4,
          build: (pw.Context docContext) {
            return [
              pw.Header(
                level: 0,
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Spendly Expense Report', style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold)),
                    pw.Text(DateFormat('MMM d, yyyy').format(DateTime.now()), style: const pw.TextStyle(fontSize: 10)),
                  ],
                ),
              ),
              pw.SizedBox(height: 14),
              pw.Text('Family Account Summary', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 6),
              pw.Bullet(text: 'Total Spent: ${currencyFmt.format(state.totalSpent)}'),
              pw.Bullet(text: 'Daily Average: ${currencyFmt.format(state.dailyAverage)}/day'),
              pw.Bullet(text: 'Total Transactions: ${state.totalTransactions} Entries'),
              pw.Bullet(text: 'Active Members: ${state.activeMembersCount} family members active'),
              pw.SizedBox(height: 20),
              
              pw.Text('Recent Expenses List', style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              
              // Table of expenses
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Date', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Description', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Category', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('By', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Amount', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...state.filteredExpenses.map((e) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(DateFormat('MMM d').format(e.expenseDate))),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.description.isEmpty ? e.category : e.description)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.category)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(e.createdByName)),
                        pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(currencyFmt.format(e.amount))),
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
      final file = File('${directory.path}/spendly_expense_report.pdf');
      await file.writeAsBytes(await pdf.save());

      await Share.shareXFiles([XFile(file.path)], text: 'Spendly Family Expense PDF Report');
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to export PDF: ${e.toString()}')),
        );
      }
    }
  }

  Future<void> _shareSummary(BuildContext context) async {
    final currencyFmt = NumberFormat.currency(locale: 'en_IN', symbol: '₹', decimalDigits: 0);
    final summaryText = 'Spendly Financial Intelligence Summary:\n'
        '• Total Spent: ${currencyFmt.format(state.totalSpent)}\n'
        '• Daily Average: ${currencyFmt.format(state.dailyAverage)}/day\n'
        '• Transactions: ${state.totalTransactions} entries logged\n'
        '• Active Members: ${state.activeMembersCount}\n'
        '• Financial Health Score: ${state.financialHealthScore}/100 (${state.healthScoreLabel})\n'
        '• Top Category: ${state.categoryShares.isNotEmpty ? state.categoryShares.first.category : "N/A"}\n'
        'Shared via Spendly App.';
    
    await Share.share(summaryText);
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(28),
        side: const BorderSide(color: Color(0xFFF1F5F9)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Export & Share',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Distribute financial intelligence reports',
                      style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                    ),
                  ],
                ),
                Icon(Icons.ios_share_outlined, size: 20, color: Theme.of(context).primaryColor),
              ],
            ),
            const SizedBox(height: 20),

            // Export Actions Grid
            GridView(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 1.6,
              ),
              children: [
                _buildExportButton(
                  context,
                  label: 'Export PDF',
                  icon: Icons.picture_as_pdf_outlined,
                  color: Colors.red[600]!,
                  onTap: () => _exportPDF(context),
                ),
                _buildExportButton(
                  context,
                  label: 'Export CSV',
                  icon: Icons.grid_on_outlined,
                  color: Colors.emerald[600]!,
                  onTap: () => _exportCSV(context),
                ),
                _buildExportButton(
                  context,
                  label: 'Share Summary',
                  icon: Icons.share_outlined,
                  color: Colors.blue[600]!,
                  onTap: () => _shareSummary(context),
                ),
                _buildExportButton(
                  context,
                  label: 'Print Report',
                  icon: Icons.print_outlined,
                  color: Colors.purple[600]!,
                  onTap: () => _exportPDF(context), // Shares PDF natively which has print capabilities
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExportButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.06),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.12)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 18, color: color),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
