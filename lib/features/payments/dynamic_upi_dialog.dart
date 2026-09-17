import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/models/firm.dart';
import '../../core/models/customer.dart';
import '../../core/models/bill.dart';

class DynamicUpiDialog extends StatefulWidget {
  final Firm firm;
  final Customer? customer;
  final Bill? bill;
  final double? initialAmount;

  const DynamicUpiDialog({
    super.key,
    required this.firm,
    this.customer,
    this.bill,
    this.initialAmount,
  });

  static Future<void> show(
    BuildContext context, {
    required Firm firm,
    Customer? customer,
    Bill? bill,
    double? initialAmount,
  }) {
    return showDialog(
      context: context,
      builder: (ctx) => DynamicUpiDialog(
        firm: firm,
        customer: customer,
        bill: bill,
        initialAmount: initialAmount,
      ),
    );
  }

  @override
  State<DynamicUpiDialog> createState() => _DynamicUpiDialogState();
}

class _DynamicUpiDialogState extends State<DynamicUpiDialog> {
  late TextEditingController _amountController;
  late double _amount;

  @override
  void initState() {
    super.initState();
    _amount = widget.initialAmount ?? widget.bill?.finalPayable ?? widget.customer?.currentBalance ?? 0.0;
    _amountController = TextEditingController(
      text: _amount > 0 ? _amount.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    super.dispose();
  }

  String get _upiUrl {
    final upiId = widget.firm.upiId.trim().isNotEmpty
        ? widget.firm.upiId.trim()
        : 'vendor.soft@upi';
    final firmName = widget.firm.name.trim().isNotEmpty
        ? widget.firm.name.trim().replaceAll(RegExp(r'[^a-zA-Z0-9 ]'), '')
        : 'Vendor Soft';
    final billNo = widget.bill?.billNo ?? (widget.customer != null ? 'CUST-${widget.customer!.custNo}' : 'PAY');
    final note = 'Bill-$billNo';

    if (_amount > 0) {
      return 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(firmName)}&am=${_amount.toStringAsFixed(2)}&cu=INR&tn=${Uri.encodeComponent(note)}';
    } else {
      return 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(firmName)}&cu=INR&tn=${Uri.encodeComponent(note)}';
    }
  }

  void _launchDirectUpi() async {
    final uri = Uri.parse(_upiUrl);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('UPI એપ્લિકેશન (GPay/PhonePe) શરૂ થઈ શકી નથી.'),
            backgroundColor: AppColors.errorRed,
          ),
        );
      }
    }
  }

  void _copyToClipboard(String text, String label) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$label ક્લિપબોર્ડમાં કોપી થઈ ગયું!'),
        backgroundColor: AppColors.successGreen,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final custName = widget.customer?.name ?? widget.bill?.customerName ?? '';
    final custCode = widget.customer?.custNo ?? widget.bill?.customerNo ?? '';

    return AlertDialog(
      backgroundColor: AppColors.cardDark,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColors.cardBorderDark),
      ),
      contentPadding: const EdgeInsets.all(24),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.qr_code_2, color: AppColors.primaryTeal, size: 22),
                      ),
                      const SizedBox(width: 10),
                      const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'લાઇવ UPI QR કોડ',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Scan & Pay with Any UPI App',
                            style: TextStyle(fontSize: 11, color: AppColors.textMutedDark),
                          ),
                        ],
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Firm & Customer info pill
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceDark,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.cardBorderDark),
                ),
                child: Column(
                  children: [
                    Text(
                      widget.firm.name.isNotEmpty ? widget.firm.name : 'Vendor Soft Agency',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.accentGold),
                      textAlign: TextAlign.center,
                    ),
                    if (custName.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'ગ્રાહક: $custName ${custCode.isNotEmpty ? "(#$custCode)" : ""}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textLight),
                        textAlign: TextAlign.center,
                      ),
                    ],
                    if (widget.bill != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        'બિલ નં: ${widget.bill!.billNo}  •  માસ: ${widget.bill!.monthYear}',
                        style: const TextStyle(fontSize: 11, color: AppColors.textMutedDark),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // White Card with QR
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    QrImageView(
                      data: _upiUrl,
                      version: QrVersions.auto,
                      size: 210.0,
                      backgroundColor: Colors.white,
                      eyeStyle: const QrEyeStyle(
                        eyeShape: QrEyeShape.square,
                        color: Color(0xFF0F172A),
                      ),
                      dataModuleStyle: const QrDataModuleStyle(
                        dataModuleShape: QrDataModuleShape.square,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Supported Apps Pill
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildAppBadge('GPay', const Color(0xFF4285F4)),
                        const SizedBox(width: 8),
                        _buildAppBadge('PhonePe', const Color(0xFF5F259F)),
                        const SizedBox(width: 8),
                        _buildAppBadge('Paytm', const Color(0xFF00B9F1)),
                        const SizedBox(width: 8),
                        _buildAppBadge('BHIM', const Color(0xFF00833D)),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // UPI ID badge with copy action
              InkWell(
                onTap: () => _copyToClipboard(widget.firm.upiId, 'UPI ID'),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceDark,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.account_balance_wallet, size: 14, color: AppColors.primaryTeal),
                      const SizedBox(width: 8),
                      Text(
                        widget.firm.upiId.isNotEmpty ? widget.firm.upiId : 'UPI ID સેટ કરો',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.copy, size: 14, color: AppColors.textMutedDark),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Amount editor input
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _amountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.accentGold),
                      decoration: InputDecoration(
                        labelText: 'રકમ બદલો (Amount ₹)',
                        prefixText: '₹ ',
                        prefixStyle: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accentGold),
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.surfaceDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                      ),
                      onChanged: (val) {
                        setState(() {
                          _amount = double.tryParse(val) ?? 0.0;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'કોઈપણ રકમ (Dynamic)',
                    icon: const Icon(Icons.refresh, color: AppColors.textMutedDark),
                    onPressed: () {
                      setState(() {
                        _amount = 0.0;
                        _amountController.clear();
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Buttons
              Row(
                children: [
                  // 1-Tap Pay Launch Button
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _launchDirectUpi,
                      icon: const Icon(Icons.open_in_new, size: 16),
                      label: const Text('GPay / PhonePe થી ખોલો'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.successGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Copy UPI Link Button
                  OutlinedButton.icon(
                    onPressed: () => _copyToClipboard(_upiUrl, 'UPI Link'),
                    icon: const Icon(Icons.link, size: 16),
                    label: const Text('લિંક કોપી'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primaryTeal,
                      side: const BorderSide(color: AppColors.primaryTeal),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBadge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }
}
