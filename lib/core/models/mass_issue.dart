class MassIssue {
  final int id;
  final int itemId;
  final String date; // YYYY-MM-DD
  final double rate; // Selling Price / MRP
  final double purchaseRate; // Purchase Price / PTR
  final String targetType; // 'all' or 'day_wise'
  final bool holidayForOthers;
  final String reason;

  MassIssue({
    required this.id,
    required this.itemId,
    required this.date,
    this.rate = 0.0,
    this.purchaseRate = 0.0,
    this.targetType = 'all',
    this.holidayForOthers = true,
    this.reason = '',
  });

  factory MassIssue.fromJson(Map<String, dynamic> json) {
    return MassIssue(
      id: (json['id'] as num?)?.toInt() ?? 0,
      itemId: (json['itemId'] as num?)?.toInt() ?? 0,
      date: json['date']?.toString() ?? '',
      rate: (json['rate'] as num?)?.toDouble() ?? 0.0,
      purchaseRate: (json['purchaseRate'] as num?)?.toDouble() ?? 0.0,
      targetType: json['targetType']?.toString() ?? 'all',
      holidayForOthers: json['holidayForOthers'] != false,
      reason: json['reason']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': itemId,
    'date': date,
    'rate': rate,
    'purchaseRate': purchaseRate,
    'targetType': targetType,
    'holidayForOthers': holidayForOthers,
    'reason': reason,
  };
}
