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
import '../models/bank_account.dart';
import '../models/collection_man.dart';
import '../models/press_return.dart';

// App Role & Session
enum AppRole {
  admin,
  salesman,
  collection,
}

class AuthSession {
  final AppRole role;
  final Salesman? activeSalesman;
  final CollectionMan? activeCollectionMan;

  const AuthSession({
    this.role = AppRole.admin,
    this.activeSalesman,
    this.activeCollectionMan,
  });

  bool get isAdmin => role == AppRole.admin;
  bool get isSalesman => role == AppRole.salesman;
  bool get isCollection => role == AppRole.collection;

  String get displayName {
    switch (role) {
      case AppRole.admin:
        return 'એડમિન (Admin)';
      case AppRole.salesman:
        return 'વિતરક: ${activeSalesman?.name ?? ""}';
      case AppRole.collection:
        return 'ઉઘરાણી: ${activeCollectionMan?.name ?? ""}';
    }
  }

  String get roleBadgeLabel {
    switch (role) {
      case AppRole.admin:
        return '👑 એડમિન';
      case AppRole.salesman:
        return '🚴‍♂️ ${activeSalesman?.name ?? "વિતરક"}';
      case AppRole.collection:
        return '💼 ${activeCollectionMan?.name ?? "કલેક્શન"}';
    }
  }

  AuthSession copyWith({
    AppRole? role,
    Salesman? activeSalesman,
    CollectionMan? activeCollectionMan,
  }) {
    return AuthSession(
      role: role ?? this.role,
      activeSalesman: activeSalesman ?? this.activeSalesman,
      activeCollectionMan: activeCollectionMan ?? this.activeCollectionMan,
    );
  }
}

class AuthSessionNotifier extends StateNotifier<AuthSession> {
  AuthSessionNotifier() : super(const AuthSession());

  void setAdmin() {
    state = const AuthSession(role: AppRole.admin);
  }

  void setSalesman(Salesman s) {
    state = AuthSession(role: AppRole.salesman, activeSalesman: s);
  }

  void setCollection(CollectionMan c) {
    state = AuthSession(role: AppRole.collection, activeCollectionMan: c);
  }
}

final authSessionProvider = StateNotifierProvider<AuthSessionNotifier, AuthSession>((ref) {
  return AuthSessionNotifier();
});

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

final collectionMenProvider = Provider<List<CollectionMan>>((ref) {
  ref.watch(dbChangeNotifierProvider);
  return List.unmodifiable(DatabaseService.instance.collectionMen);
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

final bankAccountsProvider = Provider<List<BankAccount>>((ref) {
  ref.watch(dbChangeNotifierProvider);
  return List.unmodifiable(DatabaseService.instance.bankAccounts);
});

final bankTransactionsProvider = Provider<List<BankTransaction>>((ref) {
  ref.watch(dbChangeNotifierProvider);
  return List.unmodifiable(DatabaseService.instance.bankTransactions);
});

final pressReturnsProvider = Provider<List<PressReturnEntry>>((ref) {
  ref.watch(dbChangeNotifierProvider);
  return List.unmodifiable(DatabaseService.instance.pressReturns);
});

void notifyDbChanged(WidgetRef ref) {
  ref.read(dbChangeNotifierProvider.notifier).state++;
}
