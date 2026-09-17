class PressReturnEntry {
  final int id;
  final String date; // YYYY-MM-DD
  final int itemId;
  final String itemName;
  final int copies;
  final double creditRate;
  final double creditAmount;
  final String notes;

  PressReturnEntry({
    required this.id,
    required this.date,
    required this.itemId,
    required this.itemName,
    required this.copies,
    required this.creditRate,
    required this.creditAmount,
    this.notes = '',
  });

  factory PressReturnEntry.fromJson(Map<String, dynamic> json) {
    return PressReturnEntry(
      id: (json['id'] as num?)?.toInt() ?? 0,
      date: json['date']?.toString() ?? '',
      itemId: (json['itemId'] as num?)?.toInt() ?? 0,
      itemName: json['itemName']?.toString() ?? '',
      copies: (json['copies'] as num?)?.toInt() ?? 0,
      creditRate: (json['creditRate'] as num?)?.toDouble() ?? 0.0,
      creditAmount: (json['creditAmount'] as num?)?.toDouble() ?? 0.0,
      notes: json['notes']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'date': date,
    'itemId': itemId,
    'itemName': itemName,
    'copies': copies,
    'creditRate': creditRate,
    'creditAmount': creditAmount,
    'notes': notes,
  };
}

class PressItemReconciliation {
  final int itemId;
  final String itemName;
  final String itemCode;
  final int suppliedCopies;
  final double avgPurchaseRate;
  final double grossPurchase;
  final int returnedCopies;
  final double returnCredits;
  final double netPayable;

  PressItemReconciliation({
    required this.itemId,
    required this.itemName,
    required this.itemCode,
    required this.suppliedCopies,
    required this.avgPurchaseRate,
    required this.grossPurchase,
    required this.returnedCopies,
    required this.returnCredits,
    required this.netPayable,
  });
}

class PressReconciliationReport {
  final String monthYear;
  final int totalSuppliedCopies;
  final double totalGrossPurchase;
  final int totalReturnedCopies;
  final double totalReturnCredits;
  final double netPayableToPress;
  final List<PressItemReconciliation> itemsSummary;

  PressReconciliationReport({
    required this.monthYear,
    required this.totalSuppliedCopies,
    required this.totalGrossPurchase,
    required this.totalReturnedCopies,
    required this.totalReturnCredits,
    required this.netPayableToPress,
    required this.itemsSummary,
  });
}
