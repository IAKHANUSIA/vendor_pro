class DeliveryRoute {
  final int id;
  final String code;
  final String name;
  final int? salesmanId;
  final int? collectionManId;
  final double defaultDeliveryCharge;
  String status;

  DeliveryRoute({
    required this.id,
    required this.code,
    required this.name,
    this.salesmanId,
    this.collectionManId,
    this.defaultDeliveryCharge = 0.0,
    this.status = 'active',
  });

  bool get isActive => status == 'active';

  factory DeliveryRoute.fromJson(Map<String, dynamic> json) {
    return DeliveryRoute(
      id: (json['id'] as num?)?.toInt() ?? 0,
      code: json['code']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      salesmanId: (json['salesmanId'] as num?)?.toInt(),
      collectionManId: (json['collectionManId'] as num?)?.toInt(),
      defaultDeliveryCharge: (json['defaultDeliveryCharge'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'active',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'code': code,
    'name': name,
    'salesmanId': salesmanId,
    'collectionManId': collectionManId,
    'defaultDeliveryCharge': defaultDeliveryCharge,
    'status': status,
  };
}
