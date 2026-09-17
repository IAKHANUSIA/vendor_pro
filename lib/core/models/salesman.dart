class Salesman {
  final int id;
  final String name;
  final String mobile;
  final String address;
  final double commissionRate;
  final double salary;
  final String notes;
  String status;
  final String pin; // 4 to 8 digit login PIN

  Salesman({
    required this.id,
    required this.name,
    this.mobile = '',
    this.address = '',
    double? commissionRate,
    double? salary,
    this.notes = '',
    this.status = 'active',
    this.pin = '1111',
  })  : commissionRate = commissionRate ?? salary ?? 0.0,
        salary = salary ?? commissionRate ?? 0.0;

  bool get isActive => status == 'active';

  factory Salesman.fromJson(Map<String, dynamic> json) {
    final sal = (json['salary'] as num?)?.toDouble() ?? (json['commissionRate'] as num?)?.toDouble() ?? 0.0;
    return Salesman(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      commissionRate: sal,
      salary: sal,
      notes: json['notes']?.toString() ?? '',
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
    'salary': salary,
    'notes': notes,
    'status': status,
    'pin': pin,
  };
}
