import 'package:flutter/material.dart';
import '../../../core/models/bill.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/firm.dart';

class PaymentReceiptImageCard extends StatelessWidget {
  final Payment payment;
  final Customer customer;
  final Firm firm;
  final Bill? bill;

  const PaymentReceiptImageCard({
    super.key,
    required this.payment,
    required this.customer,
    required this.firm,
    this.bill,
  });

  @override
  Widget build(BuildContext context) {
    final agencyName = firm.name.isNotEmpty ? firm.name : 'SHAHID AGENCY';
    final custName = customer.name;
    final custAddress = customer.buildingAddress.isNotEmpty 
        ? customer.buildingAddress 
        : (customer.address.isNotEmpty ? customer.address : '');
    final partyDisplay = custAddress.isNotEmpty ? '$custName ($custAddress)' : custName;

    final billNoDisplay = bill?.billNo.isNotEmpty == true 
        ? bill!.billNo 
        : (payment.billMonthYear.isNotEmpty ? payment.billMonthYear : '-');
    final billAmountDisplay = bill != null 
        ? bill!.finalPayable 
        : (payment.amount + customer.currentBalance);
    final paidAmountDisplay = payment.amount;
    final dueRemainingDisplay = customer.currentBalance;

    String modeDisplay = 'Online';
    if (payment.paymentMode == 'cash') {
      modeDisplay = 'Cash';
    } else if (payment.paymentMode == 'upi') {
      modeDisplay = 'UPI Online';
    } else if (payment.paymentMode == 'cheque' || payment.paymentMode == 'bank') {
      modeDisplay = 'Bank Transfer';
    }

    final txnIdDisplay = payment.receiptNo.isNotEmpty ? payment.receiptNo : 'TXN-${payment.id}';

    return Container(
      width: 380,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFD3E0EA), width: 1.5),
        boxShadow: const [
          BoxShadow(color: Colors.black12, blurRadius: 16, offset: Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Dashed Border
          _buildDashedLine(),
          const SizedBox(height: 14),

          // Title
          const Center(
            child: Text(
              'PAYMENT RECEIPT',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w900,
                color: Color(0xFF0D3B66),
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 14),
          _buildDashedLine(),
          const SizedBox(height: 18),

          // Party Name Row
          _buildInfoRow(
            icon: Icons.apartment,
            iconColor: const Color(0xFF1E88E5),
            label: 'Party Name',
            value: partyDisplay.toUpperCase(),
            isBoldValue: true,
          ),
          const SizedBox(height: 12),

          // Date Row
          _buildInfoRow(
            icon: Icons.calendar_month,
            iconColor: const Color(0xFF43A047),
            label: 'Date',
            value: payment.date,
          ),
          const SizedBox(height: 12),

          // Receipt No Row
          _buildInfoRow(
            icon: Icons.receipt_long,
            iconColor: const Color(0xFF00897B),
            label: 'Receipt No.',
            value: txnIdDisplay,
          ),
          const SizedBox(height: 16),

          // Highlighted Golden Box (Bill & Amount Details)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFFFD54F), width: 1.5),
            ),
            child: Column(
              children: [
                _buildBoxRow(
                  icon: Icons.receipt,
                  iconColor: const Color(0xFFF57C00),
                  label: 'Bill No.',
                  value: billNoDisplay,
                ),
                const Divider(height: 16, color: Color(0xFFFFECB3)),
                _buildBoxRow(
                  icon: Icons.attach_money,
                  iconColor: const Color(0xFFE64A19),
                  label: 'Bill Amount',
                  value: '₹${billAmountDisplay.toStringAsFixed(0)}',
                ),
                const Divider(height: 16, color: Color(0xFFFFECB3)),
                _buildBoxRow(
                  icon: Icons.currency_rupee,
                  iconColor: const Color(0xFF1E88E5),
                  label: 'Payment',
                  value: '₹${paidAmountDisplay.toStringAsFixed(0)}',
                  valueColor: const Color(0xFF2E7D32),
                  isLarge: true,
                ),
                const Divider(height: 16, color: Color(0xFFFFECB3)),
                _buildBoxRow(
                  icon: Icons.arrow_downward,
                  iconColor: const Color(0xFFD32F2F),
                  label: 'Due',
                  value: '₹${dueRemainingDisplay.toStringAsFixed(2)}',
                  valueColor: dueRemainingDisplay > 0 ? const Color(0xFFC62828) : const Color(0xFF2E7D32),
                  isLarge: true,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Payment Mode
          _buildInfoRow(
            icon: Icons.account_balance_wallet,
            iconColor: const Color(0xFF8E24AA),
            label: 'Mode',
            value: modeDisplay,
          ),
          const SizedBox(height: 12),

          // Transaction ID / Notes
          _buildInfoRow(
            icon: Icons.badge,
            iconColor: const Color(0xFFE91E63),
            label: 'Transaction',
            value: payment.notes.isNotEmpty ? payment.notes : 'SUCCESSFUL',
          ),
          const SizedBox(height: 18),

          // Green Payment Status Badge
          Container(
            padding: const EdgeInsets.symmetric(vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F5E9),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFA5D6A7)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.check_circle, color: Color(0xFF2E7D32), size: 24),
                SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'PAYMENT STATUS',
                      style: TextStyle(
                        fontSize: 9.5,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                        letterSpacing: 0.5,
                      ),
                    ),
                    Text(
                      'SUCCESSFUL',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B5E20),
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Thank you message
          const Center(
            child: Text(
              'Thank you for your payment.',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: Color(0xFF102A43),
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Agency & Footer
          Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.receipt, color: Color(0xFF0D3B66), size: 18),
                const SizedBox(width: 6),
                Text(
                  agencyName,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF0D3B66),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _buildDashedLine(),
          const SizedBox(height: 8),
          const Center(
            child: Text(
              'Developed by Imtiyaz Khanusia',
              style: TextStyle(
                fontSize: 10,
                fontStyle: FontStyle.italic,
                color: Color(0xFF777777),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashedLine() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final boxWidth = constraints.constrainWidth();
        const dashWidth = 5.0;
        const dashHeight = 1.5;
        final dashCount = (boxWidth / (2 * dashWidth)).floor();
        return Flex(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          direction: Axis.horizontal,
          children: List.generate(dashCount, (_) {
            return const SizedBox(
              width: dashWidth,
              height: dashHeight,
              child: DecoratedBox(
                decoration: BoxDecoration(color: Color(0xFF0D3B66)),
              ),
            );
          }),
        );
      },
    );
  }

  Widget _buildInfoRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    bool isBoldValue = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor),
        const SizedBox(width: 10),
        SizedBox(
          width: 90,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF102A43),
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF102A43))),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBoldValue ? FontWeight.w900 : FontWeight.w700,
              color: const Color(0xFF102A43),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBoxRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
    bool isLarge = false,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 8),
        SizedBox(
          width: 85,
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Color(0xFF333333),
            ),
          ),
        ),
        const Text(': ', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF333333))),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: isLarge ? 15 : 13,
              fontWeight: FontWeight.w900,
              color: valueColor ?? const Color(0xFF102A43),
            ),
          ),
        ),
      ],
    );
  }
}
