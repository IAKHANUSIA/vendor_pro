class Expense {
  final int id;
  final String date; // YYYY-MM-DD
  final String category; // 'hawker_salary', 'depot_tea_snack', 'fuel_transport', 'stationary', 'misc'
  final String title;
  final double amount;
  final String paymentMode; // 'cash', 'upi', 'bank'
  final String notes;

  Expense({
    required this.id,
    required this.date,
    required this.category,
    required this.title,
    required this.amount,
    this.paymentMode = 'cash',
    this.notes = '',
  });

  factory Expense.fromJson(Map<String, dynamic> json) {
    return Expense(
      id: (json['id'] as num?)?.toInt() ?? 0,
      date: json['date']?.toString() ?? '',
      category: json['category']?.toString() ?? 'misc',
      title: json['title']?.toString() ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMode: json['paymentMode']?.toString() ?? 'cash',
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'category': category,
    'title': title,
    'amount': amount,
    'paymentMode': paymentMode,
    'notes': notes,
  };
}
