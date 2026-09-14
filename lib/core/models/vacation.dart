class Vacation {
  final int id;
  final int customerId;
  final String startDate; // YYYY-MM-DD
  final String endDate; // YYYY-MM-DD
  final String reason;

  Vacation({
    required this.id,
    required this.customerId,
    required this.startDate,
    required this.endDate,
    this.reason = '',
  });

  bool isActiveOn(String dateStr) {
    return dateStr.compareTo(startDate) >= 0 && dateStr.compareTo(endDate) <= 0;
  }

  factory Vacation.fromJson(Map<String, dynamic> json) {
    return Vacation(
      id: (json['id'] as num?)?.toInt() ?? 0,
      customerId: (json['customerId'] as num?)?.toInt() ?? 0,
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'customerId': customerId,
    'startDate': startDate,
    'endDate': endDate,
    'reason': reason,
  };
}

class PaperHoliday {
  final int id;
  final int itemId;
  final String startDate;
  final String endDate;
  final String reason;

  PaperHoliday({
    required this.id,
    required this.itemId,
    required this.startDate,
    required this.endDate,
    this.reason = '',
  });

  bool isActiveOn(int checkItemId, String dateStr) {
    return checkItemId == itemId && dateStr.compareTo(startDate) >= 0 && dateStr.compareTo(endDate) <= 0;
  }

  factory PaperHoliday.fromJson(Map<String, dynamic> json) {
    return PaperHoliday(
      id: (json['id'] as num?)?.toInt() ?? 0,
      itemId: (json['itemId'] as num?)?.toInt() ?? 0,
      startDate: json['startDate']?.toString() ?? '',
      endDate: json['endDate']?.toString() ?? '',
      reason: json['reason']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'itemId': itemId,
    'startDate': startDate,
    'endDate': endDate,
    'reason': reason,
  };
}
