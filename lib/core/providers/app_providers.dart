import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/database_service.dart';
import '../models/firm.dart';
import '../models/item.dart';
import '../models/route.dart';
import '../models/salesman.dart';
import '../models/customer.dart';
import '../models/vacation.dart';
import '../models/mass_issue.dart';
import '../models/bill.dart';
import '../models/expense.dart';

// Database Instance Provider
final databaseProvider = Provider<DatabaseService>((ref) => DatabaseService.instance);

// App Theme & Locale Providers
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.dark);
final localeProvider = StateProvider<Locale>((ref) => const Locale('gu', 'IN'));

// State revision trigger for reactive refreshes
final dbChangeNotifierProvider = StateProvider<int>((ref) => 0);

// Collections Providers
final firmProvider = Provider<Firm>((ref) {
  ref.watch(dbChangeNotifierProvider);
  return DatabaseService.instance.firm;
});

final itemsProvider = Provider<List<Item>>((ref) {
  ref.watch(dbChangeNotifierProvider);
  return List.unmodifiable(DatabaseService.instance.items);
});

final routesProvider = Provider<List<DeliveryRoute>>((ref) {
  ref.watch(dbChangeNotifierProvider);
  return List.unmodifiable(DatabaseService.instance.routes);
});

final salesmenProvider = Provider<List<Salesman>>((ref) {
  ref.watch(dbChangeNotifierProvider);
  return List.unmodifiable(DatabaseService.instance.salesmen);
});

final customersProvider = Provider<List<Customer>>((ref) {
  ref.watch(dbChangeNotifierProvider);
  return List.unmodifiable(DatabaseService.instance.customers);
});

final vacationsProvider = Provider<List<Vacation>>((ref) {
  ref.watch(dbChangeNotifierProvider);
  return List.unmodifiable(DatabaseService.instance.vacations);
});

final massIssuesProvider = Provider<List<MassIssue>>((ref) {
  ref.watch(dbChangeNotifierProvider);
  return List.unmodifiable(DatabaseService.instance.massIssues);
});

final paperHolidaysProvider = Provider<List<PaperHoliday>>((ref) {
  ref.watch(dbChangeNotifierProvider);
  return List.unmodifiable(DatabaseService.instance.paperHolidays);
});

final billsProvider = Provider<List<Bill>>((ref) {
  ref.watch(dbChangeNotifierProvider);
  return List.unmodifiable(DatabaseService.instance.bills);
});

final paymentsProvider = Provider<List<Payment>>((ref) {
  ref.watch(dbChangeNotifierProvider);
  return List.unmodifiable(DatabaseService.instance.payments);
});

final expensesProvider = Provider<List<Expense>>((ref) {
  ref.watch(dbChangeNotifierProvider);
  return List.unmodifiable(DatabaseService.instance.expenses);
});

void notifyDbChanged(WidgetRef ref) {
  ref.read(dbChangeNotifierProvider.notifier).state++;
}
