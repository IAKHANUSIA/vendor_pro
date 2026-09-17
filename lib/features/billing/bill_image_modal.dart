import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/bill.dart';
import '../../core/models/customer.dart';
import '../../core/models/firm.dart';
import '../../core/models/route.dart';
import '../../core/models/salesman.dart';
import '../../core/printing/print_service.dart';
import '../../core/services/image_export_service.dart';
import 'widgets/monthly_bill_image_card.dart';

class BillImageModal extends StatefulWidget {
  final Bill bill;
  final Firm firm;
  final Customer? customer;
  final DeliveryRoute? route;
  final Salesman? salesman;

  const BillImageModal({
    super.key,
    required this.bill,
    required this.firm,
    this.customer,
    this.route,
    this.salesman,
  });

  static void show(
    BuildContext context, {
    required Bill bill,
    required Firm firm,
    Customer? customer,
    DeliveryRoute? route,
    Salesman? salesman,
  }) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => BillImageModal(
        bill: bill,
        firm: firm,
        customer: customer,
        route: route,
        salesman: salesman,
      ),
    );
  }

  @override
  State<BillImageModal> createState() => _BillImageModalState();
}

class _BillImageModalState extends State<BillImageModal> {
  final GlobalKey _cardKey = GlobalKey();
  bool _isExporting = false;

  Future<void> _downloadImage() async {
    setState(() => _isExporting = true);
    try {
      final bytes = await ImageExportService.captureWidgetToPng(_cardKey, pixelRatio: 3.0);
      if (bytes != null && mounted) {
        final fileName = 'Bill_${widget.bill.billNo}_${widget.bill.monthYear}.png';
        await ImageExportService.downloadOrShareImage(context, bytes: bytes, fileName: fileName);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('બિલ ઈમેજ ($fileName) સફળતાપૂર્વક તૈયાર થઈ ગઈ!'),
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

  void _sendWhatsApp() async {
    final phone = widget.customer?.phone.isNotEmpty == true 
        ? widget.customer!.phone 
        : (widget.customer?.mobile ?? '');
    
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('ગ્રાહકનો મોબાઈલ નંબર ઉપલબ્ધ નથી.')),
      );
      return;
    }

    _downloadImage();

    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final fullPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final msg = widget.bill.generateWhatsAppText(firmName: widget.firm.name, upiId: widget.firm.upiId);

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
                width: 580,
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
                        Icon(Icons.image, color: AppColors.accentCyan, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'બિલ ઈમેજ કાર્ડ (Digital Bill)',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: Colors.white),
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

              // The Renderable Image Card
              RepaintBoundary(
                key: _cardKey,
                child: MonthlyBillImageCard(
                  bill: widget.bill,
                  firm: widget.firm,
                  customer: widget.customer,
                  route: widget.route,
                  salesman: widget.salesman,
                ),
              ),
              const SizedBox(height: 16),

              // Bottom Action Buttons
              Container(
                width: 580,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColors.cardDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('બંધ કરો', style: TextStyle(color: AppColors.textMutedDark)),
                    ),
                    const SizedBox(width: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                        PrintService.printSingleBillPdf(context, widget.bill, widget.firm);
                      },
                      icon: const Icon(Icons.print, size: 16, color: AppColors.primaryTeal),
                      label: const Text('PDF પ્રિન્ટ', style: TextStyle(color: AppColors.primaryTeal)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.primaryTeal),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isExporting ? null : _downloadImage,
                      icon: _isExporting 
                          ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black))
                          : const Icon(Icons.download, size: 16, color: Colors.black),
                      label: const Text('📸 ઈમેજ ડાઉનલોડ', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(backgroundColor: AppColors.accentGold),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _sendWhatsApp,
                      icon: const Icon(Icons.chat, size: 16),
                      label: const Text('📲 WhatsApp મોકલો', style: TextStyle(fontWeight: FontWeight.bold)),
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
