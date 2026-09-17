import 'dart:convert';
import '../models/firm.dart';
import '../models/item.dart';
import '../models/route.dart';
import '../models/salesman.dart';
import '../models/collection_man.dart';
import '../models/customer.dart';
import '../models/vacation.dart';
import '../models/mass_issue.dart';
import '../models/bill.dart';
import '../models/expense.dart';
import '../models/bank_account.dart';
import '../models/press_return.dart';

class DailyCashbookSummary {
  final String dateStr;
  final double openingCash;
  final double cashCollection;
  final double otherIncome;
  final double totalCashInflow;
  final double cashExpenses;
  final double bankDeposits;
  final double totalCashOutflow;
  final double closingCashInHand;
  final List<Payment> todaysCashPayments;
  final List<Expense> todaysCashExpenses;
  final List<BankTransaction> todaysBankDeposits;

  DailyCashbookSummary({
    required this.dateStr,
    required this.openingCash,
    required this.cashCollection,
    this.otherIncome = 0.0,
    required this.totalCashInflow,
    required this.cashExpenses,
    required this.bankDeposits,
    required this.totalCashOutflow,
    required this.closingCashInHand,
    required this.todaysCashPayments,
    required this.todaysCashExpenses,
    required this.todaysBankDeposits,
  });
}

class MonthlyProfitLossSummary {
  final String monthYear;
  final double grossCustomerBilling;
  final double totalDeliveryCharges;
  final double totalPressPurchaseCost;
  final double totalReturnCredits;
  final double netPressPurchaseCost;
  final double totalSalesmanCommission;
  final double totalOperatingExpenses;
  final double netEstimatedProfit;

  MonthlyProfitLossSummary({
    required this.monthYear,
    required this.grossCustomerBilling,
    required this.totalDeliveryCharges,
    required this.totalPressPurchaseCost,
    required this.totalReturnCredits,
    required this.netPressPurchaseCost,
    required this.totalSalesmanCommission,
    required this.totalOperatingExpenses,
    required this.netEstimatedProfit,
  });
}

class DepotItemDemand {
  final int id;
  final String code;
  final String name;
  final String type;
  final double saleRate;
  final double purchaseRate;
  int customerCopies;
  int extraCopies;
  int totalCopies;
  double purchaseAmount;
  double salesValue;
  double profit;
  bool isHoliday;

  DepotItemDemand({
    required this.id,
    required this.code,
    required this.name,
    this.type = 'daily',
    this.saleRate = 5.0,
    this.purchaseRate = 3.32,
    this.customerCopies = 0,
    this.extraCopies = 0,
    this.totalCopies = 0,
    this.purchaseAmount = 0.0,
    this.salesValue = 0.0,
    this.profit = 0.0,
    this.isHoliday = false,
  });
}

class DepotPurchaseSheet {
  final String date;
  final int dayOfWeek;
  final int totalCustomerCopies;
  final int totalExtraCopies;
  final int totalCopies;
  final double totalPurchaseAmount;
  final double totalSalesValue;
  final double totalProfit;
  final List<DepotItemDemand> items;

  DepotPurchaseSheet({
    required this.date,
    required this.dayOfWeek,
    required this.totalCustomerCopies,
    required this.totalExtraCopies,
    required this.totalCopies,
    required this.totalPurchaseAmount,
    required this.totalSalesValue,
    required this.totalProfit,
    required this.items,
  });
}

class CustomerLedgerEntry {
  final String date;
  final String description;
  final String type; // 'bill', 'payment', 'opening'
  final double debit; // increases balance
  final double credit; // decreases balance
  final double runningBalance;
  final String referenceNo;

  CustomerLedgerEntry({
    required this.date,
    required this.description,
    required this.type,
    required this.debit,
    required this.credit,
    required this.runningBalance,
    required this.referenceNo,
  });
}

class DatabaseService {
  static final DatabaseService instance = DatabaseService._internal();
  DatabaseService._internal();

  Firm firm = Firm();
  final List<Item> items = [];
  final List<DeliveryRoute> routes = [];
  final List<Salesman> salesmen = [];
  final List<CollectionMan> collectionMen = [];
  final List<Customer> customers = [];
  final List<Vacation> vacations = [];
  final List<PaperHoliday> paperHolidays = [];
  final List<MassIssue> massIssues = [];
  final List<Bill> bills = [];
  final List<Payment> payments = [];
  final List<Expense> expenses = [];
  final List<BankAccount> bankAccounts = [];
  final List<BankTransaction> bankTransactions = [];
  final List<PressReturnEntry> pressReturns = [];
  final Map<String, String> deliveryLogs = {}; // date_customerId -> 'delivered' | 'undelivered' | 'hold'

  // SaaS Multi-Tenant & Licensing Properties
  String agencyId = 'VS-AGY-BEBF';
  String storageMode = 'offline'; // 'offline' | 'cloud'
  String cloudUrl = '';
  String cloudKey = '';
  String licenseKey = 'VS-261031-BEBF-1A2B';
  String licensePlan = '1 Year SaaS (₹4,999)';
  String licenseValidUntil = '2026-10-31';
  String licenseStatus = 'active';
  String? lastCloudSync;

  bool isInitialized = false;

  Future<void> init() async {
    if (isInitialized) return;
    _seedDefaultData();
    isInitialized = true;
  }

  void resetToSampleData() {
    items.clear();
    routes.clear();
    salesmen.clear();
    collectionMen.clear();
    customers.clear();
    vacations.clear();
    paperHolidays.clear();
    massIssues.clear();
    bills.clear();
    payments.clear();
    expenses.clear();
    bankAccounts.clear();
    bankTransactions.clear();
    pressReturns.clear();
    deliveryLogs.clear();
    _seedDefaultData();
  }

  void _seedDefaultData() {
    firm = Firm(
      name: 'Vendor Pro - ન્યૂઝપેપર એજન્સી',
      ownerName: 'ઇમરાન ખાનુશિયા',
      phone: '9876543210',
      address: 'સ્ટેશન રોડ, પાલનપુર, ગુજરાત',
      upiId: 'vendorpro@upi',
      billNotes: 'મહેરબાની કરીને ૧૦ તારીખ પહેલા બિલ ભરી દેવું. આભાર!',
    );

    routes.addAll([
      DeliveryRoute(id: 1, code: 'R1', name: 'મેઇન બજાર લાઇન', salesmanId: 1, collectionManId: 1),
      DeliveryRoute(id: 2, code: 'R2', name: 'સ્ટેશન રોડ લાઇન', salesmanId: 2, collectionManId: 2),
      DeliveryRoute(id: 3, code: 'R3', name: 'સોસાયટી લાઇન', salesmanId: 1, collectionManId: 1),
    ]);

    salesmen.addAll([
      Salesman(id: 1, name: 'રમેશભાઈ પરમાર (વિતરક)', mobile: '9898012345'),
      Salesman(id: 2, name: 'દિનેશભાઈ સોલંકી (વિતરક)', mobile: '9898067890'),
    ]);

    collectionMen.addAll([
      CollectionMan(id: 1, name: 'પરેશભાઈ શાહ (ઉઘરાણીદાર)', mobile: '9825012345'),
      CollectionMan(id: 2, name: 'સંજયભાઈ પટેલ (ઉઘરાણીદાર)', mobile: '9825067890'),
    ]);

    items.addAll([
      Item(
        id: 1, 
        code: 'GS', 
        name: 'GUJARAT SAMACHAR', 
        defaultRate: 5.0, 
        sundayRate: 6.0,
        defaultPurchaseRate: 3.32,
        sundayPurchaseRate: 3.99,
        rateHistory: [
          RateRevision(
            effectiveDate: '2026-09-19',
            dayRates: {
              'mon': const DayRate(sale: 6.0, purchase: 4.35),
              'tue': const DayRate(sale: 6.0, purchase: 4.35),
              'wed': const DayRate(sale: 6.0, purchase: 4.35),
              'thu': const DayRate(sale: 6.0, purchase: 4.35),
              'fri': const DayRate(sale: 6.0, purchase: 4.35),
              'sat': const DayRate(sale: 6.0, purchase: 4.35),
              'sun': const DayRate(sale: 6.0, purchase: 3.99),
            },
            defaultRate: 6.0,
            sundayRate: 6.0,
            monthlyRate: 0.0,
          ),
        ],
      ),
      Item(
        id: 2, 
        code: 'DB', 
        name: 'DIVYA BHASKAR', 
        defaultRate: 5.0, 
        sundayRate: 6.0,
        defaultPurchaseRate: 3.32,
        sundayPurchaseRate: 3.98,
      ),
      Item(
        id: 3, 
        code: 'SANJ', 
        name: 'SANJ SAMACHAR', 
        defaultRate: 3.0, 
        sundayRate: 3.0,
        defaultPurchaseRate: 2.0,
        sundayPurchaseRate: 2.0,
      ),
      Item(
        id: 4, 
        code: 'SANDESH', 
        name: 'SANDESH', 
        defaultRate: 5.0, 
        sundayRate: 6.0,
        defaultPurchaseRate: 3.32,
        sundayPurchaseRate: 3.99,
      ),
    ]);

    customers.addAll([
      Customer(
        id: 1,
        custNo: '101',
        name: 'પટેલ રમેશભાઈ કેશવલાલ',
        phone: '9825011223',
        routeId: 1,
        sequenceNo: '1',
        buildingAddress: '૧૨, શાંતિનિકેતન સોસાયટી, બજાર રોડ',
        subscriptions: [1, 2],
        billingType: 'daily',
        deliveryCharge: 10.0,
        openingBalance: 0.0,
        currentBalance: 320.0,
      ),
      Customer(
        id: 2,
        custNo: '102',
        name: 'શાહ મુકેશકુમાર શાંતિલાલ',
        phone: '9898122334',
        routeId: 1,
        sequenceNo: '2',
        buildingAddress: '૪૫, મહાવીર નગર, સ્ટેશન રોડ',
        subscriptions: [1],
        billingType: 'daily',
        deliveryCharge: 10.0,
        openingBalance: 0.0,
        currentBalance: 165.0,
      ),
      Customer(
        id: 3,
        custNo: '103',
        name: 'દેસાઈ મહેશભાઈ પ્રભુદાસ',
        phone: '9426033445',
        routeId: 2,
        sequenceNo: '1',
        buildingAddress: 'બી-૫, દર્શન એપાર્ટમેન્ટ',
        subscriptions: [2, 4],
        billingType: 'daily',
        deliveryCharge: 10.0,
        openingBalance: 0.0,
        currentBalance: 320.0,
      ),
    ]);

    bankAccounts.addAll([
      BankAccount(
        id: 'acc_1',
        bankName: 'State Bank of India (SBI)',
        accountNumber: 'XXXXXX5678',
        ifsc: 'SBIN0001234',
        holderName: 'Vendor Pro Agency',
        initialBalance: 25000.0,
        currentBalance: 28500.0,
        accountType: 'current',
      ),
      BankAccount(
        id: 'acc_2',
        bankName: 'HDFC Bank',
        accountNumber: 'XXXXXX9012',
        ifsc: 'HDFC0004321',
        holderName: 'Vendor Pro Agency',
        initialBalance: 15000.0,
        currentBalance: 15000.0,
        accountType: 'savings',
      ),
      BankAccount(
        id: 'acc_cash',
        bankName: 'રોકડ કેશ કાઉન્ટર (Cash Drawer)',
        accountNumber: 'CASH-DRAWER',
        holderName: 'Daily Cash',
        initialBalance: 5000.0,
        currentBalance: 8200.0,
        accountType: 'cash_drawer',
      ),
    ]);

    expenses.addAll([
      Expense(
        id: 1,
        date: DateTime.now().toIso8601String().split('T')[0],
        category: 'petrol',
        amount: 350.0,
        paidTo: 'રમેશભાઈ (લાઇન બોય)',
        paymentMode: 'cash',
        remarks: 'રોજિંદો પેટ્રોલ ખર્ચ',
      ),
      Expense(
        id: 2,
        date: DateTime.now().toIso8601String().split('T')[0],
        category: 'tea_snacks',
        amount: 80.0,
        paidTo: 'જય અંબે ટી સ્ટોલ',
        paymentMode: 'cash',
        remarks: 'સ્ટાફ ચા-નાસ્તો',
      ),
    ]);

    pressReturns.addAll([
      PressReturnEntry(
        id: 1,
        date: DateTime.now().toIso8601String().split('T')[0],
        itemId: 1,
        itemName: 'ગુજરાત સમાચાર',
        copies: 12,
        creditRate: 3.32,
        creditAmount: 39.84,
        notes: 'વધારાની નકલો પ્રેસમાં જમા',
      ),
      PressReturnEntry(
        id: 2,
        date: DateTime.now().toIso8601String().split('T')[0],
        itemId: 2,
        itemName: 'દિવ્ય ભાસ્કર',
        copies: 8,
        creditRate: 3.32,
        creditAmount: 26.56,
        notes: 'અનસોલ્ડ કોપી જમા',
      ),
    ]);
  }

  // --- Delivery Tracking Helpers ---
  String getDeliveryStatus(String date, int customerId) {
    return deliveryLogs['${date}_$customerId'] ?? 'delivered';
  }

  void setDeliveryStatus(String date, int customerId, String status) {
    deliveryLogs['${date}_$customerId'] = status;
  }

  int getDeliveryCountForDate(String date) {
    int count = 0;
    for (final c in customers) {
      if (c.status == 'active' && getDeliveryStatus(date, c.id) == 'delivered') {
        count++;
      }
    }
    return count;
  }

  // --- Banking Helpers ---
  void addBankAccount(BankAccount account) {
    bankAccounts.add(account);
  }

  void updateBankAccount(BankAccount account) {
    final idx = bankAccounts.indexWhere((a) => a.id == account.id);
    if (idx >= 0) {
      bankAccounts[idx] = account;
    }
  }

  void deleteBankAccount(String id) {
    bankAccounts.removeWhere((a) => a.id == id);
    bankTransactions.removeWhere((t) => t.bankAccountId == id);
  }

  void addBankTransaction(BankTransaction tx) {
    bankTransactions.add(tx);
    final accIdx = bankAccounts.indexWhere((a) => a.id == tx.bankAccountId);
    if (accIdx >= 0) {
      final acc = bankAccounts[accIdx];
      double newBal = acc.currentBalance;
      if (tx.type == 'deposit') {
        newBal += tx.amount;
      } else if (tx.type == 'withdrawal') {
        newBal -= tx.amount;
      }
      bankAccounts[accIdx] = acc.copyWith(currentBalance: newBal);
    }
  }

  void deleteBankTransaction(String id) {
    final txIdx = bankTransactions.indexWhere((t) => t.id == id);
    if (txIdx >= 0) {
      final tx = bankTransactions[txIdx];
      final accIdx = bankAccounts.indexWhere((a) => a.id == tx.bankAccountId);
      if (accIdx >= 0) {
        final acc = bankAccounts[accIdx];
        double newBal = acc.currentBalance;
        if (tx.type == 'deposit') {
          newBal -= tx.amount;
        } else if (tx.type == 'withdrawal') {
          newBal += tx.amount;
        }
        bankAccounts[accIdx] = acc.copyWith(currentBalance: newBal);
      }
      bankTransactions.removeAt(txIdx);
    }
  }

  // 1. Depot Purchase Sheet Engine
  DepotPurchaseSheet getDepotPurchaseSheet(String dateStr, [Map<int, int> customExtra = const {}]) {
    final targetDate = DateTime.tryParse('${dateStr}T12:00:00') ?? DateTime.now().add(const Duration(days: 1));
    final dayOfWeek = targetDate.weekday % 7; // 0 = Sun, 1 = Mon ...

    final todaysMassIssues = massIssues.where((m) => m.date == dateStr).toList();
    final hasHolidayForOthers = todaysMassIssues.any((m) => m.holidayForOthers);
    final massIssueItemIds = todaysMassIssues.map((m) => m.itemId).toSet();

    final itemDemandMap = <int, DepotItemDemand>{};

    for (final it in items) {
      bool isHoliday = paperHolidays.any((h) => h.isActiveOn(it.id, dateStr));
      if (hasHolidayForOthers && !massIssueItemIds.contains(it.id)) {
        isHoliday = true;
      }

      final rates = it.getRateForDay(dayOfWeek, dateStr);
      final matchingMi = todaysMassIssues.cast<MassIssue?>().firstWhere((m) => m?.itemId == it.id, orElse: () => null);

      final saleRate = (matchingMi != null && matchingMi.rate >= 0) ? matchingMi.rate : rates.sale;
      final purchaseRate = (matchingMi != null && matchingMi.purchaseRate >= 0) ? matchingMi.purchaseRate : rates.purchase;
      final extra = customExtra[it.id] ?? 0;

      itemDemandMap[it.id] = DepotItemDemand(
        id: it.id,
        code: it.code,
        name: it.name,
        type: it.type,
        saleRate: saleRate,
        purchaseRate: purchaseRate,
        extraCopies: extra,
        isHoliday: isHoliday,
      );
    }

    for (final cust in customers) {
      if (cust.status != 'active') {
        if (cust.inactiveDate != null && dateStr.compareTo(cust.inactiveDate!) > 0) continue;
      }
      final onVacation = vacations.any((v) => v.customerId == cust.id && v.isActiveOn(dateStr));
      if (onVacation) continue;

      final customerItemsForDay = <int>{};
      final hasPaperOnDay = cust.hasAnyPaperOnDay(dayOfWeek, dateStr);

      for (final itemId in cust.subscriptionItemIds) {
        if (cust.isSubscribedOnDay(itemId, dayOfWeek, dateStr)) {
          if (!hasHolidayForOthers) {
            final demand = itemDemandMap[itemId];
            if (demand != null && !demand.isHoliday) {
              demand.customerCopies += 1;
              customerItemsForDay.add(itemId);
            }
          }
        }
      }

      // Inject mass issues
      for (final mi in todaysMassIssues) {
        final isEligible = (mi.targetType == 'day_wise') ? hasPaperOnDay : true;
        if (isEligible && !customerItemsForDay.contains(mi.itemId)) {
          final demand = itemDemandMap[mi.itemId];
          if (demand != null) {
            demand.customerCopies += 1;
            customerItemsForDay.add(mi.itemId);
          }
        }
      }
    }

    final rows = itemDemandMap.values.map((r) {
      r.totalCopies = r.customerCopies + r.extraCopies;
      r.purchaseAmount = double.parse((r.totalCopies * r.purchaseRate).toStringAsFixed(2));
      r.salesValue = double.parse((r.totalCopies * r.saleRate).toStringAsFixed(2));
      r.profit = double.parse((r.salesValue - r.purchaseAmount).toStringAsFixed(2));
      return r;
    }).toList();

    return DepotPurchaseSheet(
      date: dateStr,
      dayOfWeek: dayOfWeek,
      totalCustomerCopies: rows.fold(0, (sum, r) => sum + r.customerCopies),
      totalExtraCopies: rows.fold(0, (sum, r) => sum + r.extraCopies),
      totalCopies: rows.fold(0, (sum, r) => sum + r.totalCopies),
      totalPurchaseAmount: rows.fold(0.0, (sum, r) => sum + r.purchaseAmount),
      totalSalesValue: rows.fold(0.0, (sum, r) => sum + r.salesValue),
      totalProfit: rows.fold(0.0, (sum, r) => sum + r.profit),
      items: rows,
    );
  }

  // 2. Monthly Billing Engine
  List<Bill> calculateMonthlyBills(int year, int month, {
    String format = 'sequential',
    String prefix = '',
    int startNum = 1001,
    int padding = 0,
    String sortBy = 'salesman_delivery',
  }) {
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final monthKey = '$year-${month.toString().padLeft(2, '0')}';

    // Remove existing bills for this monthKey
    bills.removeWhere((b) => b.monthYear == monthKey);

    final itemMap = {for (var i in items) i.id: i};
    final routeMap = {for (var r in routes) r.id: r};
    final salesmanMap = {for (var s in salesmen) s.id: s};
    final collectionManMap = {for (var cm in collectionMen) cm.id: cm};

    final sortedCustomers = List<Customer>.from(customers);
    sortedCustomers.sort((a, b) {
      final rA = routeMap[a.routeId];
      final rB = routeMap[b.routeId];

      if (sortBy == 'salesman_delivery') {
        // 1. સેલ્સમેન + ડિલિવરી ક્રમ (Salesman/Collection Man + Delivery Sequence)
        final smA = collectionManMap[rA?.collectionManId]?.name ?? salesmanMap[rA?.salesmanId]?.name ?? '';
        final smB = collectionManMap[rB?.collectionManId]?.name ?? salesmanMap[rB?.salesmanId]?.name ?? '';
        if (smA != smB) return smA.compareTo(smB);
        final seqA = int.tryParse(a.sequenceNo) ?? 999999;
        final seqB = int.tryParse(b.sequenceNo) ?? 999999;
        return seqA.compareTo(seqB);
      } else if (sortBy == 'delivery_salesman') {
        // 2. ડિલિવરી મેન + સેલ્સમેન ક્રમ (Delivery Man + Salesman/Collection Sequence)
        final dmA = salesmanMap[rA?.salesmanId]?.name ?? '';
        final dmB = salesmanMap[rB?.salesmanId]?.name ?? '';
        if (dmA != dmB) return dmA.compareTo(dmB);
        final colSeqA = int.tryParse(a.collectionSequence.isNotEmpty ? a.collectionSequence : a.sequenceNo) ?? 999999;
        final colSeqB = int.tryParse(b.collectionSequence.isNotEmpty ? b.collectionSequence : b.sequenceNo) ?? 999999;
        return colSeqA.compareTo(colSeqB);
      } else if (sortBy == 'route_salesman') {
        // 3. લાઇન + સેલ્સમેન ક્રમ (Route/Line + Salesman/Collection Sequence)
        final rCodeA = rA?.code ?? '';
        final rCodeB = rB?.code ?? '';
        if (rCodeA != rCodeB) return rCodeA.compareTo(rCodeB);
        final colSeqA = int.tryParse(a.collectionSequence.isNotEmpty ? a.collectionSequence : a.sequenceNo) ?? 999999;
        final colSeqB = int.tryParse(b.collectionSequence.isNotEmpty ? b.collectionSequence : b.sequenceNo) ?? 999999;
        return colSeqA.compareTo(colSeqB);
      } else if (sortBy == 'route_delivery') {
        // 4. લાઇન + ડિલિવરી ક્રમ (Route/Line + Delivery Sequence)
        final rCodeA = rA?.code ?? '';
        final rCodeB = rB?.code ?? '';
        if (rCodeA != rCodeB) return rCodeA.compareTo(rCodeB);
        final seqA = int.tryParse(a.sequenceNo) ?? 999999;
        final seqB = int.tryParse(b.sequenceNo) ?? 999999;
        return seqA.compareTo(seqB);
      } else {
        final seqA = int.tryParse(a.sequenceNo) ?? 999999;
        final seqB = int.tryParse(b.sequenceNo) ?? 999999;
        return seqA.compareTo(seqB);
      }
    });

    int billIndex = 0;
    final generatedBills = <Bill>[];

    for (final cust in sortedCustomers) {
      if (cust.status != 'active') {
        if (cust.inactiveDate == null || cust.inactiveDate!.compareTo('$monthKey-01') < 0) {
          continue;
        }
      }

      double billTotal = 0.0;
      double vacationDeductionTotal = 0.0;
      int vacationDaysCount = 0;
      int deliveryDaysCount = 0;
      final paperBreakdown = <String, PaperBreakdownItem>{};

      if (cust.billingType == 'fixed' && cust.fixedMonthlyAmount > 0) {
        billTotal = cust.fixedMonthlyAmount;
        deliveryDaysCount = daysInMonth;
        paperBreakdown['fixed'] = PaperBreakdownItem(
          id: 0,
          name: 'માસિક ફિક્સ કોન્ટ્રાક્ટ (Fixed)',
          code: 'FIXED',
          daysCount: daysInMonth,
          totalCost: billTotal,
          startDate: '$monthKey-01',
          endDate: '$monthKey-${daysInMonth.toString().padLeft(2, '0')}',
        );
      } else {
        // Daily calculation
        for (int day = 1; day <= daysInMonth; day++) {
          final currentDate = DateTime(year, month, day, 12, 0, 0);
          final dateStr = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
          final dayOfWeek = currentDate.weekday % 7; // 0=Sun, 1=Mon...

          if (cust.status == 'inactive' && cust.inactiveDate != null && dateStr.compareTo(cust.inactiveDate!) > 0) {
            continue;
          }

          final isOnVacation = vacations.any((v) => v.customerId == cust.id && v.isActiveOn(dateStr));
          double dayCost = 0.0;
          final dayItems = <Map<String, dynamic>>[];
          final todaysMassIssues = massIssues.where((m) => m.date == dateStr).toList();
          final hasHolidayForOthers = todaysMassIssues.any((m) => m.holidayForOthers);
          final hasPaperOnDay = cust.hasAnyPaperOnDay(dayOfWeek, dateStr);

          for (final itemId in cust.subscriptionItemIds) {
            if (cust.isSubscribedOnDay(itemId, dayOfWeek, dateStr)) {
              if (!hasHolidayForOthers) {
                final item = itemMap[itemId];
                if (item == null || item.status == 'inactive') continue;

                final isPaperHoliday = paperHolidays.any((h) => h.isActiveOn(item.id, dateStr));
                if (isPaperHoliday) continue;

                final rates = item.getRateForDay(dayOfWeek, dateStr);
                dayCost += rates.sale;
                dayItems.add({'id': item.id, 'name': item.name, 'code': item.code, 'rate': rates.sale});
              }
            }
          }

          for (final mi in todaysMassIssues) {
            final isEligible = (mi.targetType == 'day_wise') ? hasPaperOnDay : true;
            if (isEligible) {
              final mRate = mi.rate;
              dayCost += mRate;
              final mItem = itemMap[mi.itemId];
              dayItems.add({
                'id': mi.itemId,
                'name': '${mItem?.name ?? "વિશેષ આવૃત્તિ"} (Bonus)',
                'code': mItem?.code ?? 'MI',
                'rate': mRate,
              });
            }
          }

          if (isOnVacation) {
            vacationDaysCount++;
            vacationDeductionTotal += dayCost;
          } else {
            if (dayCost > 0 || dayItems.isNotEmpty) {
              deliveryDaysCount++;
            }
            billTotal += dayCost;

            for (final it in dayItems) {
              final idKey = it['id'].toString();
              if (!paperBreakdown.containsKey(idKey)) {
                paperBreakdown[idKey] = PaperBreakdownItem(
                  id: it['id'] as int,
                  name: it['name'] as String,
                  code: it['code'] as String,
                  daysCount: 0,
                  totalCost: 0.0,
                  startDate: dateStr,
                  endDate: dateStr,
                );
              }
              final existing = paperBreakdown[idKey]!;
              paperBreakdown[idKey] = PaperBreakdownItem(
                id: existing.id,
                name: existing.name,
                code: existing.code,
                daysCount: existing.daysCount + 1,
                totalCost: double.parse((existing.totalCost + (it['rate'] as num)).toStringAsFixed(2)),
                startDate: existing.startDate,
                endDate: dateStr,
              );
            }
          }
        }
      }

      final newspaperAmount = double.parse(billTotal.toStringAsFixed(2));
      final delCharge = cust.deliveryCharge;
      final pastArrears = cust.currentBalance;
      final netPayable = (newspaperAmount + delCharge + pastArrears).roundToDouble();

      // Bill Number formatting
      billIndex++;
      final currentVal = startNum + (billIndex - 1);
      final numFormatted = padding > 0 ? currentVal.toString().padLeft(padding, '0') : currentVal.toString();
      
      String assignedBillNo = '';
      if (format == 'sequential') {
        assignedBillNo = '$prefix$numFormatted';
      } else if (format == 'month_seq') {
        const mShort = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
        final mStr = mShort[(month - 1).clamp(0, 11)];
        final yStr = year.toString().substring(2);
        assignedBillNo = prefix.isNotEmpty ? '$prefix$numFormatted' : '$mStr$yStr-$numFormatted';
      } else {
        assignedBillNo = '$prefix$numFormatted';
      }

      final bill = Bill(
        id: DateTime.now().millisecondsSinceEpoch + billIndex,
        customerId: cust.id,
        customerNo: cust.custNo.isNotEmpty ? cust.custNo : cust.id.toString(),
        customerName: cust.name,
        routeId: cust.routeId,
        monthYear: monthKey,
        billNo: assignedBillNo,
        deliveryDays: deliveryDaysCount,
        vacationDays: vacationDaysCount,
        vacationDeduction: vacationDeductionTotal,
        newspaperAmount: newspaperAmount,
        deliveryCharge: delCharge,
        currentAmount: double.parse((newspaperAmount + delCharge).toStringAsFixed(2)),
        pastBalance: pastArrears,
        finalPayable: netPayable,
        paymentReceived: 0.0,
        paperBreakdown: paperBreakdown,
        status: 'pending',
      );

      generatedBills.add(bill);
      bills.add(bill);

      // Update customer balance to the new bill amount
      cust.currentBalance = netPayable;
    }

    return generatedBills;
  }

  // 3. Payment Processing
  void recordPayment(Payment payment) {
    payments.add(payment);

    // Find customer
    final cust = customers.cast<Customer?>().firstWhere((c) => c?.id == payment.customerId, orElse: () => null);
    if (cust != null) {
      cust.currentBalance = (cust.currentBalance - payment.amount).clamp(0.0, double.infinity);
    }

    // Allocate payment against customer's bills
    double remainingAmount = payment.amount;
    final custBills = bills.where((b) => b.customerId == payment.customerId && b.balanceDue > 0).toList();
    custBills.sort((a, b) => a.monthYear.compareTo(b.monthYear));

    for (final bill in custBills) {
      if (remainingAmount <= 0) break;
      final due = bill.balanceDue;
      if (remainingAmount >= due) {
        bill.paymentReceived += due;
        bill.status = 'paid';
        remainingAmount -= due;
      } else {
        bill.paymentReceived += remainingAmount;
        bill.status = 'partial';
        remainingAmount = 0;
      }
    }
  }

  // 4. Customer Ledger History
  List<CustomerLedgerEntry> getCustomerLedger(int customerId) {
    final cust = customers.cast<Customer?>().firstWhere((c) => c?.id == customerId, orElse: () => null);
    if (cust == null) return [];

    final entries = <CustomerLedgerEntry>[];
    double balance = cust.openingBalance;

    if (balance > 0) {
      entries.add(CustomerLedgerEntry(
        date: '2026-01-01',
        description: 'શરૂઆતની બાકી રકમ (Opening Balance)',
        type: 'opening',
        debit: balance,
        credit: 0.0,
        runningBalance: balance,
        referenceNo: '-',
      ));
    }

    final custBills = bills.where((b) => b.customerId == customerId).toList();
    final custPayments = payments.where((p) => p.customerId == customerId).toList();

    final allEvents = <Map<String, dynamic>>[];
    for (final b in custBills) {
      allEvents.add({
        'date': '${b.monthYear}-28',
        'type': 'bill',
        'ref': b.billNo,
        'desc': 'માસિક બિલ (${b.monthYear})',
        'amount': b.currentAmount,
      });
    }
    for (final p in custPayments) {
      allEvents.add({
        'date': p.date,
        'type': 'payment',
        'ref': p.receiptNo.isNotEmpty ? p.receiptNo : 'REC-${p.id}',
        'desc': 'ચૂકવણી મળેલ (${p.paymentMode.toUpperCase()}) ${p.notes.isNotEmpty ? "- ${p.notes}" : ""}',
        'amount': p.amount,
      });
    }

    allEvents.sort((a, b) => (a['date'] as String).compareTo(b['date'] as String));

    for (final ev in allEvents) {
      if (ev['type'] == 'bill') {
        final amt = ev['amount'] as double;
        balance += amt;
        entries.add(CustomerLedgerEntry(
          date: ev['date'] as String,
          description: ev['desc'] as String,
          type: 'bill',
          debit: amt,
          credit: 0.0,
          runningBalance: balance,
          referenceNo: ev['ref'] as String,
        ));
      } else {
        final amt = ev['amount'] as double;
        balance = (balance - amt).clamp(0.0, double.infinity);
        entries.add(CustomerLedgerEntry(
          date: ev['date'] as String,
          description: ev['desc'] as String,
          type: 'payment',
          debit: 0.0,
          credit: amt,
          runningBalance: balance,
          referenceNo: ev['ref'] as String,
        ));
      }
    }

    return entries;
  }

  // 5. Customer Sequencing & Route Ordering
  void insertCustomerAtSequence(Customer newCustomer, int? targetSeq, int routeId, {bool syncCollectionSeq = true}) {
    final routeCusts = customers.where((c) => c.routeId == routeId && c.id != newCustomer.id).toList();

    if (targetSeq != null && targetSeq > 0) {
      final toShift = routeCusts.where((c) => (int.tryParse(c.sequenceNo) ?? 0) >= targetSeq).toList()
        ..sort((a, b) => (int.tryParse(b.sequenceNo) ?? 0).compareTo(int.tryParse(a.sequenceNo) ?? 0));

      for (final c in toShift) {
        final curSeq = int.tryParse(c.sequenceNo) ?? 0;
        final idx = customers.indexWhere((item) => item.id == c.id);
        if (idx != -1) {
          final updated = Customer(
            id: c.id,
            custNo: c.custNo,
            code: c.code,
            name: c.name,
            routeId: c.routeId,
            salesmanId: c.salesmanId,
            collectionManId: c.collectionManId,
            sequenceNo: '${curSeq + 1}',
            collectionSequence: syncCollectionSeq ? '${curSeq + 1}' : c.collectionSequence,
            mobile: c.mobile,
            whatsapp: c.whatsapp,
            address: c.address,
            societyShort: c.societyShort,
            subscriptions: c.subscriptions,
            billingType: c.billingType,
            fixedMonthlyAmount: c.fixedMonthlyAmount,
            openingBalance: c.openingBalance,
            currentBalance: c.currentBalance,
            status: c.status,
            inactiveDate: c.inactiveDate,
            delChargeEnabled: c.delChargeEnabled,
            delChargeAmt: c.delChargeAmt,
            createdAt: c.createdAt,
          );
          customers[idx] = updated;
        }
      }

      final custToInsert = Customer(
        id: newCustomer.id,
        custNo: newCustomer.custNo,
        code: newCustomer.code,
        name: newCustomer.name,
        routeId: newCustomer.routeId,
        salesmanId: newCustomer.salesmanId,
        collectionManId: newCustomer.collectionManId,
        sequenceNo: '$targetSeq',
        collectionSequence: syncCollectionSeq ? '$targetSeq' : newCustomer.collectionSequence,
        mobile: newCustomer.mobile,
        whatsapp: newCustomer.whatsapp,
        address: newCustomer.address,
        societyShort: newCustomer.societyShort,
        subscriptions: newCustomer.subscriptions,
        billingType: newCustomer.billingType,
        fixedMonthlyAmount: newCustomer.fixedMonthlyAmount,
        openingBalance: newCustomer.openingBalance,
        currentBalance: newCustomer.currentBalance,
        status: newCustomer.status,
        inactiveDate: newCustomer.inactiveDate,
        delChargeEnabled: newCustomer.delChargeEnabled,
        delChargeAmt: newCustomer.delChargeAmt,
        createdAt: newCustomer.createdAt ?? DateTime.now().toIso8601String(),
      );
      final existingIdx = customers.indexWhere((c) => c.id == newCustomer.id);
      if (existingIdx != -1) {
        customers[existingIdx] = custToInsert;
      } else {
        customers.add(custToInsert);
      }
    } else {
      final maxSeq = routeCusts.fold<int>(0, (max, c) {
        final s = int.tryParse(c.sequenceNo) ?? 0;
        return s > max ? s : max;
      });
      final nextSeq = maxSeq + 1;
      final custToInsert = Customer(
        id: newCustomer.id,
        custNo: newCustomer.custNo,
        code: newCustomer.code,
        name: newCustomer.name,
        routeId: newCustomer.routeId,
        salesmanId: newCustomer.salesmanId,
        collectionManId: newCustomer.collectionManId,
        sequenceNo: '$nextSeq',
        collectionSequence: syncCollectionSeq ? '$nextSeq' : newCustomer.collectionSequence,
        mobile: newCustomer.mobile,
        whatsapp: newCustomer.whatsapp,
        address: newCustomer.address,
        societyShort: newCustomer.societyShort,
        subscriptions: newCustomer.subscriptions,
        billingType: newCustomer.billingType,
        fixedMonthlyAmount: newCustomer.fixedMonthlyAmount,
        openingBalance: newCustomer.openingBalance,
        currentBalance: newCustomer.currentBalance,
        status: newCustomer.status,
        inactiveDate: newCustomer.inactiveDate,
        delChargeEnabled: newCustomer.delChargeEnabled,
        delChargeAmt: newCustomer.delChargeAmt,
        createdAt: newCustomer.createdAt ?? DateTime.now().toIso8601String(),
      );
      final existingIdx = customers.indexWhere((c) => c.id == newCustomer.id);
      if (existingIdx != -1) {
        customers[existingIdx] = custToInsert;
      } else {
        customers.add(custToInsert);
      }
    }
  }

  void updateRouteSequence(int routeId, List<int> orderedCustomerIds, {bool syncCollectionSeq = true}) {
    for (int i = 0; i < orderedCustomerIds.length; i++) {
      final custId = orderedCustomerIds[i];
      final idx = customers.indexWhere((c) => c.id == custId);
      if (idx != -1) {
        final c = customers[idx];
        final updated = Customer(
          id: c.id,
          custNo: c.custNo,
          code: c.code,
          name: c.name,
          routeId: c.routeId,
          salesmanId: c.salesmanId,
          collectionManId: c.collectionManId,
          sequenceNo: '${i + 1}',
          collectionSequence: syncCollectionSeq ? '${i + 1}' : c.collectionSequence,
          mobile: c.mobile,
          whatsapp: c.whatsapp,
          address: c.address,
          societyShort: c.societyShort,
          subscriptions: c.subscriptions,
          billingType: c.billingType,
          fixedMonthlyAmount: c.fixedMonthlyAmount,
          openingBalance: c.openingBalance,
          currentBalance: c.currentBalance,
          status: c.status,
          inactiveDate: c.inactiveDate,
          delChargeEnabled: c.delChargeEnabled,
          delChargeAmt: c.delChargeAmt,
          createdAt: c.createdAt,
        );
        customers[idx] = updated;
      }
    }
  }

  void updateCollectionSequence(int routeId, List<int> orderedCustomerIds, {bool syncDeliverySeq = true}) {
    for (int i = 0; i < orderedCustomerIds.length; i++) {
      final custId = orderedCustomerIds[i];
      final idx = customers.indexWhere((c) => c.id == custId);
      if (idx != -1) {
        final c = customers[idx];
        final updated = Customer(
          id: c.id,
          custNo: c.custNo,
          code: c.code,
          name: c.name,
          routeId: c.routeId,
          salesmanId: c.salesmanId,
          collectionManId: c.collectionManId,
          sequenceNo: syncDeliverySeq ? '${i + 1}' : c.sequenceNo,
          collectionSequence: '${i + 1}',
          mobile: c.mobile,
          whatsapp: c.whatsapp,
          address: c.address,
          societyShort: c.societyShort,
          subscriptions: c.subscriptions,
          billingType: c.billingType,
          fixedMonthlyAmount: c.fixedMonthlyAmount,
          openingBalance: c.openingBalance,
          currentBalance: c.currentBalance,
          status: c.status,
          inactiveDate: c.inactiveDate,
          delChargeEnabled: c.delChargeEnabled,
          delChargeAmt: c.delChargeAmt,
          createdAt: c.createdAt,
        );
        customers[idx] = updated;
      }
    }
  }

  void switchCustomerPaper({
    required int customerId,
    required String effectiveDate,
    int? oldPaperId,
    int? newPaperId,
    List<String>? newDays,
  }) {
    final idx = customers.indexWhere((c) => c.id == customerId);
    if (idx == -1) return;
    final cust = customers[idx];

    DateTime eff;
    try {
      eff = DateTime.parse(effectiveDate);
    } catch (_) {
      eff = DateTime.now();
    }
    final prevDay = eff.subtract(const Duration(days: 1));
    final prevDayStr = '${prevDay.year.toString().padLeft(4, '0')}-${prevDay.month.toString().padLeft(2, '0')}-${prevDay.day.toString().padLeft(2, '0')}';

    final Map<String, dynamic> updatedSubs = {};

    if (cust.subscriptions is Map) {
      (cust.subscriptions as Map).forEach((k, v) {
        updatedSubs[k.toString()] = v;
      });
    } else if (cust.subscriptions is List) {
      for (final itm in (cust.subscriptions as List)) {
        updatedSubs[itm.toString()] = {
          'days': ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'],
        };
      }
    }

    // 1. End old paper on prevDay
    if (oldPaperId != null) {
      final oldKey = oldPaperId.toString();
      final existing = updatedSubs[oldKey];
      List<String> existingDays = ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'];
      String? oldStart;
      if (existing is List) {
        existingDays = existing.map((e) => e.toString()).toList();
      } else if (existing is Map) {
        if (existing['days'] is List) {
          existingDays = (existing['days'] as List).map((e) => e.toString()).toList();
        }
        oldStart = existing['startDate']?.toString();
      }

      updatedSubs[oldKey] = {
        'days': existingDays,
        'startDate': oldStart,
        'endDate': prevDayStr,
      };
    }

    // 2. Start new paper on effectiveDate
    if (newPaperId != null) {
      final newKey = newPaperId.toString();
      updatedSubs[newKey] = {
        'days': newDays ?? ['sun', 'mon', 'tue', 'wed', 'thu', 'fri', 'sat'],
        'startDate': effectiveDate,
        'endDate': null,
      };
    }

    final updated = Customer(
      id: cust.id,
      custNo: cust.custNo,
      code: cust.code,
      name: cust.name,
      routeId: cust.routeId,
      salesmanId: cust.salesmanId,
      collectionManId: cust.collectionManId,
      sequenceNo: cust.sequenceNo,
      collectionSequence: cust.collectionSequence,
      mobile: cust.mobile,
      whatsapp: cust.whatsapp,
      address: cust.address,
      societyShort: cust.societyShort,
      subscriptions: updatedSubs,
      billingType: cust.billingType,
      fixedMonthlyAmount: cust.fixedMonthlyAmount,
      openingBalance: cust.openingBalance,
      currentBalance: cust.currentBalance,
      status: cust.status,
      inactiveDate: cust.inactiveDate,
      delChargeEnabled: cust.delChargeEnabled,
      delChargeAmt: cust.delChargeAmt,
      createdAt: cust.createdAt,
    );

    customers[idx] = updated;
  }

  // 6. Import JSON Backup
  void importFromJsonString(String jsonContent) {
    try {
      final data = jsonDecode(jsonContent);
      if (data is Map) {
        if (data['firm'] is Map) firm = Firm.fromJson(Map<String, dynamic>.from(data['firm']));
        if (data['items'] is List) {
          items.clear();
          for (final i in data['items']) {
            if (i is Map) items.add(Item.fromJson(Map<String, dynamic>.from(i)));
          }
        }
        if (data['customers'] is List) {
          customers.clear();
          for (final c in data['customers']) {
            if (c is Map) customers.add(Customer.fromJson(Map<String, dynamic>.from(c)));
          }
        }
        if (data['routes'] is List) {
          routes.clear();
          for (final r in data['routes']) {
            if (r is Map) routes.add(DeliveryRoute.fromJson(Map<String, dynamic>.from(r)));
          }
        }
        if (data['salesmen'] is List) {
          salesmen.clear();
          for (final s in data['salesmen']) {
            if (s is Map) salesmen.add(Salesman.fromJson(Map<String, dynamic>.from(s)));
          }
        }
        if (data['massIssues'] is List) {
          massIssues.clear();
          for (final m in data['massIssues']) {
            if (m is Map) massIssues.add(MassIssue.fromJson(Map<String, dynamic>.from(m)));
          }
        }
        if (data['vacations'] is List) {
          vacations.clear();
          for (final v in data['vacations']) {
            if (v is Map) vacations.add(Vacation.fromJson(Map<String, dynamic>.from(v)));
          }
        }
        if (data['bills'] is List) {
          bills.clear();
          for (final b in data['bills']) {
            if (b is Map) bills.add(Bill.fromJson(Map<String, dynamic>.from(b)));
          }
        }
        if (data['payments'] is List) {
          payments.clear();
          for (final p in data['payments']) {
            if (p is Map) payments.add(Payment.fromJson(Map<String, dynamic>.from(p)));
          }
        }
        if (data['expenses'] is List) {
          expenses.clear();
          for (final e in data['expenses']) {
            if (e is Map) expenses.add(Expense.fromJson(Map<String, dynamic>.from(e)));
          }
        }
        if (data['pressReturns'] is List) {
          pressReturns.clear();
          for (final r in data['pressReturns']) {
            if (r is Map) pressReturns.add(PressReturnEntry.fromJson(Map<String, dynamic>.from(r)));
          }
        }
      }
    } catch (e) {
      // Handle error gracefully
    }
  }

  // 6. Export JSON Backup
  String exportToJsonString() {
    final data = {
      'firm': firm.toJson(),
      'items': items.map((i) => i.toJson()).toList(),
      'customers': customers.map((c) => c.toJson()).toList(),
      'routes': routes.map((r) => r.toJson()).toList(),
      'salesmen': salesmen.map((s) => s.toJson()).toList(),
      'massIssues': massIssues.map((m) => m.toJson()).toList(),
      'vacations': vacations.map((v) => v.toJson()).toList(),
      'bills': bills.map((b) => b.toJson()).toList(),
      'payments': payments.map((p) => p.toJson()).toList(),
      'expenses': expenses.map((e) => e.toJson()).toList(),
      'pressReturns': pressReturns.map((r) => r.toJson()).toList(),
    };
    return const JsonEncoder.withIndent('  ').convert(data);
  }

  // 7. Monthly Press Supply & Return Reconciliation
  PressReconciliationReport getPressReconciliation(String monthYear) {
    final parts = monthYear.split('-');
    final year = int.tryParse(parts[0]) ?? DateTime.now().year;
    final month = int.tryParse(parts[1]) ?? DateTime.now().month;
    final daysInMonth = DateTime(year, month + 1, 0).day;

    final Map<int, int> suppliedCopiesMap = {};
    final Map<int, double> grossPurchaseMap = {};
    final Map<int, double> totalRateSumMap = {};
    final Map<int, int> rateDaysCountMap = {};

    for (int day = 1; day <= daysInMonth; day++) {
      final dateStr = '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
      final sheet = getDepotPurchaseSheet(dateStr);
      for (final itemDemand in sheet.items) {
        if (itemDemand.isHoliday) continue;
        suppliedCopiesMap[itemDemand.id] = (suppliedCopiesMap[itemDemand.id] ?? 0) + itemDemand.totalCopies;
        grossPurchaseMap[itemDemand.id] = (grossPurchaseMap[itemDemand.id] ?? 0.0) + itemDemand.purchaseAmount;
        totalRateSumMap[itemDemand.id] = (totalRateSumMap[itemDemand.id] ?? 0.0) + itemDemand.purchaseRate;
        rateDaysCountMap[itemDemand.id] = (rateDaysCountMap[itemDemand.id] ?? 0) + 1;
      }
    }

    final monthReturns = pressReturns.where((r) => r.date.startsWith(monthYear)).toList();
    final Map<int, int> returnedCopiesMap = {};
    final Map<int, double> returnCreditsMap = {};

    for (final ret in monthReturns) {
      returnedCopiesMap[ret.itemId] = (returnedCopiesMap[ret.itemId] ?? 0) + ret.copies;
      returnCreditsMap[ret.itemId] = (returnCreditsMap[ret.itemId] ?? 0.0) + ret.creditAmount;
    }

    final itemsSummary = <PressItemReconciliation>[];
    int totalSupplied = 0;
    double totalGross = 0.0;
    int totalReturned = 0;
    double totalReturnCredits = 0.0;

    for (final item in items) {
      final supplied = suppliedCopiesMap[item.id] ?? 0;
      final gross = grossPurchaseMap[item.id] ?? 0.0;
      final daysCount = rateDaysCountMap[item.id] ?? 1;
      final avgRate = daysCount > 0 ? ((totalRateSumMap[item.id] ?? item.defaultPurchaseRate) / daysCount) : item.defaultPurchaseRate;
      final returned = returnedCopiesMap[item.id] ?? 0;
      final credits = returnCreditsMap[item.id] ?? 0.0;
      final netPayable = (gross - credits) < 0 ? 0.0 : (gross - credits);

      if (supplied > 0 || returned > 0) {
        itemsSummary.add(PressItemReconciliation(
          itemId: item.id,
          itemName: item.name,
          itemCode: item.code,
          suppliedCopies: supplied,
          avgPurchaseRate: avgRate,
          grossPurchase: gross,
          returnedCopies: returned,
          returnCredits: credits,
          netPayable: netPayable,
        ));

        totalSupplied += supplied;
        totalGross += gross;
        totalReturned += returned;
        totalReturnCredits += credits;
      }
    }

    final netPayable = (totalGross - totalReturnCredits) < 0 ? 0.0 : (totalGross - totalReturnCredits);

    return PressReconciliationReport(
      monthYear: monthYear,
      totalSuppliedCopies: totalSupplied,
      totalGrossPurchase: totalGross,
      totalReturnedCopies: totalReturned,
      totalReturnCredits: totalReturnCredits,
      netPayableToPress: netPayable,
      itemsSummary: itemsSummary,
    );
  }

  // 8. Daily Cashbook Summary
  DailyCashbookSummary getDailyCashbookSummary(String dateStr, [double openingCash = 1500.0]) {
    final todaysCashPayments = payments.where((p) => p.date == dateStr && p.paymentMode == 'cash').toList();
    final todaysCashExpenses = expenses.where((e) => e.date == dateStr && (e.paymentMode == 'cash' || e.bankAccountId == null)).toList();
    final todaysBankDeposits = bankTransactions.where((t) => t.date == dateStr && t.type == 'deposit').toList();

    final cashCollection = todaysCashPayments.fold(0.0, (sum, p) => sum + p.amount);
    final cashExpensesTotal = todaysCashExpenses.fold(0.0, (sum, e) => sum + e.amount);
    final bankDepositsTotal = todaysBankDeposits.fold(0.0, (sum, t) => sum + t.amount);

    final totalCashInflow = openingCash + cashCollection;
    final totalCashOutflow = cashExpensesTotal + bankDepositsTotal;
    final closingCashInHand = totalCashInflow - totalCashOutflow;

    return DailyCashbookSummary(
      dateStr: dateStr,
      openingCash: openingCash,
      cashCollection: cashCollection,
      otherIncome: 0.0,
      totalCashInflow: totalCashInflow,
      cashExpenses: cashExpensesTotal,
      bankDeposits: bankDepositsTotal,
      totalCashOutflow: totalCashOutflow,
      closingCashInHand: closingCashInHand,
      todaysCashPayments: todaysCashPayments,
      todaysCashExpenses: todaysCashExpenses,
      todaysBankDeposits: todaysBankDeposits,
    );
  }

  // 9. Monthly Profit & Loss Summary
  MonthlyProfitLossSummary getMonthlyProfitLoss(String monthYear) {
    final monthBills = bills.where((b) => b.monthYear == monthYear).toList();
    final grossCustomerBilling = monthBills.fold(0.0, (sum, b) => sum + b.finalPayable);
    final totalDeliveryCharges = monthBills.fold(0.0, (sum, b) => sum + b.deliveryCharge);

    final pressReport = getPressReconciliation(monthYear);
    final totalPressPurchaseCost = pressReport.totalGrossPurchase;
    final totalReturnCredits = pressReport.totalReturnCredits;
    final netPressPurchaseCost = pressReport.netPayableToPress;

    final monthExpenses = expenses.where((e) => e.date.startsWith(monthYear)).toList();
    final totalOperatingExpenses = monthExpenses.where((e) => e.category != 'salary').fold(0.0, (sum, e) => sum + e.amount);
    final totalSalesmanCommission = monthExpenses.where((e) => e.category == 'salary').fold(0.0, (sum, e) => sum + e.amount);

    final netEstimatedProfit = grossCustomerBilling - netPressPurchaseCost - totalSalesmanCommission - totalOperatingExpenses;

    return MonthlyProfitLossSummary(
      monthYear: monthYear,
      grossCustomerBilling: grossCustomerBilling,
      totalDeliveryCharges: totalDeliveryCharges,
      totalPressPurchaseCost: totalPressPurchaseCost,
      totalReturnCredits: totalReturnCredits,
      netPressPurchaseCost: netPressPurchaseCost,
      totalSalesmanCommission: totalSalesmanCommission,
      totalOperatingExpenses: totalOperatingExpenses,
      netEstimatedProfit: netEstimatedProfit,
    );
  }
}
