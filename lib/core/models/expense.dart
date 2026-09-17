class Expense {
  final int id;
  final String date; // YYYY-MM-DD
  final String category; // 'petrol', 'tea_snacks', 'salary', 'maintenance', 'rent', 'misc'
  final String title;
  final double amount;
  final String paymentMode; // 'cash', 'upi', 'bank'
  final String notes;
  final String? bankAccountId;

  Expense({
    required this.id,
    required this.date,
    required this.category,
    String? title,
    String? paidTo,
    required this.amount,
    this.paymentMode = 'cash',
    this.bankAccountId,
    String? notes,
    String? remarks,
  })  : title = title ?? paidTo ?? '',
        notes = notes ?? remarks ?? '';

  String get paidTo => title;
  String get remarks => notes;

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: (json['id'] as num?)?.toInt() ?? 0,
      date: json['date']?.toString() ?? '',
      category: json['category']?.toString() ?? 'misc',
      title: json['title']?.toString() ?? json['paidTo']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: json['paymentMode']?.toString() ?? 'cash',
      bankAccountId: json['bankAccountId']?.toString(),
      notes: json['notes']?.toString() ?? json['remarks']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'category': category,
    'title': title,
    'paidTo': title,
    'amount': amount,
    'paymentMode': paymentMode,
    'bankAccountId': bankAccountId,
    'notes': notes,
    'remarks': notes,
  };
}
