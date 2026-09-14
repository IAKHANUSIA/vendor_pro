import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/bill.dart';
import '../models/firm.dart';
import '../database/database_service.dart';

class PrintService {
  // 1. Bulk Month Bills Print (4 Bills Per A4 Page - Compact Indian Vendor Standard)
  static Future<void> printMonthBillsPdf(
    BuildContext context,
    List<Bill> bills,
    Firm firm,
    String monthYear,
  ) async {
    final pdf = pw.Document();

    // Group bills in chunks of 4 per page
    for (int i = 0; i < bills.length; i += 4) {
      final chunk = bills.sublist(i, (i + 4 > bills.length) ? bills.length : i + 4);

      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context ctx) {
            return pw.GridView(
              crossAxisCount: 2,
              childAspectRatio: 1.35,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: chunk.map((b) => _buildCompactBillBox(b, firm)).toList(),
            );
          },
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Bills_$monthYear.pdf',
    );
  }

  // 2. Single Bill Print (Thermal / Half A4 format)
  static Future<void> printSingleBillPdf(
    BuildContext context,
    Bill bill,
    Firm firm,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(20),
        build: (pw.Context ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey600, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(firm.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                      pw.Text('${firm.address} | Phone: ${firm.phone}', style: const pw.TextStyle(fontSize: 9)),
                    ],
                  ),
                ),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                pw.SizedBox(height: 6),

                // Customer & Bill Row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Customer: ${bill.customerName}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Code: #${bill.customerNo}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Bill No: ${bill.billNo}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Month: ${bill.monthYear}', style: const pw.TextStyle(fontSize: 10)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 12),

                // Paper Items Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Item / Publication', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Days', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Amount (Rs)', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    ...bill.paperBreakdown.values.map((p) => pw.TableRow(
                          children: [
                            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(p.name, style: const pw.TextStyle(fontSize: 9))),
                            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('${p.daysCount}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 9))),
                            pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(p.totalCost.toStringAsFixed(0), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 9))),
                          ],
                        )),
                  ],
                ),
                pw.SizedBox(height: 10),

                // Summary Lines
                if (bill.deliveryCharge > 0)
                  _buildPdfSummaryRow('Delivery Charge:', 'Rs ${bill.deliveryCharge.toStringAsFixed(0)}'),
                if (bill.vacationDeduction > 0)
                  _buildPdfSummaryRow('Vacation Deduction (${bill.vacationDays} d):', '-Rs ${bill.vacationDeduction.toStringAsFixed(0)}'),
                if (bill.pastBalance > 0)
                  _buildPdfSummaryRow('Previous Arrears:', 'Rs ${bill.pastBalance.toStringAsFixed(0)}'),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),
                _buildPdfSummaryRow('Total Net Payable:', 'Rs ${bill.finalPayable.toStringAsFixed(0)}', isBold: true),
                pw.SizedBox(height: 8),

                // UPI / Payment Info
                if (firm.upiId.isNotEmpty)
                  pw.Container(
                    padding: const pw.EdgeInsets.all(6),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text('Pay via GPay/PhonePe UPI: ${firm.upiId}', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Scan & Pay Accepted', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Bill_${bill.billNo}.pdf',
    );
  }

  // Helper: 4-per-page compact invoice widget
  static pw.Widget _buildCompactBillBox(Bill bill, Firm firm) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey700, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text(firm.name, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Ph: ${firm.phone}', style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Bill: ${bill.billNo}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                  pw.Text(bill.monthYear, style: const pw.TextStyle(fontSize: 7)),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 0.5, color: PdfColors.grey400),

          // Customer
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Cust: ${bill.customerName}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
              pw.Text('#${bill.customerNo}', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
          pw.SizedBox(height: 2),

          // Items summary
          pw.Text(
            bill.paperBreakdown.values.map((p) => '${p.code}:${p.daysCount}d(Rs ${p.totalCost.toStringAsFixed(0)})').join(', '),
            style: const pw.TextStyle(fontSize: 7),
            maxLines: 2,
          ),
          pw.Divider(thickness: 0.5, color: PdfColors.grey400),

          // Bottom Totals & UPI
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (bill.deliveryCharge > 0)
                    pw.Text('Del: Rs ${bill.deliveryCharge.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 7)),
                  if (bill.pastBalance > 0)
                    pw.Text('Old Bal: Rs ${bill.pastBalance.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 7)),
                  pw.Text('UPI: ${firm.upiId}', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                child: pw.Text('NET: Rs ${bill.finalPayable.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildPdfSummaryRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 1.5),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: pw.TextStyle(fontSize: isBold ? 11 : 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
          pw.Text(value, style: pw.TextStyle(fontSize: isBold ? 12 : 9, fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal)),
        ],
      ),
    );
  }

  // 3. Depot Purchase Sheet Printout
  static Future<void> printDepotPurchaseSheetPdf(
    BuildContext context,
    DepotPurchaseSheet sheet,
    Firm firm,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        build: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Column(
                  children: [
                    pw.Text(firm.name, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                    pw.Text('ડેપો દૈનિક ખરીદી પત્રક (Depot Purchase Sheet) - તારીખ: ${sheet.date}', style: const pw.TextStyle(fontSize: 12)),
                  ],
                ),
              ),
              pw.SizedBox(height: 16),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey400),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Item / Paper', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Cust Copies', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Extra Copies', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total Copies', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('PTR (Rs)', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Purchase Amt (Rs)', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Est Sale (Rs)', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                  ...sheet.items.map((it) => pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(it.name)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${it.customerCopies}', textAlign: pw.TextAlign.center)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${it.extraCopies}', textAlign: pw.TextAlign.center)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${it.totalCopies}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(it.purchaseRate.toStringAsFixed(2), textAlign: pw.TextAlign.right)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(it.purchaseAmount.toStringAsFixed(2), textAlign: pw.TextAlign.right)),
                          pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(it.salesValue.toStringAsFixed(2), textAlign: pw.TextAlign.right)),
                        ],
                      )),
                  // Totals Row
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.grey100),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('TOTAL', style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${sheet.totalCustomerCopies}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${sheet.totalExtraCopies}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${sheet.totalCopies}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('-', textAlign: pw.TextAlign.right)),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(sheet.totalPurchaseAmount.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(sheet.totalSalesValue.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: pw.TextStyle(fontWeight: pw.FontWeight.bold))),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 16),
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Text('Estimated Daily Profit: Rs ${sheet.totalProfit.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'DepotPurchase_${sheet.date}.pdf',
    );
  }
}
