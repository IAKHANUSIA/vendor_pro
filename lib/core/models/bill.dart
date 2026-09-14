class PaperBreakdownItem {
  final int id;
  final String name;
  final String code;
  final int daysCount;
  final double totalCost;
  final String startDate;
  final String endDate;
  final bool isMonthly;

  PaperBreakdownItem({
    required this.id,
    required this.name,
    required this.code,
    required this.daysCount,
    required this.totalCost,
    required this.startDate,
    required this.endDate,
    this.isMonthly = false,
  });

  factory PaperBreakdownItem.fromJson(Map<String, dynamic> json) {
    return PaperBreakdownItem(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      daysCount: (json['daysCount'] as num?)?.toInt() ?? 0,
      totalCost: (json['totalCost'] as num?)?.toDouble() ?? 0.0,
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      isMonthly: json['isMonthly'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'code': code,
    'daysCount': daysCount,
    'totalCost': totalCost,
    'startDate': startDate,
    'endDate': endDate,
    'isMonthly': isMonthly,
  };
}

class Bill {
  final int id;
  final int customerId;
  final String customerNo;
  final String customerName;
  final int routeId;
  final String monthYear; // YYYY-MM
  final String billNo;
  final int deliveryDays;
  final int vacationDays;
  final double vacationDeduction;
  final double newspaperAmount;
  final double deliveryCharge;
  final double currentAmount;
  final double pastBalance;
  final double finalPayable;
  double paymentReceived;
  final Map<String, PaperBreakdownItem> paperBreakdown;
  final String generatedAt;
  String status; // 'pending', 'paid', 'partial'

  Bill({
    required this.id,
    required this.customerId,
    this.customerNo = '',
    this.customerName = '',
    this.routeId = 0,
    required this.monthYear,
    required this.billNo,
    this.deliveryDays = 0,
    this.vacationDays = 0,
    this.vacationDeduction = 0.0,
    this.newspaperAmount = 0.0,
    this.deliveryCharge = 0.0,
    this.currentAmount = 0.0,
    this.pastBalance = 0.0,
    this.finalPayable = 0.0,
    this.paymentReceived = 0.0,
    Map<String, PaperBreakdownItem>? paperBreakdown,
    String? generatedAt,
    this.status = 'pending',
  })  : paperBreakdown = paperBreakdown ?? {},
        generatedAt = generatedAt ?? DateTime.now().toIso8601String();

  double get balanceDue => (finalPayable - paymentReceived).clamp(0.0, double.infinity);

  factory Bill.fromJson(Map<String, dynamic> json) {
    final pb = <String, PaperBreakdownItem>{};
    if (json['paperBreakdown'] is Map) {
      (json['paperBreakdown'] as Map).forEach((k, v) {
        if (v is Map) pb[k.toString()] = PaperBreakdownItem.fromJson(Map<String, dynamic>.from(v));
      });
    } else if (json['paperBreakdown'] is List) {
      for (final item in json['paperBreakdown']) {
        if (item is Map) {
          final pbi = PaperBreakdownItem.fromJson(Map<String, dynamic>.from(item));
          pb[pbi.id.toString()] = pbi;
        }
      }
    }

    final netPay = (json['finalPayable'] ?? json['totalPayable'] as num?)?.toDouble() ?? 0.0;
    final rec = (json['paymentReceived'] as num?)?.toDouble() ?? 0.0;

    return Bill(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      customerNo: json['customerNo']?.toString() ?? '',
      customerName: json['customerName']?.toString() ?? '',
      routeId: (json['routeId'] as num?)?.toInt() ?? 0,
      monthYear: json['monthYear']?.toString() ?? '',
      billNo: json['billNo']?.toString() ?? '',
      deliveryDays: (json['deliveryDays'] ?? json['daysDelivered'] as num?)?.toInt() ?? 0,
      vacationDays: (json['vacationDays'] as num?)?.toInt() ?? 0,
      vacationDeduction: (json['vacationDeduction'] as num?)?.toDouble() ?? 0.0,
      newspaperAmount: (json['newspaperAmount'] as num?)?.toDouble() ?? 0.0,
      deliveryCharge: (json['deliveryCharge'] ?? json['delCharge'] as num?)?.toDouble() ?? 0.0,
      currentAmount: (json['currentAmount'] as num?)?.toDouble() ?? 0.0,
      pastBalance: (json['pastBalance'] ?? json['pastArrears'] as num?)?.toDouble() ?? 0.0,
      finalPayable: netPay,
      paymentReceived: rec,
      paperBreakdown: pb,
      generatedAt: json['generatedAt']?.toString() ?? json['dateGenerated']?.toString(),
      status: json['status']?.toString() ?? (rec >= netPay && netPay > 0 ? 'paid' : (rec > 0 ? 'partial' : 'pending')),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'customerNo': customerNo,
    'customerName': customerName,
    'routeId': routeId,
    'monthYear': monthYear,
    'billNo': billNo,
    'deliveryDays': deliveryDays,
    'vacationDays': vacationDays,
    'vacationDeduction': vacationDeduction,
    'newspaperAmount': newspaperAmount,
    'deliveryCharge': deliveryCharge,
    'currentAmount': currentAmount,
    'pastBalance': pastBalance,
    'finalPayable': finalPayable,
    'paymentReceived': paymentReceived,
    'paperBreakdown': paperBreakdown.map((k, v) => MapEntry(k, v.toJson())),
    'generatedAt': generatedAt,
    'status': status,
  };

  String generateWhatsAppText({required String firmName, required String upiId}) {
    final buffer = StringBuffer();
    buffer.writeln('📰 *$firmName*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('નમસ્તે *$customerName*,');
    buffer.writeln('તમારું માસિક ન્યૂઝપેપર બિલ નીચે મુજબ છે:');
    buffer.writeln('📄 *બિલ નંબર:* $billNo');
    buffer.writeln('📅 *મહિનો:* $monthYear');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    
    paperBreakdown.forEach((_, item) {
      buffer.writeln('• ${item.name}: ${item.daysCount} દિવસ = ₹${item.totalCost.toStringAsFixed(0)}');
    });

    if (deliveryCharge > 0) {
      buffer.writeln('• વિતરણ ચાર્જ (Delivery): ₹${deliveryCharge.toStringAsFixed(0)}');
    }
    if (pastBalance > 0) {
      buffer.writeln('• પાછલી બાકી રકમ (Old Balance): ₹${pastBalance.toStringAsFixed(0)}');
    }
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');
    buffer.writeln('💰 *કુલ ચૂકવવાપાત્ર રકમ: ₹${balanceDue.toStringAsFixed(0)}*');
    buffer.writeln('━━━━━━━━━━━━━━━━━━━━');

    if (upiId.isNotEmpty) {
      buffer.writeln('📱 *Google Pay / PhonePe / Paytm દ્વારા ચૂકવણી:*');
      buffer.writeln('UPI ID: `$upiId`');
      buffer.writeln('UPI લિંક: upi://pay?pa=$upiId&pn=${Uri.encodeComponent(firmName)}&am=${balanceDue.toStringAsFixed(2)}&cu=INR&tn=Bill-$billNo');
      buffer.writeln('');
    }
    buffer.writeln('આભાર સહ,');
    buffer.writeln('*$firmName*');
    return buffer.toString();
  }
}

class Payment {
  final int id;
  final int customerId;
  final String date; // YYYY-MM-DD
  final double amount;
  final String paymentMode; // 'cash', 'upi', 'gpay', 'phonepe', 'cheque'
  final String receiptNo;
  final String billMonthYear;
  final String notes;

  Payment({
    required this.id,
    required this.customerId,
    required this.date,
    required this.amount,
    this.paymentMode = 'cash',
    this.receiptNo = '',
    this.billMonthYear = '',
    this.notes = '',
  });

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      date: json['date']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: json['paymentMode']?.toString() ?? 'cash',
      receiptNo: json['receiptNo']?.toString() ?? '',
      billMonthYear: json['billMonthYear']?.toString() ?? '',
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'date': date,
    'amount': amount,
    'paymentMode': paymentMode,
    'receiptNo': receiptNo,
    'billMonthYear': billMonthYear,
    'notes': notes,
  };
}
