import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../../core/models/bill.dart';
import '../../../core/models/firm.dart';
import '../../../core/models/customer.dart';
import '../../../core/models/route.dart';
import '../../../core/models/salesman.dart';

class MonthlyBillImageCard extends StatelessWidget {
  final Bill bill;
  final Firm firm;
  final Customer? customer;
  final DeliveryRoute? route;
  final Salesman? salesman;

  const MonthlyBillImageCard({
    super.key,
    required this.bill,
    required this.firm,
    this.customer,
    this.route,
    this.salesman,
  });

  @override
  Widget build(BuildContext context) {
    final upiId = firm.upiId.isNotEmpty ? firm.upiId : '9427698665@upi';
    final firmName = firm.name.isNotEmpty ? firm.name : 'PERFECT NEWSPAPER SUPPLIERS';
    final firmPhone = firm.phone.isNotEmpty ? firm.phone : '9427698665';
    final firmAddress = firm.address.isNotEmpty ? firm.address : 'E-392, SANKALITNAGAR, JUHAPURA, AHMEDABAD';

    final custName = customer?.name ?? bill.customerName;
    final custCode = customer?.custNo ?? bill.customerNo;
    final custAddress = customer?.buildingAddress.isNotEmpty == true 
        ? customer!.buildingAddress 
        : (customer?.address ?? '');
    final custMobile = customer?.phone.isNotEmpty == true 
        ? customer!.phone 
        : (customer?.mobile ?? '-');
    final salesmanName = salesman?.name ?? '-';
    final routeCode = route?.code ?? '-';

    final upiUrl = 'upi://pay?pa=$upiId&pn=${Uri.encodeComponent(firmName)}&am=${bill.finalPayable.toStringAsFixed(2)}&cu=INR&tn=Bill-${bill.billNo}';

    final items = bill.paperBreakdown.values.toList();

    return Container(
      width: 580,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0F2A4A), width: 2.5),
        boxShadow: const [
          BoxShadow(color: Colors.black26, blurRadius: 15, offset: Offset(0, 6)),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Credit Memo Top Tag
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF0F2A4A),
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Text(
                'Credit Memo',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // 2. Firm Header
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Logo Icon
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF0F2A4A),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    firmName.isNotEmpty ? firmName.substring(0, 1).toUpperCase() : 'P',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      firmName.toUpperCase(),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF0F2A4A),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '📍 $firmAddress',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF444444),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '📞 Mo: $firmPhone',
                      style: const TextStyle(
                        fontSize: 11,
                        color: Color(0xFF444444),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Divider(height: 1, thickness: 1.5, color: Color(0xFF0F2A4A)),
          const SizedBox(height: 10),

          // 3. Customer Info & Billing Meta Box
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF4F7FB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFD0DBE5)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left: Customer details
                Expanded(
                  flex: 6,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Text('Name: ', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF222222))),
                          Expanded(
                            child: Text(
                              '$custName (#$custCode)',
                              style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 13.5, color: Color(0xFF0F2A4A)),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      if (custAddress.isNotEmpty) ...[
                        const SizedBox(height: 3),
                        Text('Address: $custAddress', style: const TextStyle(fontSize: 11.5, color: Color(0xFF333333))),
                      ],
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Text('Mobile: $custMobile', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
                          const SizedBox(width: 14),
                          Text('Salesman: $salesmanName', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF222222))),
                        ],
                      ),
                    ],
                  ),
                ),
                // Right: Bill No & Period
                Expanded(
                  flex: 4,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Bill No : ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF222222))),
                          Text(bill.billNo, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: Color(0xFF0F2A4A))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          const Text('Month : ', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF222222))),
                          Text(bill.monthYear, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: Color(0xFF0F2A4A))),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Line : $routeCode', style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: Color(0xFF444444))),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 4. Newspaper Items Table (WITHOUT Rate column as requested)
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFF0F2A4A), width: 1.2),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  color: const Color(0xFF0F2A4A),
                  child: const Row(
                    children: [
                      SizedBox(
                        width: 35,
                        child: Text('No.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                      ),
                      Expanded(
                        child: Text('Newspaper', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                      ),
                      SizedBox(
                        width: 70,
                        child: Text('Days', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.center),
                      ),
                      SizedBox(
                        width: 90,
                        child: Text('Amount (₹)', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12), textAlign: TextAlign.right),
                      ),
                    ],
                  ),
                ),
                // Table Rows
                if (items.isEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: Row(
                      children: [
                        const SizedBox(width: 35, child: Text('1', textAlign: TextAlign.center, style: TextStyle(fontSize: 12))),
                        const Expanded(child: Text('માસિક લવાજમ (Monthly Fixed)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600))),
                        SizedBox(width: 70, child: Text('${bill.deliveryDays}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12))),
                        SizedBox(width: 90, child: Text('₹${bill.newspaperAmount.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12))),
                      ],
                    ),
                  )
                else
                  for (int i = 0; i < items.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: i % 2 == 1 ? const Color(0xFFF7F9FC) : Colors.white,
                        border: i < items.length - 1 ? const Border(bottom: BorderSide(color: Color(0xFFE5E9F0))) : null,
                      ),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 35,
                            child: Text('${i + 1}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, color: Color(0xFF333333))),
                          ),
                          Expanded(
                            child: Text(
                              items[i].name.toUpperCase(),
                              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Color(0xFF111111)),
                            ),
                          ),
                          SizedBox(
                            width: 70,
                            child: Text('${items[i].daysCount}', textAlign: TextAlign.center, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF333333))),
                          ),
                          SizedBox(
                            width: 90,
                            child: Text('₹${items[i].totalCost.toStringAsFixed(2)}', textAlign: TextAlign.right, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800, color: Color(0xFF0F2A4A))),
                          ),
                        ],
                      ),
                    ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 5. Previous Month Balance Strip
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: const Color(0xFFE8F4FD),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: const Color(0xFFBCE0FD)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'ગયા મહિના સુધીની બાકી રકમ : ',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Color(0xFF0F2A4A)),
                ),
                Text(
                  '₹${bill.pastBalance.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w900,
                    color: bill.pastBalance > 0 ? const Color(0xFFD9534F) : const Color(0xFF2E7D32),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),

          // 6. QR Code & Bill Summary Split Box
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left: Scan & Pay QR Code Box
              Expanded(
                flex: 5,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0F2A4A), width: 1.2),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0F2A4A),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: const Center(
                          child: Text(
                            'Scan & Pay',
                            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        width: 105,
                        height: 105,
                        child: QrImageView(
                          data: upiUrl,
                          version: QrVersions.auto,
                          padding: const EdgeInsets.all(2),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _buildAppBadge('GPay', const Color(0xFF4285F4)),
                          const SizedBox(width: 4),
                          _buildAppBadge('PhonePe', const Color(0xFF5F259F)),
                          const SizedBox(width: 4),
                          _buildAppBadge('Paytm', const Color(0xFF00B9F1)),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'UPI: $upiId',
                        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF444444)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 10),

              // Right: Detailed Summary Box
              Expanded(
                flex: 6,
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFF0F2A4A), width: 1.2),
                  ),
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8),
                        child: Column(
                          children: [
                            _buildSummaryItem('Newspaper Amount', '₹${bill.newspaperAmount.toStringAsFixed(2)}'),
                            const SizedBox(height: 3),
                            _buildSummaryItem('Previous Balance', '₹${bill.pastBalance.toStringAsFixed(2)}'),
                            const SizedBox(height: 3),
                            _buildSummaryItem('Home Delivery Charge', '₹${bill.deliveryCharge.toStringAsFixed(2)}'),
                            if (bill.vacationDeduction > 0) ...[
                              const SizedBox(height: 3),
                              _buildSummaryItem('Vacation / કપાત', '-₹${bill.vacationDeduction.toStringAsFixed(2)}', isGreen: true),
                            ],
                          ],
                        ),
                      ),
                      // Net Amount Payable Banner
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        decoration: const BoxDecoration(
                          color: Color(0xFF0F2A4A),
                          borderRadius: BorderRadius.only(
                            bottomLeft: Radius.circular(6),
                            bottomRight: Radius.circular(6),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Net Amount Payable :',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                            Text(
                              '₹ ${bill.finalPayable.toStringAsFixed(2)}',
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // 7. Gujarati Notices Box (Matching sample layout)
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFDF5),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFE6D6A8)),
            ),
            child: Column(
              children: [
                const Center(
                  child: Text(
                    '— સૂચના —',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Color(0xFF7A5C00)),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _buildNoticeBox('📅 તા. ૧ થી ૧૦ માં બિલ ચૂકવી દેવું.')),
                    const SizedBox(width: 6),
                    Expanded(child: _buildNoticeBox('🌙 ઇસ્લામિક/જાહેર તહેવારે રજા રહેશે.')),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(child: _buildNoticeBox('📢 પેપર બંધ કરાવવું હોય તો અગાઉથી જાણ કરવી.')),
                    const SizedBox(width: 6),
                    Expanded(child: _buildNoticeBox('💵 દર મહિને સર્વિસ ચાર્જ પેટે ₹${bill.deliveryCharge.toStringAsFixed(0)} વસૂલવામાં આવશે.')),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: const Color(0xFFA5D6A7)),
                  ),
                  child: const Center(
                    child: Text(
                      '📲 ONLINE PAYMENT પછી SCREEN SHOT WhatsApp પર અવશ્ય મોકલવો.',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w900,
                        color: Color(0xFF1B5E20),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // 8. Footer Branding
          const Center(
            child: Text(
              'Developed by Imtiyaz Khanusia  94276 98665',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String title, String amount, {bool isGreen = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(title, style: const TextStyle(fontSize: 11.5, color: Color(0xFF333333))),
        Text(
          amount,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isGreen ? const Color(0xFF2E7D32) : const Color(0xFF111111),
          ),
        ),
      ],
    );
  }

  Widget _buildAppBadge(String text, Color bg) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        text,
        style: const TextStyle(color: Colors.white, fontSize: 8.5, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildNoticeBox(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0xFFE5DCC5)),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 9.5, fontWeight: FontWeight.w600, color: Color(0xFF44391D)),
        textAlign: TextAlign.center,
      ),
    );
  }
}
