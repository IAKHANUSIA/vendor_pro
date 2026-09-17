import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/bill.dart';
import '../models/firm.dart';
import '../models/customer.dart';
import '../models/route.dart';
import '../models/salesman.dart';
import '../models/item.dart';
import '../database/database_service.dart';

enum BillPrintFormat {
  fourInOneClassic, // A4 4-in-1: Classic B&W Memo
  fourInOneModern, // A4 4-in-1: Modern Blue Card
  fourInOneStub, // A4 4-in-1: Bill + Tear-off Counterfoil Stub
  threeInOneStrip, // A4 3-in-1: Wide Horizontal Strip with Counterfoil
  twoInOneHalfPage, // A4 2-in-1: Detailed Commercial Invoice
  singleThermal, // Thermal Roll: 80mm/58mm POS Receipt
  fullPageA4, // A4 Full Page: Detailed Statement
}

class PrintService {
  // 1. Bulk Month Bills Print Engine (Supports 4-in-1, 3-in-1, 2-in-1, Full A4, Thermal)
  static Future<void> printMonthBillsPdf(
    BuildContext context,
    List<Bill> bills,
    Firm firm,
    String monthYear, {
    BillPrintFormat format = BillPrintFormat.fourInOneClassic,
  }) async {
    final pdf = pw.Document();

    if (format == BillPrintFormat.fourInOneClassic ||
        format == BillPrintFormat.fourInOneModern ||
        format == BillPrintFormat.fourInOneStub) {
      // 4 Bills per A4 Page (2x2 Grid)
      for (int i = 0; i < bills.length; i += 4) {
        final chunk = bills.sublist(i, (i + 4 > bills.length) ? bills.length : i + 4);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(12),
            build: (pw.Context ctx) {
              return pw.GridView(
                crossAxisCount: 2,
                childAspectRatio: 1.38,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                children: chunk.map((b) {
                  if (format == BillPrintFormat.fourInOneModern) {
                    return _build4In1ModernBox(b, firm);
                  } else if (format == BillPrintFormat.fourInOneStub) {
                    return _build4In1StubBox(b, firm);
                  } else {
                    return _build4In1ClassicBox(b, firm);
                  }
                }).toList(),
              );
            },
          ),
        );
      }
    } else if (format == BillPrintFormat.threeInOneStrip) {
      // 3 Horizontal Slips per A4 Page (3x1 Stack)
      for (int i = 0; i < bills.length; i += 3) {
        final chunk = bills.sublist(i, (i + 3 > bills.length) ? bills.length : i + 3);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(14),
            build: (pw.Context ctx) {
              return pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: chunk
                    .map((b) => pw.Expanded(
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 4),
                            child: _build3In1StripRow(b, firm),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        );
      }
    } else if (format == BillPrintFormat.twoInOneHalfPage) {
      // 2 Detailed Invoices per A4 Page (2x1 Stack)
      for (int i = 0; i < bills.length; i += 2) {
        final chunk = bills.sublist(i, (i + 2 > bills.length) ? bills.length : i + 2);
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(16),
            build: (pw.Context ctx) {
              return pw.Column(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: chunk
                    .map((b) => pw.Expanded(
                          child: pw.Padding(
                            padding: const pw.EdgeInsets.symmetric(vertical: 6),
                            child: _build2In1HalfPageBox(b, firm),
                          ),
                        ))
                    .toList(),
              );
            },
          ),
        );
      }
    } else if (format == BillPrintFormat.singleThermal) {
      // Thermal POS Roll (80mm)
      for (final b in bills) {
        pdf.addPage(
          pw.Page(
            pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm),
            build: (pw.Context ctx) => _buildThermalSlip(b, firm),
          ),
        );
      }
    } else {
      // Full Page A4
      for (final b in bills) {
        pdf.addPage(
          pw.Page(
            pageFormat: PdfPageFormat.a4,
            margin: const pw.EdgeInsets.all(24),
            build: (pw.Context ctx) => _buildFullPageA4(b, firm),
          ),
        );
      }
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat f) async => pdf.save(),
      name: 'Bills_${format.name}_$monthYear.pdf',
    );
  }

  // 2. Single Bill Print (Thermal / Half A4 / Classic Format)
  static Future<void> printSingleBillPdf(
    BuildContext context,
    Bill bill,
    Firm firm, {
    BillPrintFormat format = BillPrintFormat.twoInOneHalfPage,
  }) async {
    final pdf = pw.Document();

    if (format == BillPrintFormat.singleThermal) {
      pdf.addPage(
        pw.Page(
          pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm),
          build: (pw.Context ctx) => _buildThermalSlip(bill, firm),
        ),
      );
    } else if (format == BillPrintFormat.fullPageA4) {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(24),
          build: (pw.Context ctx) => _buildFullPageA4(bill, firm),
        ),
      );
    } else {
      pdf.addPage(
        pw.Page(
          pageFormat: PdfPageFormat.a5,
          margin: const pw.EdgeInsets.all(16),
          build: (pw.Context ctx) => _build2In1HalfPageBox(bill, firm),
        ),
      );
    }

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat f) async => pdf.save(),
      name: 'Bill_${bill.billNo}.pdf',
    );
  }

  // ===========================================================================
  // FORMAT RENDERERS
  // ===========================================================================

  // 1. A4 4-in-1: Classic B&W High Density Memo
  static pw.Widget _build4In1ClassicBox(Bill bill, Firm firm) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.black, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
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
                  pw.Text(firm.name.toUpperCase(), style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Ph: ${firm.phone}', style: const pw.TextStyle(fontSize: 6.5)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('BILL: #${bill.billNo}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  pw.Text(bill.monthYear, style: const pw.TextStyle(fontSize: 6.5)),
                ],
              ),
            ],
          ),
          pw.Divider(thickness: 0.5, color: PdfColors.grey600),

          // Customer
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Cust: ${bill.customerName}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              pw.Text('Code: #${bill.customerNo}', style: const pw.TextStyle(fontSize: 7.5)),
            ],
          ),

          // Subscription items
          pw.Text(
            bill.paperBreakdown.values
                .map((p) => '${p.code}:${p.daysCount}d(Rs ${p.totalCost.toStringAsFixed(0)})')
                .join(', '),
            style: const pw.TextStyle(fontSize: 6.5),
            maxLines: 2,
          ),
          pw.Divider(thickness: 0.5, color: PdfColors.grey600),

          // Totals and Net Pay
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (bill.deliveryCharge > 0)
                    pw.Text('Del: Rs ${bill.deliveryCharge.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 6.5)),
                  if (bill.pastBalance > 0)
                    pw.Text('Old Bal: Rs ${bill.pastBalance.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 6.5)),
                  if (firm.upiId.isNotEmpty)
                    pw.Text('UPI: ${firm.upiId}', style: const pw.TextStyle(fontSize: 5.5, color: PdfColors.grey800)),
                ],
              ),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                child: pw.Text('NET: Rs ${bill.finalPayable.toStringAsFixed(0)}',
                    style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 2. A4 4-in-1: Modern Slate/Navy Theme Card
  static pw.Widget _build4In1ModernBox(Bill bill, Firm firm) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(7),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.blue800, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Top Pill & Agency Header
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: const pw.BoxDecoration(
                  color: PdfColors.blue900,
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
                ),
                child: pw.Text('CREDIT MEMO', style: pw.TextStyle(fontSize: 6, color: PdfColors.white, fontWeight: pw.FontWeight.bold)),
              ),
              pw.Text('Bill #${bill.billNo} | ${bill.monthYear}', style: pw.TextStyle(fontSize: 7, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            ],
          ),
          pw.SizedBox(height: 2),
          pw.Text(firm.name.toUpperCase(), style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
          pw.Text('Phone: ${firm.phone}', style: const pw.TextStyle(fontSize: 6, color: PdfColors.grey700)),
          pw.Divider(thickness: 0.5, color: PdfColors.blue300),

          // Customer
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(bill.customerName, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
              pw.Text('#${bill.customerNo}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
            ],
          ),

          // Paper list
          pw.Text(
            bill.paperBreakdown.values
                .map((p) => '${p.name}: ${p.daysCount}d (Rs ${p.totalCost.toStringAsFixed(0)})')
                .join(', '),
            style: const pw.TextStyle(fontSize: 6.5),
            maxLines: 2,
          ),

          // Net Payable Banner
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2.5),
            decoration: const pw.BoxDecoration(
              color: PdfColors.blue50,
              borderRadius: pw.BorderRadius.all(pw.Radius.circular(3)),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('NET PAYABLE:', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                pw.Text('Rs ${bill.finalPayable.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. A4 4-in-1: Bill + Tear-off Stub Counterfoil
  static pw.Widget _build4In1StubBox(Bill bill, Firm firm) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey700, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
      ),
      child: pw.Row(
        children: [
          // Left Main Bill (72% width)
          pw.Expanded(
            flex: 72,
            child: pw.Padding(
              padding: const pw.EdgeInsets.all(6),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(firm.name, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Bill: ${bill.billNo}', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                  pw.Text('Cust: ${bill.customerName} (#${bill.customerNo})', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text(
                    bill.paperBreakdown.values.map((p) => '${p.code}:${p.daysCount}d').join(', '),
                    style: const pw.TextStyle(fontSize: 6.5),
                  ),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('UPI: ${firm.upiId}', style: const pw.TextStyle(fontSize: 5.5)),
                      pw.Text('Rs ${bill.finalPayable.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Dashed Vertical Tear-off Line
          pw.Container(
            width: 1,
            color: PdfColors.grey400,
            margin: const pw.EdgeInsets.symmetric(vertical: 4),
          ),

          // Right Tear-off Collection Stub (28% width)
          pw.Expanded(
            flex: 28,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(4),
              color: PdfColors.grey100,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.center,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('STUB', style: pw.TextStyle(fontSize: 6, fontWeight: pw.FontWeight.bold, color: PdfColors.grey700)),
                  pw.Text('#${bill.customerNo}', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text(bill.monthYear, style: const pw.TextStyle(fontSize: 5.5)),
                  pw.Text('Rs ${bill.finalPayable.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Sign: _____', style: const pw.TextStyle(fontSize: 5)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 4. A4 3-in-1: Wide Horizontal Strip with Counterfoil
  static pw.Widget _build3In1StripRow(Bill bill, Firm firm) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey700, width: 0.8),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Row(
        children: [
          // Main Bill (76% width)
          pw.Expanded(
            flex: 76,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Header Row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(firm.name, style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text('${firm.address} | Ph: ${firm.phone}', style: const pw.TextStyle(fontSize: 7.5)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('INVOICE: #${bill.billNo}', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Month: ${bill.monthYear}', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                  ],
                ),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),

                // Customer & Items Row
                pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 4,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('Customer: ${bill.customerName}', style: pw.TextStyle(fontSize: 9.5, fontWeight: pw.FontWeight.bold)),
                          pw.Text('Customer Code: #${bill.customerNo}', style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ),
                    pw.Expanded(
                      flex: 6,
                      child: pw.Text(
                        'Items: ' +
                            bill.paperBreakdown.values
                                .map((p) => '${p.name} (${p.daysCount}d: Rs ${p.totalCost.toStringAsFixed(0)})')
                                .join(' | '),
                        style: const pw.TextStyle(fontSize: 8),
                      ),
                    ),
                  ],
                ),
                pw.Divider(thickness: 0.5, color: PdfColors.grey400),

                // Summary Row
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Row(
                      children: [
                        if (bill.deliveryCharge > 0)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(right: 10),
                            child: pw.Text('Del: Rs ${bill.deliveryCharge.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 7.5)),
                          ),
                        if (bill.pastBalance > 0)
                          pw.Padding(
                            padding: const pw.EdgeInsets.only(right: 10),
                            child: pw.Text('Arrears: Rs ${bill.pastBalance.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 7.5)),
                          ),
                        if (firm.upiId.isNotEmpty)
                          pw.Text('UPI: ${firm.upiId}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.blue800)),
                      ],
                    ),
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      child: pw.Text('NET PAYABLE: Rs ${bill.finalPayable.toStringAsFixed(0)}',
                          style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Dashed Vertical Divider
          pw.Container(
            width: 1,
            color: PdfColors.grey400,
            margin: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          ),

          // Right Counterfoil Stub (24% width)
          pw.Expanded(
            flex: 24,
            child: pw.Container(
              padding: const pw.EdgeInsets.all(6),
              color: PdfColors.grey100,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Center(child: pw.Text('RECEIPT STUB', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold))),
                  pw.Text('Cust: ${bill.customerName}', style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold), maxLines: 1),
                  pw.Text('Code: #${bill.customerNo} | ${bill.monthYear}', style: const pw.TextStyle(fontSize: 6.5)),
                  pw.Text('Net Due: Rs ${bill.finalPayable.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Date: ___/___/2026', style: const pw.TextStyle(fontSize: 6)),
                  pw.Text('Collector Sign: ________', style: const pw.TextStyle(fontSize: 6)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // 5. A4 2-in-1: Detailed Half Page Commercial Invoice
  static pw.Widget _build2In1HalfPageBox(Bill bill, Firm firm) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(12),
      decoration: pw.BoxDecoration(
        border: pw.Border.all(color: PdfColors.grey600, width: 1),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          // Header
          pw.Center(
            child: pw.Column(
              children: [
                pw.Text(firm.name.toUpperCase(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                pw.Text('${firm.address} | Phone: ${firm.phone}', style: const pw.TextStyle(fontSize: 8.5)),
              ],
            ),
          ),
          pw.Divider(thickness: 1, color: PdfColors.grey400),

          // Customer & Bill Row
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Customer: ${bill.customerName}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Customer Code: #${bill.customerNo}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Bill No: #${bill.billNo}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  pw.Text('Billing Period: ${bill.monthYear}', style: const pw.TextStyle(fontSize: 9)),
                ],
              ),
            ],
          ),
          pw.SizedBox(height: 6),

          // Paper Items Table
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            children: [
              pw.TableRow(
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                children: [
                  pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Item / Publication', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Days', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                  pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('Amount (Rs)', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                ],
              ),
              ...bill.paperBreakdown.values.map((p) => pw.TableRow(
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(p.name, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text('${p.daysCount}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                      pw.Padding(padding: const pw.EdgeInsets.all(3), child: pw.Text(p.totalCost.toStringAsFixed(0), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                    ],
                  )),
            ],
          ),

          // Summary Lines
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            crossAxisAlignment: pw.CrossAxisAlignment.end,
            children: [
              // Notice / UPI info
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  if (firm.upiId.isNotEmpty)
                    pw.Text('Pay via GPay/PhonePe UPI: ${firm.upiId}', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.blue800)),
                  pw.Text('* Pay bill between 1st to 10th of every month.', style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey700)),
                ],
              ),
              // Totals
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  if (bill.deliveryCharge > 0)
                    pw.Text('Delivery Charge: Rs ${bill.deliveryCharge.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 7.5)),
                  if (bill.pastBalance > 0)
                    pw.Text('Previous Arrears: Rs ${bill.pastBalance.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 7.5)),
                  pw.SizedBox(height: 2),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                    child: pw.Text('TOTAL DUE: Rs ${bill.finalPayable.toStringAsFixed(0)}',
                        style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // 6. Thermal POS 80mm Roll Slip
  static pw.Widget _buildThermalSlip(Bill bill, Firm firm) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(4),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Text(firm.name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
          pw.Text('Ph: ${firm.phone}', style: const pw.TextStyle(fontSize: 8)),
          pw.Text('--------------------------------', style: const pw.TextStyle(fontSize: 8)),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Bill: #${bill.billNo}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text(bill.monthYear, style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Cust: ${bill.customerName}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
              pw.Text('#${bill.customerNo}', style: const pw.TextStyle(fontSize: 8)),
            ],
          ),
          pw.Text('--------------------------------', style: const pw.TextStyle(fontSize: 8)),
          ...bill.paperBreakdown.values.map((p) => pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('${p.name} (${p.daysCount}d)', style: const pw.TextStyle(fontSize: 7.5)),
                  pw.Text('Rs ${p.totalCost.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 7.5)),
                ],
              )),
          pw.Text('--------------------------------', style: const pw.TextStyle(fontSize: 8)),
          if (bill.deliveryCharge > 0)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Delivery Fee:', style: const pw.TextStyle(fontSize: 7.5)),
                pw.Text('Rs ${bill.deliveryCharge.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 7.5)),
              ],
            ),
          if (bill.pastBalance > 0)
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Past Arrears:', style: const pw.TextStyle(fontSize: 7.5)),
                pw.Text('Rs ${bill.pastBalance.toStringAsFixed(0)}', style: const pw.TextStyle(fontSize: 7.5)),
              ],
            ),
          pw.SizedBox(height: 4),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('NET PAYABLE:', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
              pw.Text('Rs ${bill.finalPayable.toStringAsFixed(0)}', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold)),
            ],
          ),
          pw.Text('================================', style: const pw.TextStyle(fontSize: 8)),
          if (firm.upiId.isNotEmpty) ...[
            pw.Text('Scan & Pay UPI: ${firm.upiId}', style: const pw.TextStyle(fontSize: 7.5), textAlign: pw.TextAlign.center),
            pw.SizedBox(height: 4),
          ],
          pw.Text('Thank You for Reading!', style: const pw.TextStyle(fontSize: 8)),
        ],
      ),
    );
  }

  // 7. Full Page Detailed Matrix Invoice
  static pw.Widget _buildFullPageA4(Bill bill, Firm firm) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        // Top Banner
        pw.Center(
          child: pw.Column(
            children: [
              pw.Text(firm.name.toUpperCase(), style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
              pw.Text('${firm.address} | Phone: ${firm.phone}', style: const pw.TextStyle(fontSize: 10)),
              pw.Text('MONTHLY INVOICE / STATEMENT', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
            ],
          ),
        ),
        pw.Divider(thickness: 1.5, color: PdfColors.grey500),
        pw.SizedBox(height: 10),

        // Customer & Bill Row
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('Customer Name: ${bill.customerName}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Text('Customer Code: #${bill.customerNo}', style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: [
                pw.Text('Invoice No: #${bill.billNo}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold)),
                pw.Text('Month / Period: ${bill.monthYear}', style: const pw.TextStyle(fontSize: 11)),
              ],
            ),
          ],
        ),
        pw.SizedBox(height: 16),

        // Table of Subscribed Items
        pw.Table(
          border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
          children: [
            pw.TableRow(
              decoration: const pw.BoxDecoration(color: PdfColors.grey200),
              children: [
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Publication / Item', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Days Count', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
                pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('Total Cost (Rs)', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold))),
              ],
            ),
            ...bill.paperBreakdown.values.map((p) => pw.TableRow(
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(p.name, style: const pw.TextStyle(fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text('${p.daysCount}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 10))),
                    pw.Padding(padding: const pw.EdgeInsets.all(6), child: pw.Text(p.totalCost.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 10))),
                  ],
                )),
          ],
        ),
        pw.SizedBox(height: 16),

        // Summary Breakdown
        pw.Align(
          alignment: pw.Alignment.centerRight,
          child: pw.Container(
            width: 250,
            child: pw.Column(
              children: [
                _buildPdfSummaryRow('Current Papers Total:', 'Rs ${bill.newspaperAmount.toStringAsFixed(2)}'),
                if (bill.deliveryCharge > 0)
                  _buildPdfSummaryRow('Home Delivery Charges:', 'Rs ${bill.deliveryCharge.toStringAsFixed(2)}'),
                if (bill.vacationDeduction > 0)
                  _buildPdfSummaryRow('Vacation Rebate (${bill.vacationDays} d):', '-Rs ${bill.vacationDeduction.toStringAsFixed(2)}'),
                if (bill.pastBalance > 0)
                  _buildPdfSummaryRow('Previous Arrears:', 'Rs ${bill.pastBalance.toStringAsFixed(2)}'),
                pw.Divider(thickness: 1, color: PdfColors.grey400),
                _buildPdfSummaryRow('NET AMOUNT PAYABLE:', 'Rs ${bill.finalPayable.toStringAsFixed(2)}', isBold: true),
              ],
            ),
          ),
        ),
        pw.Spacer(),

        // Payment Info & Terms
        pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: PdfColors.grey100,
            border: pw.Border.all(color: PdfColors.grey300),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Payment Mode: Cash / UPI / GPay / PhonePe', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  if (firm.upiId.isNotEmpty)
                    pw.Text('UPI VPA: ${firm.upiId}', style: const pw.TextStyle(fontSize: 9, color: PdfColors.blue900)),
                ],
              ),
              pw.Text('Authorized Signature', style: const pw.TextStyle(fontSize: 9)),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildPdfSummaryRow(String label, String value, {bool isBold = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 2),
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

  // 4. Daily Morning Delivery Sheet Printout (A4 / MultiPage format)
  static Future<void> printMorningDeliverySheetPdf({
    required BuildContext context,
    required DeliveryRoute route,
    required DateTime date,
    required List<Customer> customers,
    required Firm firm,
    Salesman? salesman,
    required Map<String, int> paperSummary,
  }) async {
    final pdf = pw.Document();
    final dateStr = DateFormat('dd/MM/yyyy').format(date);
    final dayOfWeek = date.weekday % 7;
    const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
    final dayName = dayNames[dayOfWeek];

    final db = DatabaseService.instance;
    final isoDateStr = DateFormat('yyyy-MM-dd').format(date);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(20),
        header: (pw.Context ctx) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text(firm.name, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Phone: ${firm.phone} | ${firm.address}', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                  pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text('DAILY DELIVERY SHEET', style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold, color: PdfColors.blue800)),
                      pw.Text('Date: $dateStr ($dayName)', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ],
              ),
              pw.SizedBox(height: 6),
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Route: ${route.code} - ${route.name}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Hawker: ${salesman?.name ?? "None"} (${salesman?.mobile ?? ""})', style: const pw.TextStyle(fontSize: 9)),
                    pw.Text('Total Cust: ${customers.length}', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
              ),
              pw.SizedBox(height: 6),
              if (paperSummary.isNotEmpty) ...[
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border.all(color: PdfColors.grey400, width: 0.5),
                  ),
                  child: pw.Row(
                    children: [
                      pw.Text('PAPERS SUMMARY: ', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      pw.Expanded(
                        child: pw.Text(
                          paperSummary.entries.map((e) => '${e.key}: ${e.value}').join('  |  '),
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                      ),
                      pw.Text('TOTAL: ${paperSummary.values.fold<int>(0, (a, b) => a + b)} copies', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 8),
              ],
            ],
          );
        },
        build: (pw.Context ctx) {
          return [
            pw.Table(
              border: pw.TableBorder.all(color: PdfColors.grey400, width: 0.5),
              children: [
                // Table Header
                pw.TableRow(
                  decoration: const pw.BoxDecoration(color: PdfColors.grey300),
                  children: [
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Seq', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Code', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Customer Name', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Address / Society', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Today\'s Papers', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                    pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Delivered', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                  ],
                ),
                ...customers.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final c = entry.value;
                  final onVacation = db.vacations.any((v) => v.customerId == c.id && v.isActiveOn(isoDateStr));
                  final isDelivered = db.getDeliveryStatus(isoDateStr, c.id) == 'delivered';

                  final todayPapers = c.subscriptionItemIds.where((id) {
                    return c.isSubscribedOnDay(id, dayOfWeek, isoDateStr);
                  }).map((id) {
                    return db.items.cast<Item?>().firstWhere((i) => i?.id == id, orElse: () => null)?.code;
                  }).where((n) => n != null).join(', ');

                  return pw.TableRow(
                    decoration: onVacation
                        ? const pw.BoxDecoration(color: PdfColors.red50)
                        : (idx.isEven ? const pw.BoxDecoration(color: PdfColors.white) : const pw.BoxDecoration(color: PdfColors.grey100)),
                    children: [
                      pw.Padding(padding: const pw.EdgeInsets.all(3.5), child: pw.Text('#${idx + 1}', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(3.5), child: pw.Text(c.code.isNotEmpty ? c.code : '#${c.custNo}', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5))),
                      pw.Padding(padding: const pw.EdgeInsets.all(3.5), child: pw.Text(c.name, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold))),
                      pw.Padding(padding: const pw.EdgeInsets.all(3.5), child: pw.Text(c.societyShort.isNotEmpty ? '[${c.societyShort}] ${c.address}' : c.address, style: const pw.TextStyle(fontSize: 7.5))),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3.5),
                        child: onVacation
                            ? pw.Text('[VACATION / HOLD]', style: pw.TextStyle(fontSize: 7.5, color: PdfColors.red700, fontWeight: pw.FontWeight.bold))
                            : pw.Text(todayPapers.isNotEmpty ? todayPapers : '-', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(3.5),
                        child: pw.Center(
                          child: pw.Container(
                            width: 12,
                            height: 12,
                            decoration: pw.BoxDecoration(
                              border: pw.Border.all(color: PdfColors.grey600, width: 0.8),
                            ),
                            child: isDelivered ? pw.Center(child: pw.Text('X', style: const pw.TextStyle(fontSize: 8))) : null,
                          ),
                        ),
                      ),
                    ],
                  );
                }),
              ],
            ),
          ];
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'MorningDelivery_${route.code}_$dateStr.pdf',
    );
  }

  // 5. Payment Receipt Slip Printout (POS 80mm / Slip Format)
  static Future<void> printPaymentReceiptPdf(
    BuildContext context,
    Payment payment,
    Customer customer,
    Firm firm,
  ) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: const PdfPageFormat(80 * PdfPageFormat.mm, double.infinity, marginAll: 4 * PdfPageFormat.mm),
        build: (pw.Context ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(4),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(firm.name, style: pw.TextStyle(fontSize: 12, fontWeight: pw.FontWeight.bold), textAlign: pw.TextAlign.center),
                pw.Text('Ph: ${firm.phone}', style: const pw.TextStyle(fontSize: 8)),
                pw.Text(firm.address, style: const pw.TextStyle(fontSize: 7), textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 2),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  child: pw.Text('PAYMENT RECEIPT / પાવતી', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                ),
                pw.Text('--------------------------------', style: const pw.TextStyle(fontSize: 8)),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Rec No: #REC-${payment.id}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Text('Date: ${payment.date}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Cust: ${customer.name}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                    pw.Text('#${customer.custNo}', style: const pw.TextStyle(fontSize: 8)),
                  ],
                ),
                if (customer.phone.isNotEmpty || customer.mobile.isNotEmpty)
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('Ph: ${customer.phone.isNotEmpty ? customer.phone : customer.mobile}', style: const pw.TextStyle(fontSize: 7.5)),
                  ),
                pw.Text('--------------------------------', style: const pw.TextStyle(fontSize: 8)),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Payment Mode:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text(payment.paymentMode.toUpperCase(), style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                if (payment.billMonthYear.isNotEmpty)
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('For Month:', style: const pw.TextStyle(fontSize: 8)),
                      pw.Text(payment.billMonthYear, style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                pw.SizedBox(height: 4),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('AMOUNT RECEIVED:', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Rs ${payment.amount.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 4),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Current Balance:', style: const pw.TextStyle(fontSize: 8)),
                    pw.Text('Rs ${customer.currentBalance.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
                  ],
                ),
                if (payment.notes.isNotEmpty) ...[
                  pw.SizedBox(height: 2),
                  pw.Align(
                    alignment: pw.Alignment.centerLeft,
                    child: pw.Text('Note: ${payment.notes}', style: const pw.TextStyle(fontSize: 7)),
                  ),
                ],
                pw.Text('================================', style: const pw.TextStyle(fontSize: 8)),
                pw.SizedBox(height: 4),
                pw.Text('Thank you for prompt payment!', style: const pw.TextStyle(fontSize: 7.5), textAlign: pw.TextAlign.center),
                pw.SizedBox(height: 8),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('Collector: ________', style: const pw.TextStyle(fontSize: 7)),
                    pw.Text('Auth Sign: ________', style: const pw.TextStyle(fontSize: 7)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'Receipt_REC_${payment.id}.pdf',
    );
  }

  // 6. Hawker Salary / Commission Slip Printout
  static Future<void> printHawkerSalarySlipPdf(
    BuildContext context,
    Salesman salesman,
    int totalCopies,
    double commissionAmt,
    double bonus,
    double deductions,
    double netSalary,
    String monthYear,
    Firm firm, {
    double baseSalary = 0.0,
    double ratePerCopy = 0.0,
    int daysCount = 30,
    String notes = '',
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context ctx) {
          return pw.Container(
            padding: const pw.EdgeInsets.all(12),
            decoration: pw.BoxDecoration(
              border: pw.Border.all(color: PdfColors.grey700, width: 1),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                // Header
                pw.Center(
                  child: pw.Column(
                    children: [
                      pw.Text(firm.name.toUpperCase(), style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
                      pw.Text('${firm.address} | Phone: ${firm.phone}', style: const pw.TextStyle(fontSize: 8)),
                      pw.SizedBox(height: 2),
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: const pw.BoxDecoration(color: PdfColors.blue100),
                        child: pw.Text('DELIVERY SALARY & COMMISSION SLIP / વિતરક પગાર પાવતી', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                      ),
                    ],
                  ),
                ),
                pw.Divider(thickness: 0.8, color: PdfColors.grey400),

                // Hawker & Period Details
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('Hawker: ${salesman.name}', style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Mobile: ${salesman.mobile}', style: const pw.TextStyle(fontSize: 8.5)),
                        if (salesman.address.isNotEmpty)
                          pw.Text('Address: ${salesman.address}', style: const pw.TextStyle(fontSize: 8)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('Month: $monthYear', style: pw.TextStyle(fontSize: 10, fontWeight: pw.FontWeight.bold)),
                        pw.Text('Daily Copies: $totalCopies', style: const pw.TextStyle(fontSize: 9)),
                        pw.Text('Days: $daysCount', style: const pw.TextStyle(fontSize: 8.5)),
                      ],
                    ),
                  ],
                ),
                pw.SizedBox(height: 6),

                // Salary / Earnings Table
                pw.Table(
                  border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                  children: [
                    pw.TableRow(
                      decoration: const pw.BoxDecoration(color: PdfColors.grey200),
                      children: [
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Earnings / Description', style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Rate / Detail', textAlign: pw.TextAlign.center, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                        pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Amount (Rs)', textAlign: pw.TextAlign.right, style: pw.TextStyle(fontSize: 8.5, fontWeight: pw.FontWeight.bold))),
                      ],
                    ),
                    if (baseSalary > 0)
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Fixed Monthly Salary (ફિક્સ માસિક પગાર)', style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Fixed', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(baseSalary.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                        ],
                      ),
                    if (commissionAmt > 0)
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Delivery Commission (કમિશન)', style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(ratePerCopy > 0 ? '$totalCopies copies x Rs $ratePerCopy/d' : '$totalCopies copies', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 7.5))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(commissionAmt.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                        ],
                      ),
                    if (bonus > 0)
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Bonus / Incentive / Extra Duty (બોનસ)', style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Extra', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text(bonus.toStringAsFixed(2), textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8))),
                        ],
                      ),
                    if (deductions > 0)
                      pw.TableRow(
                        children: [
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Deductions / Advance / Fines (કાપ / એડવાન્સ)', style: const pw.TextStyle(fontSize: 8, color: PdfColors.red700))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('Deduction', textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8))),
                          pw.Padding(padding: const pw.EdgeInsets.all(4), child: pw.Text('-${deductions.toStringAsFixed(2)}', textAlign: pw.TextAlign.right, style: const pw.TextStyle(fontSize: 8, color: PdfColors.red700))),
                        ],
                      ),
                  ],
                ),
                pw.SizedBox(height: 6),

                // Net Salary Payable Banner
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: const pw.BoxDecoration(
                    color: PdfColors.grey200,
                    borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                  ),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('NET SALARY PAYABLE (ચૂકવવાપાત્ર ચોખ્ખો પગાર):', style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
                      pw.Text('Rs ${netSalary.toStringAsFixed(2)}', style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold, color: PdfColors.blue900)),
                    ],
                  ),
                ),
                if (notes.isNotEmpty)
                  pw.Padding(
                    padding: const pw.EdgeInsets.only(top: 4),
                    child: pw.Text('Note: $notes', style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
                  ),
                pw.Spacer(),

                // Signatures
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text('_________________________', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Delivery Person Signature (વિતરક સહી)', style: const pw.TextStyle(fontSize: 7.5)),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text('_________________________', style: const pw.TextStyle(fontSize: 8)),
                        pw.Text('Authorized Signature (એજન્સી સહી)', style: const pw.TextStyle(fontSize: 7.5)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (PdfPageFormat format) async => pdf.save(),
      name: 'SalarySlip_${salesman.name}_$monthYear.pdf',
    );
  }
}
