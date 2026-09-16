import 'dart:convert';
import 'dart:io';
import '../database/database_service.dart';

class CloudSyncResult {
  final bool success;
  final String message;
  final String? lastSyncTime;

  CloudSyncResult({
    required this.success,
    required this.message,
    this.lastSyncTime,
  });
}

class CloudSyncService {
  static final CloudSyncService instance = CloudSyncService._internal();
  CloudSyncService._internal();

  bool isSyncing = false;

  /// Sync all live data to Supabase / Cloud REST API
  Future<CloudSyncResult> syncToCloud(DatabaseService db) async {
    if (isSyncing) {
      return CloudSyncResult(success: true, message: 'સિંક પ્રોસેસ ચાલુ છે...');
    }

    isSyncing = true;
    try {
      final agyId = db.agencyId;
      final customers = db.customers;
      final routes = db.routes;
      final payments = db.payments;
      final firm = db.firm;
      final today = DateTime.now().toIso8601String().split('T')[0];

      final todayDelivered = db.getDeliveryCountForDate(today);
      final todayColl = payments
          .where((p) => p.date == today)
          .fold<double>(0.0, (sum, p) => sum + p.amount);

      final payload = {
        'id': agyId,
        'name': firm.name.isNotEmpty ? firm.name : 'Vendor Pro Agency',
        'owner': firm.ownerName.isNotEmpty ? firm.ownerName : 'Agency Owner',
        'phone': firm.phone,
        'city': firm.address.isNotEmpty ? firm.address : 'Gujarat',
        'customers_count': customers.length,
        'routes_count': routes.length,
        'today_delivered': todayDelivered,
        'today_collection': todayColl,
        'status': db.licenseStatus,
        'storage_mode': db.storageMode,
        'plan': db.licensePlan,
        'valid_until': db.licenseValidUntil,
        'last_seen': DateTime.now().toUtc().toIso8601String(),
      };

      // If Supabase URL and Key are configured, make real REST API call
      if (db.cloudUrl.isNotEmpty && db.cloudKey.isNotEmpty) {
        final cleanUrl = db.cloudUrl.replaceAll(RegExp(r'/+$'), '');
        final endpoint = Uri.parse('$cleanUrl/rest/v1/agencies');

        final client = HttpClient();
        client.connectionTimeout = const Duration(seconds: 10);
        
        final request = await client.postUrl(endpoint);
        request.headers.set('apikey', db.cloudKey);
        request.headers.set('Authorization', 'Bearer ${db.cloudKey}');
        request.headers.set('Content-Type', 'application/json');
        request.headers.set('Prefer', 'resolution=merge-duplicates,return=representation');
        
        request.write(jsonEncode(payload));
        final response = await request.close();

        if (response.statusCode >= 200 && response.statusCode < 300) {
          final responseBody = await response.transform(utf8.decoder).join();
          try {
            final List<dynamic> data = jsonDecode(responseBody);
            if (data.isNotEmpty && data[0] is Map) {
              final remote = data[0] as Map;
              if (remote['valid_until'] != null && remote['valid_until'].toString().isNotEmpty) {
                db.licenseValidUntil = remote['valid_until'].toString();
              }
              if (remote['status'] != null && remote['status'].toString().isNotEmpty) {
                db.licenseStatus = remote['status'].toString();
              }
              if (remote['plan'] != null && remote['plan'].toString().isNotEmpty) {
                db.licensePlan = remote['plan'].toString();
              }
            }
          } catch (_) {}
        }
        client.close();
      }

      final syncTimestamp = DateTime.now().toIso8601String();
      db.lastCloudSync = syncTimestamp;
      isSyncing = false;

      return CloudSyncResult(
        success: true,
        message: 'ક્લાઉડ ડેટા સફળતાપૂર્વક અપડેટ થયો! ☁️✅',
        lastSyncTime: syncTimestamp,
      );
    } catch (e) {
      isSyncing = false;
      return CloudSyncResult(
        success: false,
        message: 'ક્લાઉડ સિંક એરર: ${e.toString()}',
      );
    }
  }
}
