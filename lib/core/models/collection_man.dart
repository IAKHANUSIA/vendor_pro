class CollectionMan {
  final int id;
  final String name;
  final String mobile;
  final String address;
  final double commissionRate;
  String status; // 'active' or 'inactive'
  final String pin; // 4 to 8 digit login PIN

  CollectionMan({
    required this.id,
    required this.name,
    this.mobile = '',
    this.address = '',
    this.commissionRate = 0.0,
    this.status = 'active',
    this.pin = '1111',
  });

  bool get isActive => status == 'active';

  factory CollectionMan.fromJson(Map<String, dynamic> json) {
    return CollectionMan(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      commissionRate: (json['commissionRate'] as num?)?.toDouble() ?? 0.0,
      status: json['status']?.toString() ?? 'active',
      pin: json['pin']?.toString() ?? '1111',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'mobile': mobile,
    'address': address,
    'commissionRate': commissionRate,
    'status': status,
    'pin': pin,
  };
}
