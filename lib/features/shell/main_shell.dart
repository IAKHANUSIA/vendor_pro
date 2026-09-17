import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/providers/app_providers.dart';
import '../dashboard/dashboard_view.dart';
import '../daily_delivery/daily_delivery_view.dart';
import '../depot_purchase/depot_purchase_view.dart';
import '../customers/customers_view.dart';
import '../vacations/vacations_view.dart';
import '../billing/billing_view.dart';
import '../payments/payments_view.dart';
import '../salesman/salesman_portal_view.dart';
import '../collection/collection_portal_view.dart';
import '../ledgers/ledgers_view.dart';
import '../expenses/expenses_view.dart';
import '../items/items_view.dart';
import '../routes/routes_view.dart';
import '../settings/settings_view.dart';

class MainShell extends ConsumerStatefulWidget {
  final Locale currentLocale;
  final VoidCallback onToggleLocale;

  const MainShell({
    super.key,
    required this.currentLocale,
    required this.onToggleLocale,
  });

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell> {
  int _selectedIndex = 0;

  final List<NavModule> _modules = const [
    NavModule(icon: Icons.dashboard_rounded, label: 'ડેશબોર્ડ (Dashboard)', emoji: '📊'),
    NavModule(icon: Icons.delivery_dining_rounded, label: 'દૈનિક વિતરણ (Delivery)', emoji: '🛵'),
    NavModule(icon: Icons.storefront_rounded, label: 'ડેપો ખરીદી (Depot)', emoji: '🏬'),
    NavModule(icon: Icons.people_alt_rounded, label: 'ગ્રાહક માસ્ટર (Customers)', emoji: '👥'),
    NavModule(icon: Icons.beach_access_rounded, label: 'રજા કેલેન્ડર / બોનસ (Vacations)', emoji: '🌴'),
    NavModule(icon: Icons.receipt_long_rounded, label: 'માસિક બિલિંગ (Billing)', emoji: '🧾'),
    NavModule(icon: Icons.payments_rounded, label: 'ઉઘરાણી / UPI (Payments)', emoji: '💰'),
    NavModule(icon: Icons.pedal_bike_rounded, label: 'હોકર ડિલિવરી શીટ (Salesman)', emoji: '🚴'),
    NavModule(icon: Icons.work_outline_rounded, label: 'ઉઘરાણી માસ્ટર (Collection)', emoji: '💼'),
    NavModule(icon: Icons.menu_book_rounded, label: 'ખાતાવહી (Ledgers)', emoji: '📚'),
    NavModule(icon: Icons.account_balance_wallet_rounded, label: 'ખર્ચ અને બેંક (Expenses)', emoji: '💸'),
    NavModule(icon: Icons.newspaper_rounded, label: 'પેપર માસ્ટર (Items)', emoji: '📰'),
    NavModule(icon: Icons.map_rounded, label: 'લાઇનો / રૂટ (Routes)', emoji: '🗺️'),
    NavModule(icon: Icons.settings_rounded, label: 'સેટિંગ્સ (Settings)', emoji: '⚙️'),
  ];

  @override
  Widget build(BuildContext context) {
    ref.watch(dbChangeNotifierProvider);
    final db = DatabaseService.instance;
    final isWide = MediaQuery.of(context).size.width >= 900;
    final isCloud = db.storageMode == 'cloud';

    return Scaffold(
      appBar: AppBar(
        backgroundColor: AppColors.bgCardDark,
        elevation: 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('📰', style: TextStyle(fontSize: 20)),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      db.firm.name.isNotEmpty ? db.firm.name : 'Vendor Pro',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primaryBlue.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        db.agencyId,
                        style: const TextStyle(fontSize: 10, color: AppColors.accentCyan, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                const Text(
                  'ન્યૂઝપેપર વિતરણ અને બિલિંગ મેનેજમેન્ટ સિસ્ટમ',
                  style: TextStyle(fontSize: 11, color: AppColors.textMutedDark),
                ),
              ],
            ),
          ],
        ),
        actions: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: (isCloud ? AppColors.accentCyan : AppColors.successGreen).withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: (isCloud ? AppColors.accentCyan : AppColors.successGreen).withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: isCloud ? AppColors.accentCyan : AppColors.successGreen,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isCloud ? '☁️ Cloud Sync (Live)' : '💾 ૧૦૦% ઓફલાઇન',
                  style: TextStyle(
                    color: isCloud ? AppColors.accentCyan : AppColors.successGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: widget.onToggleLocale,
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, size: 20, color: AppColors.primaryTeal),
                const SizedBox(width: 4),
                Text(
                  widget.currentLocale.languageCode == 'gu' ? 'EN' : 'ગુજ',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryTeal),
                ),
              ],
            ),
            tooltip: 'Language / ભાષા',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Row(
        children: [
          if (isWide)
            NavigationRail(
              backgroundColor: AppColors.bgCardDark,
              selectedIndex: _selectedIndex,
              onDestinationSelected: (index) => setState(() => _selectedIndex = index),
              extended: MediaQuery.of(context).size.width >= 1200,
              minExtendedWidth: 220,
              destinations: _modules.map((m) {
                return NavigationRailDestination(
                  icon: Icon(m.icon),
                  selectedIcon: Icon(m.icon, color: AppColors.primaryTeal),
                  label: Text(
                    '${m.emoji} ${m.label}',
                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                  ),
                );
              }).toList(),
            ),
          Expanded(
            child: _buildCurrentView(),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : BottomNavigationBar(
              currentIndex: _selectedIndex > 4 ? 0 : _selectedIndex,
              onTap: (index) => setState(() => _selectedIndex = index),
              backgroundColor: AppColors.bgCardDark,
              selectedItemColor: AppColors.primaryTeal,
              unselectedItemColor: AppColors.textMutedDark,
              type: BottomNavigationBarType.fixed,
              items: _modules.take(5).map((m) {
                return BottomNavigationBarItem(
                  icon: Icon(m.icon),
                  label: m.label.split(' ')[0],
                );
              }).toList(),
            ),
    );
  }

  Widget _buildCurrentView() {
    switch (_selectedIndex) {
      case 0:
        return DashboardView(
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
      case 1:
        return const DailyDeliveryView();
      case 2:
        return const DepotPurchaseView();
      case 3:
        return const CustomersView();
      case 4:
        return const VacationsView();
      case 5:
        return const BillingView();
      case 6:
        return const PaymentsView();
      case 7:
        return const SalesmanPortalView();
      case 8:
        return const CollectionPortalView();
      case 9:
        return const LedgersView();
      case 10:
        return const ExpensesView();
      case 11:
        return const ItemsView();
      case 12:
        return const RoutesView();
      case 13:
        return const SettingsView();
      default:
        return DashboardView(
          onNavigate: (index) => setState(() => _selectedIndex = index),
        );
    }
  }
}

class NavModule {
  final IconData icon;
  final String label;
  final String emoji;

  const NavModule({
    required this.icon,
    required this.label,
    required this.emoji,
  });
}
