import 'package:flutter/material.dart';

class AppLocalizations {
  final Locale locale;
  AppLocalizations(this.locale);

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations) ??
        AppLocalizations(const Locale('gu', 'IN'));
  }

  static const _localizedValues = <String, Map<String, String>>{
    'gu': {
      'appTitle': 'વેન્ડર પ્રો (Vendor Pro)',
      'tagline': 'ન્યૂઝપેપર અને સામયિક વિતરણ વ્યવસ્થાપન સિસ્ટમ',
      'offlineStatus': '૧૦૦% ઓફલાઇન સક્રિય',
      'navDashboard': 'ડેશબોર્ડ',
      'navDailyDelivery': 'રોજિંદી વહેંચણી (સેલ)',
      'navDepot': 'ડેપો ખરીદી (સાંજનું સેલ)',
      'navCustomers': 'ગ્રાહક માસ્ટર',
      'navVacation': 'રજા કેલેન્ડર',
      'navBilling': 'મહિનાનું બિલિંગ',
      'navPayments': 'ઉઘરાણી અને UPI',
      'navItems': 'પેપર માસ્ટર',
      'navRoutes': 'લાઇન અને વિતરક',
      'navReports': 'ખાતાવહી અને હિસાબ',
      'navExpenses': 'ખર્ચ અને બેંક',
      'navSettings': 'સેટિંગ્સ અને બેકઅપ',
      'totalMorningPapers': 'સવારે જોઈતા કુલ પેપર્સ',
      'activeCustomers': 'કુલ સક્રિય ગ્રાહકો',
      'activeVacations': 'આજે રજા પર ગ્રાહકો',
      'monthlyBilled': 'આ મહિનાનું કુલ બિલિંગ',
      'monthlyCollected': 'કુલ જમા ઉઘરાણી',
      'monthlyPending': 'કુલ બાકી રકમ',
      'todayDemandSummary': 'ડેપોમાંથી લેવાના પેપર્સની વિગત',
      'save': 'સાચવો',
      'cancel': 'રદ કરો',
      'delete': 'હટાવો',
      'edit': 'ફેરફાર કરો',
      'add': 'ઉમેરો',
      'search': 'શોધો...',
      'all': 'બધા',
      'date': 'તારીખ',
      'rate': 'ભાવ',
      'mrp': 'વેચાણ ભાવ (MRP)',
      'ptr': 'ખરીદ ભાવ (PTR)',
      'copies': 'નકલ',
      'amount': 'રકમ (₹)',
      'status': 'સ્થિતિ',
      'actions': 'ક્રિયાઓ',
    },
    'en': {
      'appTitle': 'Vendor Pro',
      'tagline': 'Newspaper & Magazine Distribution Management',
      'offlineStatus': '100% Offline Active',
      'navDashboard': 'Dashboard',
      'navDailyDelivery': 'Daily Delivery',
      'navDepot': 'Depot Purchase',
      'navCustomers': 'Customer Master',
      'navVacation': 'Vacations',
      'navBilling': 'Monthly Billing',
      'navPayments': 'Payments & UPI',
      'navItems': 'Newspaper Master',
      'navRoutes': 'Routes & Hawkers',
      'navReports': 'Ledgers & Reports',
      'navExpenses': 'Expenses & Bank',
      'navSettings': 'Settings & Backup',
      'totalMorningPapers': 'Morning Papers Demand',
      'activeCustomers': 'Active Customers',
      'activeVacations': 'On Vacation Today',
      'monthlyBilled': 'Month Billed Total',
      'monthlyCollected': 'Total Collected',
      'monthlyPending': 'Total Outstanding',
      'todayDemandSummary': 'Depot Paper Collection Summary',
      'save': 'Save',
      'cancel': 'Cancel',
      'delete': 'Delete',
      'edit': 'Edit',
      'add': 'Add',
      'search': 'Search...',
      'all': 'All',
      'date': 'Date',
      'rate': 'Rate',
      'mrp': 'Sale Price (MRP)',
      'ptr': 'Purchase Rate (PTR)',
      'copies': 'Copies',
      'amount': 'Amount (₹)',
      'status': 'Status',
      'actions': 'Actions',
    }
  };

  String translate(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['gu']?[key] ??
        key;
  }
}
