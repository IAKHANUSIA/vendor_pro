class BankAccount {
  final String id;
  final String bankName;
  final String accountNumber;
  final String ifsc;
  final String holderName;
  final double initialBalance;
  final double currentBalance;
  final String accountType; // 'savings', 'current', 'cash_drawer'

  BankAccount({
    required this.id,
    required this.bankName,
    required this.accountNumber,
    this.ifsc = '',
    this.holderName = '',
    this.initialBalance = 0.0,
    this.currentBalance = 0.0,
    this.accountType = 'savings',
  });

  factory BankAccount.fromJson(Map<String, dynamic> json) {
    return BankAccount(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      bankName: json['bankName']?.toString() ?? '',
      accountNumber: json['accountNumber']?.toString() ?? '',
      ifsc: json['ifsc']?.toString() ?? '',
      holderName: json['holderName']?.toString() ?? '',
      initialBalance: (json['initialBalance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ??
          (json['initialBalance'] as num?)?.toDouble() ??
          0.0,
      accountType: json['accountType']?.toString() ?? 'savings',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bankName': bankName,
    'accountNumber': accountNumber,
    'ifsc': ifsc,
    'holderName': holderName,
    'initialBalance': initialBalance,
    'currentBalance': currentBalance,
    'accountType': accountType,
  };

  BankAccount copyWith({
    String? id,
    String? bankName,
    String? accountNumber,
    String? ifsc,
    String? holderName,
    double? initialBalance,
    double? currentBalance,
    String? accountType,
  }) {
    return BankAccount(
      id: id ?? this.id,
      bankName: bankName ?? this.bankName,
      accountNumber: accountNumber ?? this.accountNumber,
      ifsc: ifsc ?? this.ifsc,
      holderName: holderName ?? this.holderName,
      initialBalance: initialBalance ?? this.initialBalance,
      currentBalance: currentBalance ?? this.currentBalance,
      accountType: accountType ?? this.accountType,
    );
  }
}

class BankTransaction {
  final String id;
  final String bankAccountId;
  final String date; // YYYY-MM-DD
  final String type; // 'deposit', 'withdrawal', 'transfer'
  final double amount;
  final String partyName;
  final String note;
  final String refNo;

  BankTransaction({
    required this.id,
    required this.bankAccountId,
    required this.date,
    required this.type,
    required this.amount,
    this.partyName = '',
    this.note = '',
    this.refNo = '',
  });

  factory BankTransaction.fromJson(Map<String, dynamic> json) {
    return BankTransaction(
      id: json['id']?.toString() ?? DateTime.now().millisecondsSinceEpoch.toString(),
      bankAccountId: json['bankAccountId']?.toString() ?? '',
      date: json['date']?.toString() ?? DateTime.now().toIso8601String().split('T')[0],
      type: json['type']?.toString() ?? 'deposit',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      partyName: json['partyName']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      refNo: json['refNo']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'bankAccountId': bankAccountId,
    'date': date,
    'type': type,
    'amount': amount,
    'partyName': partyName,
    'note': note,
    'refNo': refNo,
  };
}
