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
import '../auth/role_switcher_dialog.dart';
import '../auth/pin_auth_dialog.dart';

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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedIndex = 0;

  final List<NavModule> _modules = const [
    NavModule(icon: Icons.dashboard_rounded, label: 'ડેશબોર્ડ (Dashboard)', emoji: '📊'),
    NavModule(icon: Icons.delivery_dining_rounded, label: 'દૈનિક વિતરણ (Delivery)', emoji: '🛵'),
    NavModule(icon: Icons.storefront_rounded, label: 'ડેપો ખરીદી (Depot)', emoji: '🏬'),
    NavModule(icon: Icons.people_alt_rounded, label: 'ગ્રાહક માસ્ટર (Customers)', emoji: '👥'),
    NavModule(icon: Icons.beach_access_rounded, label: 'રજા કેલેન્ડર / બોનસ (Vacations)', emoji: '🌴'),
    NavModule(icon: Icons.receipt_long_rounded, label: 'માસિક બિલિંગ (Billing)', emoji: '🧾'),
    NavModule(icon: Icons.payments_rounded, label: 'ઉઘરાણી / UPI (Payments)', emoji: '💰'),
    NavModule(icon: Icons.pedal_bike_rounded, label: 'વિતરક ડિલિવરી શીટ (Salesman)', emoji: '🚴'),
    NavModule(icon: Icons.work_outline_rounded, label: 'ઉઘરાણી માસ્ટર (Collection)', emoji: '💼'),
    NavModule(icon: Icons.menu_book_rounded, label: 'ખાતાવહી (Ledgers)', emoji: '📚'),
    NavModule(icon: Icons.account_balance_wallet_rounded, label: 'ખર્ચ અને બેંક (Expenses)', emoji: '💸'),
    NavModule(icon: Icons.newspaper_rounded, label: 'પેપર માસ્ટર (Items)', emoji: '📰'),
    NavModule(icon: Icons.map_rounded, label: 'લાઇનો / રૂટ (Routes)', emoji: '🗺️'),
    NavModule(icon: Icons.settings_rounded, label: 'સેટિંગ્સ (Settings)', emoji: '⚙️'),
  ];

  int _getBottomNavIndex() {
    if (_selectedIndex == 0) return 0;
    if (_selectedIndex == 1) return 1;
    if (_selectedIndex == 3) return 2;
    if (_selectedIndex == 5) return 3;
    return 4; // Highlight 'વધુ' (More) for any other module
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(dbChangeNotifierProvider);
    final session = ref.watch(authSessionProvider);
    final firm = ref.watch(firmProvider);
    final db = DatabaseService.instance;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 900;
    final isVeryCompact = screenWidth < 500;
    final isCloud = db.storageMode == 'cloud';

    return Scaffold(
      key: _scaffoldKey,
      drawer: isWide ? null : _buildAppDrawer(context, session, firm, db, isCloud),
      appBar: AppBar(
        backgroundColor: AppColors.bgCardDark,
        elevation: 0,
        leading: isWide
            ? null
            : IconButton(
                icon: const Icon(Icons.menu, color: Colors.white),
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
                tooltip: 'મેનૂ',
              ),
        titleSpacing: isWide ? NavigationToolbar.kMiddleSpacing : 0,
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primaryTeal.withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('📰', style: TextStyle(fontSize: 18)),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          db.firm.name.isNotEmpty ? db.firm.name : 'Vendor Pro',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.white),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: BoxDecoration(
                          color: AppColors.primaryBlue.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          db.agencyId,
                          style: const TextStyle(fontSize: 9, color: AppColors.accentCyan, fontFamily: 'monospace', fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                  if (screenWidth >= 600)
                    const Text(
                      'ન્યૂઝપેપર વિતરણ અને બિલિંગ મેનેજમેન્ટ સિસ્ટમ',
                      style: TextStyle(fontSize: 10, color: AppColors.textMutedDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          // Role Switcher Badge Pill
          InkWell(
            onTap: () => RoleSwitcherDialog.show(context),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
              padding: EdgeInsets.symmetric(horizontal: isVeryCompact ? 6 : 8, vertical: 3),
              decoration: BoxDecoration(
                color: (session.isAdmin
                        ? AppColors.primaryTeal
                        : (session.isSalesman ? AppColors.primaryBlue : AppColors.accentGold))
                    .withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (session.isAdmin
                          ? AppColors.primaryTeal
                          : (session.isSalesman ? AppColors.primaryBlue : AppColors.accentGold))
                      .withOpacity(0.4),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isVeryCompact ? (session.isAdmin ? '👑' : (session.isSalesman ? '🚴' : '💼')) : session.roleBadgeLabel,
                    style: TextStyle(
                      color: session.isAdmin
                          ? AppColors.primaryTeal
                          : (session.isSalesman ? AppColors.primaryLight : AppColors.accentGold),
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Icon(Icons.arrow_drop_down, size: 14, color: AppColors.textMutedDark),
                ],
              ),
            ),
          ),
          // Dual-Role Quick Toggle Button (One-tap switch between Morning Delivery and Evening Collection)
          if (session.isDualRole)
            InkWell(
              onTap: () {
                ref.read(authSessionProvider.notifier).toggleDualRole();
                final current = ref.read(authSessionProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(current.isSalesman
                        ? '🚴‍♂️ સવારના વિતરણ મોડમાં સ્વિચ થયા!'
                        : '💼 સાંજની ઉઘરાણી મોડમાં સ્વિચ થયા!'),
                    backgroundColor: current.isSalesman ? AppColors.primaryBlue : AppColors.accentGold,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.accentGold.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.accentGold, width: 1.2),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.swap_horiz, size: 14, color: AppColors.accentGold),
                    const SizedBox(width: 4),
                    Text(
                      session.isSalesman ? '💼 ઉઘરાણી મોડ' : '🚴‍♂️ વિતરણ મોડ',
                      style: const TextStyle(
                        color: AppColors.accentGold,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          // Storage Mode Badge Pill (icon-only on very compact screens)
          if (!isVeryCompact)
            Container(
              margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 3),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: (isCloud ? AppColors.accentCyan : AppColors.successGreen).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: (isCloud ? AppColors.accentCyan : AppColors.successGreen).withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 7,
                    height: 7,
                    decoration: BoxDecoration(
                      color: isCloud ? AppColors.accentCyan : AppColors.successGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    isCloud ? 'Cloud' : 'ઓફલાઇન',
                    style: TextStyle(
                      color: isCloud ? AppColors.accentCyan : AppColors.successGreen,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          // Language toggle
          IconButton(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            constraints: const BoxConstraints(),
            onPressed: widget.onToggleLocale,
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.language, size: 18, color: AppColors.primaryTeal),
                const SizedBox(width: 2),
                Text(
                  widget.currentLocale.languageCode == 'gu' ? 'EN' : 'ગુજ',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryTeal),
                ),
              ],
            ),
            tooltip: 'Language / ભાષા',
          ),
          const SizedBox(width: 4),
        ],
      ),
      body: Row(
        children: [
          // Sidebar
          if (isWide)
            if (session.isAdmin)
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
              )
            else
              // Staff Mode Simple Sidebar
              Container(
                width: 220,
                color: AppColors.bgCardDark,
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: (session.isSalesman ? AppColors.primaryBlue : AppColors.accentGold).withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: (session.isSalesman ? AppColors.primaryBlue : AppColors.accentGold).withOpacity(0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            session.isSalesman ? '🚴‍♂️ વિતરક પોર્ટલ' : '💼 કલેક્શન પોર્ટલ',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: session.isSalesman ? AppColors.primaryLight : AppColors.accentGold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            session.isSalesman
                                ? (session.activeSalesman?.name ?? 'વિતરક')
                                : (session.activeCollectionMan?.name ?? 'કલેક્શન સ્ટાફ'),
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    ListTile(
                      leading: Icon(
                        session.isSalesman ? Icons.delivery_dining : Icons.work_outline,
                        color: AppColors.primaryTeal,
                      ),
                      title: Text(
                        session.isSalesman ? 'સવારની શીટ' : 'ઉઘરાણી લિસ્ટ',
                        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: AppColors.primaryTeal),
                      ),
                      selected: true,
                      selectedTileColor: AppColors.primaryTeal.withOpacity(0.12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      onTap: () {},
                    ),
                    const Spacer(),
                    // Return to Admin Button
                    ElevatedButton.icon(
                      onPressed: () async {
                        final verified = await PinAuthDialog.verify(
                          context,
                          title: '🔐 Owner Master PIN',
                          subtitle: 'એડમિન મોડમાં પાછા જવા માટે ૪ થી ૮ આંકડાનો Master PIN નાખો:',
                          expectedPin: firm.ownerPin.isNotEmpty ? firm.ownerPin : '1111',
                          roleBadge: '👑 એડમિન ઓથેન્ટિકેશન',
                        );
                        if (verified && context.mounted) {
                          ref.read(authSessionProvider.notifier).setAdmin();
                          setState(() => _selectedIndex = 0);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('👑 એડમિન મોડ સફળતાપૂર્વક અનલૉક થયો!'),
                              backgroundColor: AppColors.successGreen,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.lock_open, size: 16),
                      label: const Text('એડમિન પર પાછા જાઓ', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.surfaceDark,
                        foregroundColor: AppColors.accentGold,
                        side: const BorderSide(color: AppColors.accentGold),
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),

          // Main View Content
          Expanded(
            child: _buildCurrentView(session),
          ),
        ],
      ),
      bottomNavigationBar: isWide
          ? null
          : session.isAdmin
              ? BottomNavigationBar(
                  currentIndex: _getBottomNavIndex(),
                  onTap: (navIndex) {
                    if (navIndex == 4) {
                      _scaffoldKey.currentState?.openDrawer();
                    } else {
                      final targetMap = [0, 1, 3, 5];
                      setState(() => _selectedIndex = targetMap[navIndex]);
                    }
                  },
                  backgroundColor: AppColors.bgCardDark,
                  selectedItemColor: AppColors.primaryTeal,
                  unselectedItemColor: AppColors.textMutedDark,
                  type: BottomNavigationBarType.fixed,
                  selectedFontSize: 11,
                  unselectedFontSize: 10,
                  items: const [
                    BottomNavigationBarItem(icon: Icon(Icons.dashboard_rounded), label: 'ડેશબોર્ડ'),
                    BottomNavigationBarItem(icon: Icon(Icons.delivery_dining_rounded), label: 'દૈનિક'),
                    BottomNavigationBarItem(icon: Icon(Icons.people_alt_rounded), label: 'ગ્રાહક'),
                    BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'બિલિંગ'),
                    BottomNavigationBarItem(icon: Icon(Icons.menu_rounded), label: 'વધુ (મેનૂ)'),
                  ],
                )
              : null,
    );
  }

  Widget _buildAppDrawer(BuildContext context, AuthSession session, dynamic firm, DatabaseService db, bool isCloud) {
    return Drawer(
      backgroundColor: AppColors.bgCardDark,
      child: SafeArea(
        child: Column(
          children: [
            // Drawer Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: Color(0xFF141A28),
                border: Border(bottom: BorderSide(color: Color(0xFF222F46))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primaryTeal.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text('📰', style: TextStyle(fontSize: 22)),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              db.firm.name.isNotEmpty ? db.firm.name : 'Vendor Pro',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
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
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Storage & Role Status
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: (isCloud ? AppColors.accentCyan : AppColors.successGreen).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: isCloud ? AppColors.accentCyan : AppColors.successGreen,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              isCloud ? 'Cloud Sync' : '💾 ૧૦૦% ઓફલાઇન',
                              style: TextStyle(
                                color: isCloud ? AppColors.accentCyan : AppColors.successGreen,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (session.isDualRole) ...[
                        const SizedBox(width: 6),
                        InkWell(
                          onTap: () {
                            ref.read(authSessionProvider.notifier).toggleDualRole();
                            Navigator.pop(context);
                            final current = ref.read(authSessionProvider);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(current.isSalesman
                                    ? '🚴‍♂️ સવારના વિતરણ મોડમાં સ્વિચ થયા!'
                                    : '💼 સાંજની ઉઘરાણી મોડમાં સ્વિચ થયા!'),
                                backgroundColor: current.isSalesman ? AppColors.primaryBlue : AppColors.accentGold,
                                duration: const Duration(seconds: 2),
                              ),
                            );
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.accentGold.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                              border: Border.all(color: AppColors.accentGold),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.swap_horiz, size: 13, color: AppColors.accentGold),
                                const SizedBox(width: 4),
                                Text(
                                  session.isSalesman ? 'ઉઘરાણી' : 'વિતરણ',
                                  style: const TextStyle(color: AppColors.accentGold, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                      const Spacer(),
                      InkWell(
                        onTap: () {
                          Navigator.pop(context);
                          RoleSwitcherDialog.show(context);
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primaryTeal.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: AppColors.primaryTeal.withOpacity(0.3)),
                          ),
                          child: Text(
                            session.roleBadgeLabel,
                            style: const TextStyle(color: AppColors.primaryTeal, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Modules List (All 14 Modules Accessible!)
            Expanded(
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: _modules.length,
                itemBuilder: (context, index) {
                  final m = _modules[index];
                  final isSelected = _selectedIndex == index;
                  return ListTile(
                    dense: true,
                    leading: Text(m.emoji, style: const TextStyle(fontSize: 18)),
                    title: Text(
                      m.label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                        color: isSelected ? AppColors.primaryTeal : Colors.white,
                      ),
                    ),
                    trailing: isSelected
                        ? Container(
                            width: 6,
                            height: 24,
                            decoration: BoxDecoration(
                              color: AppColors.primaryTeal,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          )
                        : null,
                    selected: isSelected,
                    selectedTileColor: AppColors.primaryTeal.withOpacity(0.1),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    onTap: () {
                      setState(() => _selectedIndex = index);
                      Navigator.pop(context);
                    },
                  );
                },
              ),
            ),
            // Footer
            Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(
                color: Color(0xFF141A28),
                border: Border(top: BorderSide(color: Color(0xFF222F46))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Vendor Pro v2.0', style: TextStyle(fontSize: 11, color: AppColors.textMutedDark)),
                  TextButton.icon(
                    onPressed: () {
                      Navigator.pop(context);
                      widget.onToggleLocale();
                    },
                    icon: const Icon(Icons.language, size: 16, color: AppColors.primaryTeal),
                    label: Text(
                      widget.currentLocale.languageCode == 'gu' ? 'English' : 'ગુજરાતી',
                      style: const TextStyle(fontSize: 12, color: AppColors.primaryTeal),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCurrentView(AuthSession session) {
    if (session.isSalesman) {
      return const SalesmanPortalView();
    }
    if (session.isCollection) {
      return const CollectionPortalView();
    }

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
