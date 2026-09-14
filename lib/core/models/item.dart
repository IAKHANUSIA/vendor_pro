class DayRate {
  final double sale;
  final double purchase;

  const DayRate({required this.sale, required this.purchase});

  factory DayRate.fromJson(Map<String, dynamic> json) {
    return DayRate(
      sale: (json['sale'] as num?)?.toDouble() ?? 5.0,
      purchase: (json['purchase'] as num?)?.toDouble() ?? 3.32,
    );
  }

  Map<String, dynamic> toJson() => {'sale': sale, 'purchase': purchase};
}

class RateRevision {
  final String effectiveDate; // YYYY-MM-DD
  final Map<String, DayRate> dayRates;
  final double defaultRate;
  final double sundayRate;
  final double monthlyRate;

  RateRevision({
    required this.effectiveDate,
    required this.dayRates,
    required this.defaultRate,
    required this.sundayRate,
    required this.monthlyRate,
  });

  factory RateRevision.fromJson(Map<String, dynamic> json) {
    final dr = <String, DayRate>{};
    if (json['dayRates'] is Map) {
      (json['dayRates'] as Map).forEach((k, v) {
        if (v is Map) dr[k.toString()] = DayRate.fromJson(Map<String, dynamic>.from(v));
      });
    }
    return RateRevision(
      effectiveDate: json['effectiveDate']?.toString() ?? '',
      dayRates: dr,
      defaultRate: (json['defaultRate'] as num?)?.toDouble() ?? 5.0,
      sundayRate: (json['sundayRate'] as num?)?.toDouble() ?? 6.0,
      monthlyRate: (json['monthlyRate'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
    'effectiveDate': effectiveDate,
    'dayRates': dayRates.map((k, v) => MapEntry(k, v.toJson())),
    'defaultRate': defaultRate,
    'sundayRate': sundayRate,
    'monthlyRate': monthlyRate,
  };
}

class Item {
  final int id;
  final String code;
  final String name;
  final String type; // 'daily', 'weekly', 'monthly'
  final double defaultRate;
  final double sundayRate;
  final double monthlyRate;
  final String status; // 'active', 'inactive'
  final Map<String, DayRate> dayRates;
  final List<RateRevision> rateHistory;

  Item({
    required this.id,
    required this.code,
    required this.name,
    this.type = 'daily',
    this.defaultRate = 5.0,
    this.sundayRate = 6.0,
    this.monthlyRate = 0.0,
    this.status = 'active',
    Map<String, DayRate>? dayRates,
    List<RateRevision>? rateHistory,
  })  : dayRates = dayRates ?? _defaultDayRates(defaultRate, sundayRate),
        rateHistory = rateHistory ?? [];

  static Map<String, DayRate> _defaultDayRates(double defSale, double sunSale) {
    final defPur = double.parse((defSale * 0.7).toStringAsFixed(2));
    final sunPur = double.parse((sunSale * 0.7).toStringAsFixed(2));
    return {
      'mon': DayRate(sale: defSale, purchase: defPur),
      'tue': DayRate(sale: defSale, purchase: defPur),
      'wed': DayRate(sale: defSale, purchase: defPur),
      'thu': DayRate(sale: defSale, purchase: defPur),
      'fri': DayRate(sale: defSale, purchase: defPur),
      'sat': DayRate(sale: defSale, purchase: defPur),
      'sun': DayRate(sale: sunSale, purchase: sunPur),
    };
  }

  DayRate getRateForDay(int dayOfWeek, [String? dateStr]) {
    // dayOfWeek: 0 = Sun, 1 = Mon, 2 = Tue, 3 = Wed, 4 = Thu, 5 = Fri, 6 = Sat
    const keys = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
    final key = (dayOfWeek >= 0 && dayOfWeek < keys.length) ? keys[dayOfWeek] : 'mon';

    Map<String, DayRate> activeRates = dayRates;
    if (dateStr != null && rateHistory.isNotEmpty) {
      final sorted = List<RateRevision>.from(rateHistory)
        ..sort((a, b) => b.effectiveDate.compareTo(a.effectiveDate));
      final rev = sorted.firstWhere(
        (r) => dateStr.compareTo(r.effectiveDate) >= 0,
        orElse: () => sorted.first,
      );
      if (rev.dayRates.isNotEmpty) {
        activeRates = rev.dayRates;
      }
    }

    return activeRates[key] ??
        DayRate(
          sale: dayOfWeek == 0 ? sundayRate : defaultRate,
          purchase: double.parse(((dayOfWeek == 0 ? sundayRate : defaultRate) * 0.7).toStringAsFixed(2)),
        );
  }

  factory Item.fromJson(Map<String, dynamic> json) {
    final dr = <String, DayRate>{};
    if (json['dayRates'] is Map) {
      (json['dayRates'] as Map).forEach((k, v) {
        if (v is Map) dr[k.toString()] = DayRate.fromJson(Map<String, dynamic>.from(v));
      });
    }
    final rh = <RateRevision>[];
    if (json['rateHistory'] is List) {
      for (final r in json['rateHistory']) {
        if (r is Map) rh.add(RateRevision.fromJson(Map<String, dynamic>.from(r)));
      }
    }

    return Item(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      type: json['type']?.toString() ?? 'daily',
      defaultRate: (json['defaultRate'] as num?)?.toDouble() ?? 5.0,
      sundayRate: (json['sundayRate'] as num?)?.toDouble() ?? 6.0,
      monthlyRate: (json['monthlyRate'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'active',
      dayRates: dr.isNotEmpty ? dr : null,
      rateHistory: rh,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'type': type,
    'defaultRate': defaultRate,
    'sundayRate': sundayRate,
    'monthlyRate': monthlyRate,
    'status': status,
    'dayRates': dayRates.map((k, v) => MapEntry(k, v.toJson())),
    'rateHistory': rateHistory.map((r) => r.toJson()).toList(),
  };
}
