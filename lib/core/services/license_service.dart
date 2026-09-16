class LicenseResult {
  final bool isValid;
  final String status; // 'active', 'expired', 'invalid', 'tampered'
  final String plan;
  final String expiryDate;
  final int remainingDays;
  final String? message;

  LicenseResult({
    required this.isValid,
    required this.status,
    required this.plan,
    required this.expiryDate,
    required this.remainingDays,
    this.message,
  });
}

class LicenseService {
  static const String secretSalt = "VS_SECURE_SALT_2026";

  /// 32-bit FNV-1a Hash function for Cryptographic Checksum Matching Web/Admin
  static String computeChecksum(String agencyId, String dateStr, String planCode) {
    final str = "${agencyId}_${dateStr}_${planCode}_$secretSalt";
    int hash = 0x811c9dc5;
    for (int i = 0; i < str.length; i++) {
      hash ^= str.codeUnitAt(i);
      hash = (hash * 0x01000193) & 0xFFFFFFFF;
    }
    return hash.toRadixString(16).toUpperCase().padLeft(8, '0').substring(4);
  }

  /// Verify Cryptographic License Key Format: VS-YYMMDD-XXXX-CRC4
  static LicenseResult verifyKey(String key, String agencyId) {
    if (key.trim().isEmpty) {
      return LicenseResult(
        isValid: false,
        status: 'invalid',
        plan: 'Unknown',
        expiryDate: '',
        remainingDays: 0,
        message: 'કૃપા કરીને લાયસન્સ કી દાખલ કરો.',
      );
    }

    final cleanKey = key.trim().toUpperCase();
    final parts = cleanKey.split('-');
    if (parts.length != 4 || parts[0] != 'VS') {
      return LicenseResult(
        isValid: false,
        status: 'invalid',
        plan: 'Unknown',
        expiryDate: '',
        remainingDays: 0,
        message: 'અમાન્ય લાયસન્સ કી ફોર્મેટ! (દા.ત. VS-261031-1AF4-XXXX)',
      );
    }

    final datePart = parts[1]; // YYMMDD
    final agyPart = parts[2];  // Last 4 of Agency ID
    final checksum = parts[3]; // 4-char CRC

    final agyClean = agencyId.replaceAll(RegExp(r'[^A-Za-z0-9]'), '').toUpperCase();
    final agyTail = agyClean.length >= 4 ? agyClean.substring(agyClean.length - 4) : agyClean;

    if (agyPart != agyTail) {
      return LicenseResult(
        isValid: false,
        status: 'invalid',
        plan: 'Unknown',
        expiryDate: '',
        remainingDays: 0,
        message: 'આ લાયસન્સ કી અન્ય એજન્સી માટે છે! તમારી Agency ID સાથે મેળ ખાતી નથી.',
      );
    }

    // Try plan codes: M, Q, H, Y, L
    String matchedPlan = '';
    bool checksumMatched = false;
    for (final p in ['M', 'Q', 'H', 'Y', 'L']) {
      if (computeChecksum(agencyId, datePart, p) == checksum) {
        checksumMatched = true;
        if (p == 'L') matchedPlan = 'Lifetime SaaS';
        else if (p == 'Y') matchedPlan = '1 Year SaaS (₹4,999)';
        else if (p == 'H') matchedPlan = '6 Months SaaS (₹2,699)';
        else if (p == 'Q') matchedPlan = '3 Months SaaS (₹1,399)';
        else matchedPlan = 'Monthly SaaS (₹499)';
        break;
      }
    }

    if (!checksumMatched) {
      return LicenseResult(
        isValid: false,
        status: 'tampered',
        plan: 'Unknown',
        expiryDate: '',
        remainingDays: 0,
        message: 'સિક્યોરિટી ચેકસમ મેળ ખાતો નથી! લાયસન્સ કી ખોટી અથવા ફેરફાર કરેલી છે.',
      );
    }

    // Format Expiry Date: 20YY-MM-DD
    final year = "20${datePart.substring(0, 2)}";
    final month = datePart.substring(2, 4);
    final day = datePart.substring(4, 6);
    final expiryIso = "$year-$month-$day";

    try {
      final expiry = DateTime.parse(expiryIso);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final diff = expiry.difference(today).inDays;

      if (diff < 0) {
        return LicenseResult(
          isValid: false,
          status: 'expired',
          plan: matchedPlan,
          expiryDate: expiryIso,
          remainingDays: diff,
          message: 'આ લાયસન્સ કી ની મુદત પૂરી થઈ ગઈ છે.',
        );
      }

      return LicenseResult(
        isValid: true,
        status: 'active',
        plan: matchedPlan,
        expiryDate: expiryIso,
        remainingDays: diff,
        message: 'લાયસન્સ સફળતાપૂર્વક માન્ય થયું!',
      );
    } catch (e) {
      return LicenseResult(
        isValid: false,
        status: 'invalid',
        plan: matchedPlan,
        expiryDate: expiryIso,
        remainingDays: 0,
        message: 'તારીખ અમાન્ય છે.',
      );
    }
  }
}
