class Firm {
  final String id;
  final String name;
  final String ownerName;
  final String phone;
  final String address;
  final String upiId;
  final String bankDetails;
  final String billNoFormat; // 'sequential', 'month_prefix', 'custom_prefix'
  final String billNoPrefix;
  final int billNoStartNum;
  final int billNoPadding;
  final String termsAndConditions;

  Firm({
    this.id = 'primary',
    this.name = 'Vendor Pro Agency',
    this.ownerName = '',
    this.phone = '',
    this.address = '',
    this.upiId = '',
    this.bankDetails = '',
    this.billNoFormat = 'sequential',
    this.billNoPrefix = 'VP',
    this.billNoStartNum = 1001,
    this.billNoPadding = 4,
    String? termsAndConditions,
    String? billNotes,
  }) : termsAndConditions = billNotes ??
            termsAndConditions ??
            'દરેક મહિનાની ૧૦ તારીખ પહેલા બિલની રકમ જમા કરાવી આપવા વિનંતી.';

  String get billNotes => termsAndConditions;

  factory Firm.fromJson(Map<String, dynamic> json) {
    return Firm(
      id: json['id']?.toString() ?? 'primary',
      name: json['name']?.toString() ?? 'Vendor Pro Agency',
      ownerName: json['ownerName']?.toString() ?? '',
      phone: json['phone']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      upiId: json['upiId']?.toString() ?? '',
      bankDetails: json['bankDetails']?.toString() ?? '',
      billNoFormat: json['billNoFormat']?.toString() ?? 'sequential',
      billNoPrefix: json['billNoPrefix']?.toString() ?? 'VP',
      billNoStartNum: (json['billNoStartNum'] as num?)?.toInt() ?? 1001,
      billNoPadding: (json['billNoPadding'] as num?)?.toInt() ?? 4,
      termsAndConditions: json['billNotes']?.toString() ??
          json['termsAndConditions']?.toString() ??
          'દરેક મહિનાની ૧૦ તારીખ પહેલા બિલની રકમ જમા કરાવી આપવા વિનંતી.',
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'ownerName': ownerName,
    'phone': phone,
    'address': address,
    'upiId': upiId,
    'bankDetails': bankDetails,
    'billNoFormat': billNoFormat,
    'billNoPrefix': billNoPrefix,
    'billNoStartNum': billNoStartNum,
    'billNoPadding': billNoPadding,
    'termsAndConditions': termsAndConditions,
    'billNotes': billNotes,
  };
}
