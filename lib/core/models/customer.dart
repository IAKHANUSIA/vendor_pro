class Customer {
  final int id;
  final String custNo;
  final String code;
  final String name;
  final int routeId;
  final int? salesmanId;
  final int? collectionManId;
  final String sequenceNo;
  final String collectionSequence;
  final String mobile;
  final String whatsapp;
  final String address;
  final String societyShort;
  final dynamic subscriptions; // List<int> or Map<String, dynamic>
  final String billingType; // 'daily' or 'fixed'
  final double fixedMonthlyAmount;
  final double openingBalance;
  double currentBalance;
  String status; // 'active' or 'inactive'
  final String? inactiveDate;
  final bool delChargeEnabled;
  final double delChargeAmt;
  final String? createdAt;

  bool get isActive => status == 'active';

  Customer({
    required this.id,
    this.custNo = '',
    this.code = '',
    required this.name,
    this.routeId = 1,
    this.salesmanId,
    this.collectionManId,
    this.sequenceNo = '1',
    this.collectionSequence = '1',
    String mobile = '',
    String? phone,
    this.whatsapp = '',
    String address = '',
    String? buildingAddress,
    this.societyShort = '',
    this.subscriptions,
    this.billingType = 'daily',
    this.fixedMonthlyAmount = 0.0,
    this.openingBalance = 0.0,
    this.currentBalance = 0.0,
    this.status = 'active',
    this.inactiveDate,
    this.delChargeEnabled = false,
    double delChargeAmt = 0.0,
    double? deliveryCharge,
    this.createdAt,
  })  : mobile = mobile.isNotEmpty ? mobile : (phone ?? ''),
        address = address.isNotEmpty ? address : (buildingAddress ?? ''),
        delChargeAmt = delChargeAmt > 0 ? delChargeAmt : (deliveryCharge ?? 0.0);

  String get phone => mobile.isNotEmpty ? mobile : whatsapp;
  double get deliveryCharge => delChargeAmt;
  String get buildingAddress => address.isNotEmpty ? address : societyShort;

  List<int> get subscriptionItemIds {
    if (subscriptions == null) return [];
    if (subscriptions is List) {
      return (subscriptions as List).map((e) => int.tryParse(e.toString()) ?? 0).where((e) => e > 0).toList();
    }
    if (subscriptions is Map) {
      return (subscriptions as Map).keys.map((k) => int.tryParse(k.toString()) ?? 0).where((e) => e > 0).toList();
    }
    return [];
  }

  bool isSubscribedOnDay(int itemId, int dayOfWeek, [String? dateStr]) {
    if (subscriptions == null) return false;
    const dayNames = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
    final dayStr = (dayOfWeek >= 0 && dayOfWeek < dayNames.length) ? dayNames[dayOfWeek] : 'mon';

    if (subscriptions is List) {
      final list = (subscriptions as List).map((e) => e.toString()).toList();
      return list.contains(itemId.toString());
    }

    if (subscriptions is Map) {
      final map = subscriptions as Map;
      final config = map[itemId] ?? map[itemId.toString()];
      if (config == null) return false;

      if (config is List) {
        if (config.isNotEmpty && config.first is String) {
          return config.contains(dayStr);
        }
        for (final entry in config) {
          if (entry is Map) {
            if (dateStr != null) {
              if (entry['startDate'] != null && dateStr.compareTo(entry['startDate'].toString()) < 0) continue;
              if (entry['endDate'] != null && dateStr.compareTo(entry['endDate'].toString()) > 0) continue;
            }
            final days = entry['days'] is List ? (entry['days'] as List).cast<String>() : <String>[];
            if (days.contains(dayStr)) return true;
          }
        }
      } else if (config is Map) {
        if (dateStr != null) {
          if (config['startDate'] != null && dateStr.compareTo(config['startDate'].toString()) < 0) return false;
          if (config['endDate'] != null && dateStr.compareTo(config['endDate'].toString()) > 0) return false;
        }
        final days = config['days'] is List ? (config['days'] as List).cast<String>() : <String>[];
        return days.contains(dayStr);
      }
    }
    return false;
  }

  bool hasAnyPaperOnDay(int dayOfWeek, [String? dateStr]) {
    final items = subscriptionItemIds;
    for (final id in items) {
      if (isSubscribedOnDay(id, dayOfWeek, dateStr)) return true;
    }
    return false;
  }

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: (json['id'] as num?)?.toInt() ?? 0,
      custNo: json['custNo']?.toString() ?? '',
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      routeId: (json['routeId'] as num?)?.toInt() ?? 1,
      salesmanId: (json['salesmanId'] as num?)?.toInt(),
      collectionManId: (json['collectionManId'] as num?)?.toInt(),
      sequenceNo: json['sequenceNo']?.toString() ?? '1',
      collectionSequence: json['collectionSequence']?.toString() ?? '1',
      mobile: json['mobile']?.toString() ?? json['phone']?.toString() ?? '',
      whatsapp: json['whatsapp']?.toString() ?? '',
      address: json['address']?.toString() ?? json['buildingAddress']?.toString() ?? '',
      societyShort: json['societyShort']?.toString() ?? '',
      subscriptions: json['subscriptions'],
      billingType: json['billingType']?.toString() ?? 'daily',
      fixedMonthlyAmount: (json['fixedMonthlyAmount'] as num?)?.toDouble() ?? 0.0,
      openingBalance: (json['openingBalance'] as num?)?.toDouble() ?? 0.0,
      currentBalance: (json['currentBalance'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'active',
      inactiveDate: json['inactiveDate']?.toString(),
      delChargeEnabled: json['delChargeEnabled'] == true || json['delChargeEnabled'] == 'yes',
      delChargeAmt: (json['delChargeAmt'] ?? json['deliveryCharge'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'custNo': custNo,
    'code': code,
    'name': name,
    'routeId': routeId,
    'salesmanId': salesmanId,
    'collectionManId': collectionManId,
    'sequenceNo': sequenceNo,
    'collectionSequence': collectionSequence,
    'mobile': mobile,
    'phone': phone,
    'whatsapp': whatsapp,
    'address': address,
    'buildingAddress': buildingAddress,
    'societyShort': societyShort,
    'subscriptions': subscriptions,
    'billingType': billingType,
    'fixedMonthlyAmount': fixedMonthlyAmount,
    'openingBalance': openingBalance,
    'currentBalance': currentBalance,
    'status': status,
    'inactiveDate': inactiveDate,
    'delChargeEnabled': delChargeEnabled,
    'delChargeAmt': delChargeAmt,
    'deliveryCharge': deliveryCharge,
    'createdAt': createdAt,
  };
}
