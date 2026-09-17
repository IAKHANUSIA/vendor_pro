import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/bill.dart';
import '../../core/models/customer.dart';
import '../../core/models/firm.dart';
import '../../core/printing/print_service.dart';

class PaymentReceiptDialog extends StatelessWidget {
  final Payment payment;
  final Customer customer;
  final Firm firm;

  const PaymentReceiptDialog({
    super.key,
    required this.payment,
    required this.customer,
    required this.firm,
  });

  static void show(BuildContext context, {
    required Payment payment,
    required Customer customer,
    required Firm firm,
  }) {
    showDialog(
      context: context,
      builder: (ctx) => PaymentReceiptDialog(
        payment: payment,
        customer: customer,
        firm: firm,
      ),
    );
  }

  String _getModeLabel(String mode) {
    switch (mode) {
      case 'cash':
        return '💵 રોકડ (Cash)';
      case 'upi':
        return '📱 UPI / GPay / PhonePe';
      case 'bank':
        return '🏦 બેંક ટ્રાન્સફર / ચેક';
      default:
        return mode.toUpperCase();
    }
  }

  String _generateReceiptMessage() {
    final modeStr = _getModeLabel(payment.paymentMode);
    return '''🧾 *પેમેન્ટ પહોંચ રસીદ (Payment Receipt)*
━━━━━━━━━━━━━━━━━━
એજન્સી: *${firm.name}*
પહોંચ નં: *#REC-${payment.id}*
તારીખ: *${payment.date}*

ગ્રાહકનું નામ: *${customer.name}*
ગ્રાહક કોડ: *${customer.custNo}*
${customer.buildingAddress.isNotEmpty ? "સરનામું: ${customer.buildingAddress}\n" : ""}
જમા કરેલ રકમ: *₹${payment.amount.toStringAsFixed(2)}*
પેમેન્ટ પદ્ધતિ: *${modeStr}*
હાલ બાકી રકમ: *₹${customer.currentBalance.toStringAsFixed(2)}*
${payment.notes.isNotEmpty ? "નોંધ: ${payment.notes}\n" : ""}━━━━━━━━━━━━━━━━━━
આપની સમયસર ચુકવણી બદલ ખૂબ ખૂબ આભાર! 🙏
સંપર્ક: ${firm.phone}''';
  }

  void _sendWhatsAppReceipt(BuildContext context) async {
    final phone = customer.phone.isNotEmpty ? customer.phone : customer.mobile;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ગ્રાહકનો મોબાઈલ નંબર ઉપલબ્ધ નથી.')),
      );
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final fullPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final msg = _generateReceiptMessage();

    final uri = Uri.parse('https://wa.me/$fullPhone?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp ખોલી શકાયું નથી.')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final msg = _generateReceiptMessage();

    return Dialog(
      backgroundColor: AppColors.bgCardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 480,
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.successGreen.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.receipt_long, color: AppColors.successGreen, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '🧾 પેમેન્ટ પહોંચ રસીદ (Digital Receipt)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                      ),
                      Text(
                        'પહોંચ નં. #REC-${payment.id} • ${payment.date}',
                        style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMutedDark),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Receipt Preview Card
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderDark),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(customer.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white)),
                      Text(
                        '₹${payment.amount.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.successGreen),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('મોબાઇલ: ${customer.phone.isNotEmpty ? customer.phone : customer.mobile}', style: const TextStyle(color: AppColors.textSecondaryDark, fontSize: 12)),
                      Text(_getModeLabel(payment.paymentMode), style: const TextStyle(color: AppColors.accentCyan, fontSize: 12)),
                    ],
                  ),
                  const Divider(color: AppColors.borderDark, height: 16),
                  Text(
                    msg,
                    style: const TextStyle(fontFamily: 'monospace', fontSize: 11, color: AppColors.textLight, height: 1.4),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Actions Row
            Row(
              children: [
                // Copy button
                OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: msg));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('રસીદ મેસેજ કોપી થઈ ગયો! 📋')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('કોપી'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.textSecondaryDark,
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const SizedBox(width: 8),

                // Print PDF button
                OutlinedButton.icon(
                  onPressed: () {
                    PrintService.printPaymentReceiptPdf(context, payment, customer, firm);
                  },
                  icon: const Icon(Icons.print, size: 16),
                  label: const Text('પ્રિન્ટ પાવતી'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accentCyan,
                    side: const BorderSide(color: AppColors.accentCyan),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  ),
                ),
                const Spacer(),

                // WhatsApp Send Button
                ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF25D366),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  onPressed: () => _sendWhatsAppReceipt(context),
                  icon: const Icon(Icons.send, size: 16),
                  label: const Text('WhatsApp રસીદ મોકલો', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
