import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/bill.dart';
import '../../core/models/customer.dart';
import '../../core/models/firm.dart';
import '../../core/services/image_export_service.dart';
import 'widgets/payment_receipt_image_card.dart';

class PaymentReceiptImageModal extends StatefulWidget {
  final Payment payment;
  final Customer customer;
  final Firm firm;
  final Bill? bill;

  const PaymentReceiptImageModal({
    super.key,
    required this.payment,
    required this.customer,
    required this.firm,
    this.bill,
  });

  static void show(
    BuildContext context, {
    required Payment payment,
    required Customer customer,
    required Firm firm,
    Bill? bill,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => PaymentReceiptImageModal(
        payment: payment,
        customer: customer,
        firm: firm,
        bill: bill,
      ),
    );
  }

  @override
  State<PaymentReceiptImageModal> createState() => _PaymentReceiptImageModalState();
}

class _PaymentReceiptImageModalState extends State<PaymentReceiptImageModal> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _downloadImage() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await ImageExportService.captureWidgetToPng(_cardKey, pixelRatio: 3.0);
      if (bytes != null && mounted) {
        final fileName = 'Receipt_${widget.payment.receiptNo.isNotEmpty ? widget.payment.receiptNo : widget.payment.id}.png';
        await ImageExportService.downloadOrShareImage(context, bytes: bytes, fileName: fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('પેમેન્ટ રસીદ ઈમેજ ($fileName) સફળતાપૂર્વક તૈયાર થઈ ગઈ!'),
              backgroundColor: AppColors.successGreen,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  String _generateReceiptMessage() {
    return '''🧾 *પેમેન્ટ પહોંચ રસીદ (Payment Receipt)*
━━━━━━━━━━━━━━━━━━
એજન્સી: *${widget.firm.name}*
પહોંચ નં: *#REC-${widget.payment.id}*
તારીખ: *${widget.payment.date}*

ગ્રાહકનું નામ: *${widget.customer.name}*
ગ્રાહક કોડ: *${widget.customer.custNo}*
${widget.customer.buildingAddress.isNotEmpty ? "સરનામું: ${widget.customer.buildingAddress}\n" : ""}
જમા કરેલ રકમ: *₹${widget.payment.amount.toStringAsFixed(2)}*
પેમેન્ટ પદ્ધતિ: *${widget.payment.paymentMode.toUpperCase()}*
હાલ બાકી રકમ: *₹${widget.customer.currentBalance.toStringAsFixed(2)}*
${widget.payment.notes.isNotEmpty ? "નોંધ: ${widget.payment.notes}\n" : ""}━━━━━━━━━━━━━━━━━━
આપની સમયસર ચુકવણી બદલ ખૂબ ખૂબ આભાર! 🙏
સંપર્ક: ${widget.firm.phone}''';
  }

  void _sendWhatsApp() async {
    final phone = widget.customer.phone.isNotEmpty 
        ? widget.customer.phone 
        : widget.customer.mobile;
    
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ગ્રાહકનો મોબાઈલ નંબર ઉપલબ્ધ નથી.')),
      );
      return;
    }

    _downloadImage();

    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final fullPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final msg = _generateReceiptMessage();

    final uri = Uri.parse('https://wa.me/$fullPhone?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp ખોલી શકાયું નથી.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: Center(
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Action Bar
              Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: const [
                        Icon(Icons.receipt, color: AppColors.accentGold, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'પેમેન્ટ રસીદ કાર્ડ (Receipt Card)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close, color: AppColors.textMutedDark),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'બંધ કરો',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // The Renderable Receipt Image Card
              RepaintBoundary(
                key: _cardKey,
                child: PaymentReceiptImageCard(
                  payment: widget.payment,
                  customer: widget.customer,
                  firm: widget.firm,
                  bill: widget.bill,
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Action Buttons
              Container(
                constraints: const BoxConstraints(maxWidth: 380),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: Wrap(
                  alignment: WrapAlignment.end,
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('બંધ કરો', style: TextStyle(color: AppColors.textMutedDark)),
                    ),
                    ElevatedButton.icon(
                      onPressed: _isExporting ? null : _downloadImage,
                      icon: _isExporting 
                          ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.download, size: 15, color: Colors.black),
                      label: const Text('📸 ઈમેજ ડાઉનલોડ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold),
                    ),
                    ElevatedButton.icon(
                      onPressed: _sendWhatsApp,
                      icon: const Icon(Icons.chat, size: 15),
                      label: const Text('📲 WhatsApp', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.successGreen),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
