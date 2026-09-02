import 'dart:io';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../core/state/app_state.dart';
import '../../core/theme/app_theme.dart';

class ExportDataDialog extends StatefulWidget {
  const ExportDataDialog({super.key});

  @override
  State<ExportDataDialog> createState() => _ExportDataDialogState();
}

class _ExportDataDialogState extends State<ExportDataDialog> {
  String _selectedFormat = 'CSV'; // 'CSV', 'PDF'
  String _selectedRange = 'This month'; // 'This month', 'Last 3 months', 'All time'
  bool _isExporting = false;

  /// Helper to filter transactions based on the selected date range
  List<TransactionItem> _getFilteredTransactions(List<TransactionItem> allTxs) {
    if (_selectedRange == 'All time') return allTxs;

    return allTxs.where((t) {
      final dateLower = t.date.toLowerCase();
      if (dateLower.contains('today')) return true;
      if (_selectedRange == 'This month') {
        if (dateLower.contains('yesterday')) return true;
        return true;
      }
      return true;
    }).toList();
  }

  /// Generate clean, clear, and professional CSV statement
  String _generateCsv(List<TransactionItem> txs, AppStateModel appState) {
    final buffer = StringBuffer();
    final userName = appState.userName.isNotEmpty ? appState.userName : 'Thaili User';
    final currCode = appState.currentCurrencyData.code;
    final currSymbol = appState.currentCurrencyData.symbol;
    final nowStr = DateTime.now().toString().split('.')[0];

    double totalIncome = 0;
    double totalExpense = 0;

    for (final t in txs) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    String sanitize(String input) {
      if (input.contains(',') || input.contains('"') || input.contains('\n')) {
        return '"${input.replaceAll('"', '""')}"';
      }
      return input;
    }

    buffer.writeln('================================================================================');
    buffer.writeln('THAILI FINANCIAL STATEMENT REPORT');
    buffer.writeln('================================================================================');
    buffer.writeln('Account Holder   : ${sanitize(userName)}');
    buffer.writeln('Generation Date  : $nowStr');
    buffer.writeln('Selected Period  : $_selectedRange');
    buffer.writeln('Primary Currency : $currCode ($currSymbol)');
    buffer.writeln('Total Records    : ${txs.length}');
    buffer.writeln('================================================================================');
    buffer.writeln();

    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('TRANSACTION LEDGER');
    buffer.writeln('--------------------------------------------------------------------------------');
    buffer.writeln('ID,Date,Title,Category,Type,Amount ($currSymbol),Payment Method,Note');

    for (final t in txs) {
      final typeLabel = t.type == TransactionType.income ? 'Income' : 'Expense';
      final formattedAmount = '${t.type == TransactionType.income ? '+' : '-'}${t.amount.toStringAsFixed(2)}';
      buffer.writeln(
        '${t.id},${sanitize(t.date)},${sanitize(t.title)},${sanitize(t.category)},'
        '$typeLabel,$formattedAmount,${sanitize(t.paymentMethod)},${sanitize(t.note)}',
      );
    }

    buffer.writeln();
    buffer.writeln('================================================================================');
    buffer.writeln('EXECUTIVE FINANCIAL SUMMARY');
    buffer.writeln('================================================================================');
    buffer.writeln('Metric,Amount ($currSymbol)');
    buffer.writeln('Total Income,+${totalIncome.toStringAsFixed(2)}');
    buffer.writeln('Total Expense,-${totalExpense.toStringAsFixed(2)}');
    buffer.writeln('Net Balance,${(totalIncome - totalExpense).toStringAsFixed(2)}');
    buffer.writeln('================================================================================');

    return buffer.toString();
  }

  /// Generate executive-grade PDF document
  Future<List<int>> _generatePdf(List<TransactionItem> txs, AppStateModel appState) async {
    final pdf = pw.Document(
      title: 'Thaili Financial Statement',
      author: 'Thaili Financial Workspace',
    );
    final userName = appState.userName.isNotEmpty ? appState.userName : 'Thaili User';
    final currCode = appState.currentCurrencyData.code;
    final nowStr = DateTime.now().toString().split('.')[0];

    double totalIncome = 0;
    double totalExpense = 0;

    for (final t in txs) {
      if (t.type == TransactionType.income) {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
      }
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(36),
        header: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(bottom: 20),
            padding: const pw.EdgeInsets.only(bottom: 10),
            decoration: const pw.BoxDecoration(
              border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal800, width: 1.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      width: 24,
                      height: 24,
                      decoration: pw.BoxDecoration(
                        color: PdfColors.teal800,
                        borderRadius: pw.BorderRadius.circular(6),
                      ),
                      child: pw.Center(
                        child: pw.Text('T', style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 14)),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text('THAILI FINANCIAL WORKSPACE', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                  ],
                ),
                pw.Text('CONFIDENTIAL LEDGER STATEMENT', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          );
        },
        footer: (pw.Context context) {
          return pw.Container(
            margin: const pw.EdgeInsets.only(top: 20),
            padding: const pw.EdgeInsets.only(top: 8),
            decoration: const pw.BoxDecoration(
              border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 0.5)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('100% Offline & Private Financial Statement | Thaili App', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                pw.Text('Page ${context.pageNumber} of ${context.pagesCount}', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
              ],
            ),
          );
        },
        build: (pw.Context context) {
          return [
            // Title & Meta Card
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                color: PdfColors.teal50,
                borderRadius: pw.BorderRadius.circular(10),
                border: pw.Border.all(color: PdfColors.teal200),
              ),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('FINANCIAL ACTIVITY STATEMENT', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.teal900)),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: pw.BoxDecoration(color: PdfColors.teal800, borderRadius: pw.BorderRadius.circular(6)),
                        child: pw.Text(currCode, style: pw.TextStyle(color: PdfColors.white, fontSize: 10, fontWeight: pw.FontWeight.bold)),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 10),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('Account Holder: $userName', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.grey800)),
                      pw.Text('Period: $_selectedRange', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                      pw.Text('Exported: $nowStr', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                    ],
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 16),

            // Executive Summary KPIs Box
            pw.Row(
              children: [
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.green50,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.green300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TOTAL INCOME', style: const pw.TextStyle(fontSize: 8, color: PdfColors.green800)),
                        pw.SizedBox(height: 4),
                        pw.Text('+$currCode ${totalIncome.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.green900)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.red50,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: PdfColors.red300),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('TOTAL EXPENSES', style: const pw.TextStyle(fontSize: 8, color: PdfColors.red800)),
                        pw.SizedBox(height: 4),
                        pw.Text('-$currCode ${totalExpense.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.red900)),
                      ],
                    ),
                  ),
                ),
                pw.SizedBox(width: 10),
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: (totalIncome - totalExpense) >= 0 ? PdfColors.teal50 : PdfColors.amber50,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: (totalIncome - totalExpense) >= 0 ? PdfColors.teal300 : PdfColors.amber400),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('NET CASH FLOW', style: pw.TextStyle(fontSize: 8, color: (totalIncome - totalExpense) >= 0 ? PdfColors.teal800 : PdfColors.amber900)),
                        pw.SizedBox(height: 4),
                        pw.Text('$currCode ${(totalIncome - totalExpense).toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: (totalIncome - totalExpense) >= 0 ? PdfColors.teal900 : PdfColors.amber900)),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 20),
            pw.Text('Transaction Log (${txs.length} total entries)', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.grey900)),
            pw.SizedBox(height: 8),

            if (txs.isEmpty)
              pw.Container(
                width: double.infinity,
                padding: const pw.EdgeInsets.all(24),
                decoration: pw.BoxDecoration(color: PdfColors.grey100, borderRadius: pw.BorderRadius.circular(8)),
                child: pw.Center(child: pw.Text('No transactions recorded for the selected period.', style: const pw.TextStyle(color: PdfColors.grey700))),
              )
            else
              pw.TableHelper.fromTextArray(
                headers: ['Date', 'Title', 'Category', 'Payment', 'Type', 'Amount ($currCode)'],
                data: txs.map((t) {
                  final isIncome = t.type == TransactionType.income;
                  return [
                    t.date,
                    t.title,
                    t.category,
                    t.paymentMethod,
                    isIncome ? 'Income' : 'Expense',
                    '${isIncome ? '+' : '-'}$currCode ${t.amount.toStringAsFixed(2)}',
                  ];
                }).toList(),
                border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.white, fontSize: 9),
                headerDecoration: const pw.BoxDecoration(color: PdfColors.teal800),
                cellStyle: const pw.TextStyle(fontSize: 8.5),
                cellPadding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 5),
                cellAlignment: pw.Alignment.centerLeft,
                rowDecoration: const pw.BoxDecoration(color: PdfColors.white),
                oddRowDecoration: const pw.BoxDecoration(color: PdfColors.grey50),
                columnWidths: {
                  0: const pw.FlexColumnWidth(1.1),
                  1: const pw.FlexColumnWidth(2.2),
                  2: const pw.FlexColumnWidth(1.4),
                  3: const pw.FlexColumnWidth(1.2),
                  4: const pw.FlexColumnWidth(1.0),
                  5: const pw.FlexColumnWidth(1.5),
                },
              ),
          ];
        },
      ),
    );

    return await pdf.save();
  }

  /// Perform Export: isShareMode = false for saving to Device Storage, true for Share Sheet
  Future<void> _exportAndSave({required bool isShareMode}) async {
    setState(() => _isExporting = true);

    try {
      final appState = AppStateModel();
      final filteredTxs = _getFilteredTransactions(appState.transactions);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileExtension = _selectedFormat.toLowerCase();
      final fileName = 'Thaili_Ledger_$timestamp.$fileExtension';

      List<int> fileBytes;
      if (_selectedFormat == 'CSV') {
        final csvContent = _generateCsv(filteredTxs, appState);
        fileBytes = csvContent.codeUnits;
      } else {
        fileBytes = await _generatePdf(filteredTxs, appState);
      }

      if (!mounted) return;
      final messenger = ScaffoldMessenger.of(context);

      if (isShareMode) {
        // Use application documents directory for shareable files
        Directory? shareDir;
        try {
          shareDir = await getApplicationDocumentsDirectory();
        } catch (_) {}
        shareDir ??= await getTemporaryDirectory();

        final shareFile = File('${shareDir.path}/$fileName');
        await shareFile.writeAsBytes(fileBytes);

        final mimeType = _selectedFormat == 'CSV' ? 'text/csv' : 'application/pdf';
        final xFile = XFile(
          shareFile.path,
          mimeType: mimeType,
          name: fileName,
        );

        setState(() => _isExporting = false);
        if (mounted) Navigator.pop(context);

        // ignore: deprecated_member_use
        await Share.shareXFiles(
          [xFile],
          subject: 'Thaili Financial Statement',
          text: 'Thaili Financial Statement ($_selectedRange)',
        );
      } else {
        // Direct Save to Internal Storage / User File Picker
        String? savedPath;

        try {
          final mimeType = _selectedFormat == 'CSV' ? 'text/csv' : 'application/pdf';
          final resultUri = await FilePickerPlatform.instance.saveFile(
            dialogTitle: 'Select destination folder to save your export file:',
            fileName: fileName,
            bytes: Uint8List.fromList(fileBytes),
            mimeType: mimeType,
          );
          if (resultUri != null) {
            savedPath = resultUri.toFilePath();
          }
        } catch (e) {
          debugPrint('FilePicker saveFile fallback: $e');
        }

        if (savedPath == null) {
          // Fallback: save directly to public Downloads folder or Documents folder
          Directory? targetDir;
          try {
            targetDir = await getDownloadsDirectory();
          } catch (_) {}
          targetDir ??= await getApplicationDocumentsDirectory();

          final destFile = File('${targetDir.path}/$fileName');
          await destFile.writeAsBytes(fileBytes);
          savedPath = destFile.path;
        }

        if (!mounted) return;
        setState(() => _isExporting = false);
        Navigator.pop(context);

        messenger.showSnackBar(
          SnackBar(
            backgroundColor: const Color(0xFF0D9488),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 22),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Saved to Device Storage! ($_selectedFormat)',
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text('Path: $savedPath',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 11, color: Colors.white70)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }
    } catch (e) {
      debugPrint('Export error: $e');
      if (mounted) {
        setState(() => _isExporting = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            content: Text('Export failed: $e', style: const TextStyle(fontWeight: FontWeight.w600)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textColor = isDark ? AppTheme.textPrimary : AppTheme.textPrimaryLight;
    final subTextColor =
        isDark ? AppTheme.textSecondary : AppTheme.textSecondaryLight;
    final cardBg = isDark ? AppTheme.cardColor : AppTheme.surfaceLight;
    final outlineColor =
        isDark ? const Color(0xFF243348) : const Color(0xFFE2E8F0);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
          Center(
            child: Container(
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: outlineColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 18),

          Text(
            'Export Your Data',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: textColor),
          ),
          const SizedBox(height: 4),
          Text(
            'Save formatted financial statement directly to device storage',
            style: TextStyle(fontSize: 13, color: subTextColor),
          ),
          const SizedBox(height: 22),

          // Format Options: CSV | PDF
          Text('Format', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: subTextColor)),
          const SizedBox(height: 8),
          Row(
            children: ['CSV', 'PDF'].map((fmt) {
              final isSelected = _selectedFormat == fmt;
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: fmt == 'CSV' ? 10.0 : 0.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedFormat = fmt),
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? AppTheme.primaryLight.withValues(alpha: 0.12) : cardBg,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isSelected ? AppTheme.primaryLight : outlineColor, width: isSelected ? 1.5 : 1),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(fmt == 'CSV' ? Icons.table_chart_outlined : Icons.picture_as_pdf_outlined,
                              size: 18, color: isSelected ? AppTheme.primaryLight : subTextColor),
                          const SizedBox(width: 8),
                          Text(
                            fmt,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected ? AppTheme.primaryLight : textColor,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 20),

          // Date Range Options: This month | Last 3 months | All time
          Text('Date Range', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: subTextColor)),
          const SizedBox(height: 8),
          Column(
            children: ['This month', 'Last 3 months', 'All time'].map((rng) {
              final isSelected = _selectedRange == rng;
              return Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: InkWell(
                  onTap: () => setState(() => _selectedRange = rng),
                  borderRadius: BorderRadius.circular(14),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: isSelected ? AppTheme.primaryLight.withValues(alpha: 0.08) : cardBg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isSelected ? AppTheme.primaryLight : outlineColor, width: isSelected ? 1.5 : 1),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          rng,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected ? AppTheme.primaryLight : textColor,
                          ),
                        ),
                        if (isSelected)
                          const Icon(Icons.check_circle_rounded, color: AppTheme.primaryLight, size: 18),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),

          const SizedBox(height: 24),

          // Action Buttons: Save to Device & Share
          if (_isExporting)
            const SizedBox(
              width: double.infinity,
              height: 52,
              child: Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5)),
                    SizedBox(width: 12),
                    Text('Generating professional report...', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                  ],
                ),
              ),
            )
          else
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: SizedBox(
                    height: 52,
                    child: ElevatedButton.icon(
                      onPressed: () => _exportAndSave(isShareMode: false),
                      icon: const Icon(Icons.save_alt_rounded, size: 20),
                      label: const Text('Save to Storage', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryLight,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        elevation: 2,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: SizedBox(
                    height: 52,
                    child: OutlinedButton.icon(
                      onPressed: () => _exportAndSave(isShareMode: true),
                      icon: const Icon(Icons.share_rounded, size: 18),
                      label: const Text('Share', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: textColor,
                        side: BorderSide(color: outlineColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
