import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/database/database_service.dart';
import '../../core/models/customer.dart';
import '../../core/models/firm.dart';
import '../../core/models/item.dart';
import '../../core/providers/app_providers.dart';

class BroadcastNoticeDialog extends ConsumerStatefulWidget {
  final Item? initialItem;

  const BroadcastNoticeDialog({
    super.key,
    this.initialItem,
  });

  static void show(BuildContext context, {Item? initialItem}) {
    showDialog(
      context: context,
      builder: (ctx) => BroadcastNoticeDialog(initialItem: initialItem),
    );
  }

  @override
  ConsumerState<BroadcastNoticeDialog> createState() => _BroadcastNoticeDialogState();
}

class _BroadcastNoticeDialogState extends ConsumerState<BroadcastNoticeDialog> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Mode 1: Price Hike
  int? _selectedItemId;
  final TextEditingController _oldRateCtrl = TextEditingController();
  final TextEditingController _newRateCtrl = TextEditingController();
  final TextEditingController _effectiveDateCtrl = TextEditingController();
  final TextEditingController _customHikeMsgCtrl = TextEditingController();

  // Mode 2: General / Festival Notice
  int? _selectedRouteId;
  String _presetType = 'diwali';
  final TextEditingController _generalMsgCtrl = TextEditingController();

  // Queue state
  int _currentQueueIndex = 0;
  final Set<int> _dispatchedCustomerIds = {};

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    final db = DatabaseService.instance;

    // Initialize item
    final item = widget.initialItem ?? (db.items.isNotEmpty ? db.items.first : null);
    if (item != null) {
      _selectedItemId = item.id;
      _oldRateCtrl.text = item.monthlyRate > 0 ? item.monthlyRate.toStringAsFixed(0) : item.defaultRate.toStringAsFixed(1);
      final newAmt = (double.tryParse(_oldRateCtrl.text) ?? 5.0) + (item.monthlyRate > 0 ? 20.0 : 1.0);
      _newRateCtrl.text = newAmt.toStringAsFixed(item.monthlyRate > 0 ? 0 : 1);
    }

    // Next 1st of month as default effective date
    final now = DateTime.now();
    final nextMonthFirst = DateTime(now.year, now.month + 1, 1);
    _effectiveDateCtrl.text = DateFormat('01/MM/yyyy').format(nextMonthFirst);

    _updateHikeMessageTemplate();
    _updateGeneralMessageTemplate();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _oldRateCtrl.dispose();
    _newRateCtrl.dispose();
    _effectiveDateCtrl.dispose();
    _customHikeMsgCtrl.dispose();
    _generalMsgCtrl.dispose();
    super.dispose();
  }

  void _onItemChanged(int? itemId) {
    if (itemId == null) return;
    setState(() {
      _selectedItemId = itemId;
      final db = DatabaseService.instance;
      final item = db.items.cast<Item?>().firstWhere((i) => i?.id == itemId, orElse: () => null);
      if (item != null) {
        _oldRateCtrl.text = item.monthlyRate > 0 ? item.monthlyRate.toStringAsFixed(0) : item.defaultRate.toStringAsFixed(1);
        final newAmt = (double.tryParse(_oldRateCtrl.text) ?? 5.0) + (item.monthlyRate > 0 ? 20.0 : 1.0);
        _newRateCtrl.text = newAmt.toStringAsFixed(item.monthlyRate > 0 ? 0 : 1);
        _updateHikeMessageTemplate();
      }
    });
  }

  void _updateHikeMessageTemplate() {
    final db = DatabaseService.instance;
    final item = db.items.cast<Item?>().firstWhere((i) => i?.id == _selectedItemId, orElse: () => null);
    final itemName = item?.name ?? 'ન્યૂઝપેપર';
    final oldRate = _oldRateCtrl.text.trim().isNotEmpty ? _oldRateCtrl.text.trim() : '0';
    final newRate = _newRateCtrl.text.trim().isNotEmpty ? _newRateCtrl.text.trim() : '0';
    final effDate = _effectiveDateCtrl.text.trim().isNotEmpty ? _effectiveDateCtrl.text.trim() : 'આગામી મહિનાથી';

    _customHikeMsgCtrl.text = '''📢 *ન્યૂઝપેપર ભાવ વધારા અંગે અગત્યની સૂચના*
━━━━━━━━━━━━━━━━━━
સન્માનીય ગ્રાહકશ્રી, *{CUSTOMER_NAME}*,

પ્રેસ/પ્રકાશન સંસ્થા તરફથી કાગળ અને ઉત્પાદન ખર્ચમાં થયેલા વધારાને લીધે તારીખ *$effDate* થી *$itemName* ના ભાવમાં ફેરફાર થયેલ છે:

• જૂનો ભાવ: ₹$oldRate
• સુધારેલ નવો ભાવ: *₹$newRate*
• અમલ તારીખ: *$effDate*

આપનો સહકાર હંમેશા અમારા માટે અમૂલ્ય રહ્યો છે. આપને અવિરત અને શ્રેષ્ઠ હોમ ડિલિવરી સેવા આપવા અમે કટિબદ્ધ છીએ.

આભાર સહ,
*{FIRM_NAME}*
સંપર્ક: {FIRM_PHONE}''';
  }

  void _updateGeneralMessageTemplate() {
    switch (_presetType) {
      case 'diwali':
        _generalMsgCtrl.text = '''🪔 *દિવાળી અને નૂતન વર્ષાભિનંદન શુભકામનાઓ!*
━━━━━━━━━━━━━━━━━━
સ્નેહી ગ્રાહકશ્રી, *{CUSTOMER_NAME}*,

આપને અને આપના સમગ્ર પરિવારને દીપાવલી પર્વ અને નૂતન વર્ષની હાર્દિક શુભકામનાઓ! આવનારું નવું વર્ષ આપના માટે સુખ, સમૃદ્ધિ અને ઉત્તમ સ્વાસ્થ્ય લઈને આવે એવી પ્રાર્થના.

📌 *અગત્યની સૂચના:*
તહેવાર નિમિત્તે પ્રેસ રજા હોવાથી બેસતા વર્ષ અને ભાઈબીજના દિવસે ન્યૂઝપેપર વિતરણ બંધ રહેશે. ત્યારબાદ નિયમિત વિતરણ ચાલુ રહેશે.

શુભેચ્છક:
*{FIRM_NAME}*
સંપર્ક: {FIRM_PHONE}''';
        break;
      case 'monsoon':
        _generalMsgCtrl.text = '''🌧️ *વરસાદી ઋતુ વિતરણ અંગે સૂચના*
━━━━━━━━━━━━━━━━━━
સન્માનીય ગ્રાહકશ્રી, *{CUSTOMER_NAME}*,

ભારે વરસાદ અથવા ખરાબ હવામાનના કારણે ક્યારેક સવારે ન્યૂઝપેપર વિતરણમાં થોડો વિલંબ થઈ શકે છે. અમારા વિતરકો તમારા સુધી સમયસર પેપર પહોંચાડવા પૂરતો પ્રયાસ કરે છે. 

આપના સહકાર અને ધીરજ બદલ ખૂબ ખૂબ આભાર!

આભાર સહ,
*{FIRM_NAME}*''';
        break;
      case 'vacation':
        _generalMsgCtrl.text = '''🌴 *વેકેશન / પ્રવાસ અંગે સૂચના*
━━━━━━━━━━━━━━━━━━
સન્માનીય ગ્રાહકશ્રી, *{CUSTOMER_NAME}*,

જો આપ આગામી દિવસોમાં બહારગામ અથવા પ્રવાસે જવાના હોવ, તો કૃપા કરીને પેપર બંધ (Hold) કરાવવા માટે ૧ દિવસ અગાઉ અમને જાણ કરવા વિનંતી જેથી બિલમાં તેટલા દિવસોની રજા ગણાઈ શકે.

આભાર સહ,
*{FIRM_NAME}*
સંપર્ક: {FIRM_PHONE}''';
        break;
      default:
        _generalMsgCtrl.text = '''📢 *અગત્યની જાહેર સૂચના*
━━━━━━━━━━━━━━━━━━
સન્માનીય ગ્રાહકશ્રી, *{CUSTOMER_NAME}*,

અમારી ન્યૂઝપેપર એજન્સી તરફથી આપને જણાવવાનું કે નિયમિત વિતરણ સેવા અને બિલ પેમેન્ટ સંબંધી કોઈપણ પ્રશ્ન માટે આપ અમારો સંપર્ક કરી શકો છો.

આભાર સહ,
*{FIRM_NAME}*
સંપર્ક: {FIRM_PHONE}''';
    }
  }

  List<Customer> _getTargetRecipients() {
    final db = DatabaseService.instance;
    if (_tabController.index == 0) {
      // Filter customers subscribed to _selectedItemId
      if (_selectedItemId == null) return [];
      return db.customers.where((c) {
        return c.status == 'active' && c.subscriptionItemIds.contains(_selectedItemId);
      }).toList();
    } else {
      // Filter by route if selected
      return db.customers.where((c) {
        if (c.status != 'active') return false;
        if (_selectedRouteId != null && c.routeId != _selectedRouteId) return false;
        return true;
      }).toList();
    }
  }

  String _formatMessageForCustomer(Customer customer, Firm firm) {
    final rawMsg = _tabController.index == 0 ? _customHikeMsgCtrl.text : _generalMsgCtrl.text;
    return rawMsg
        .replaceAll('{CUSTOMER_NAME}', customer.name)
        .replaceAll('{FIRM_NAME}', firm.name)
        .replaceAll('{FIRM_PHONE}', firm.phone);
  }

  void _dispatchCurrentWhatsApp(List<Customer> recipients, Firm firm) async {
    if (recipients.isEmpty || _currentQueueIndex >= recipients.length) return;

    final customer = recipients[_currentQueueIndex];
    final phone = customer.phone.isNotEmpty ? customer.phone : customer.mobile;
    if (phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${customer.name} નો મોબાઈલ નંબર ઉપલબ્ધ નથી. આગળ વધો.')),
      );
      _skipNext(recipients);
      return;
    }

    final cleanPhone = phone.replaceAll(RegExp(r'\D'), '');
    final fullPhone = cleanPhone.length == 10 ? '91$cleanPhone' : cleanPhone;
    final msg = _formatMessageForCustomer(customer, firm);

    final uri = Uri.parse('https://wa.me/$fullPhone?text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
      setState(() {
        _dispatchedCustomerIds.add(customer.id);
        if (_currentQueueIndex < recipients.length - 1) {
          _currentQueueIndex++;
        }
      });
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('WhatsApp ખોલી શકાયું નથી.')),
        );
      }
    }
  }

  void _skipNext(List<Customer> recipients) {
    if (_currentQueueIndex < recipients.length - 1) {
      setState(() => _currentQueueIndex++);
    }
  }

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    final firm = ref.watch(firmProvider);
    final targetRecipients = _getTargetRecipients();

    if (_currentQueueIndex >= targetRecipients.length && targetRecipients.isNotEmpty) {
      _currentQueueIndex = targetRecipients.length - 1;
    }

    final currentTarget = targetRecipients.isNotEmpty && _currentQueueIndex < targetRecipients.length
        ? targetRecipients[_currentQueueIndex]
        : null;

    return Dialog(
      backgroundColor: AppColors.bgCardDark,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 820,
        height: 640,
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primaryTeal.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.campaign, color: AppColors.primaryTeal, size: 24),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '📢 ગ્રાહક બ્રોડકાસ્ટ અને ભાવ વધારા નોટિસ',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 17, color: Colors.white),
                      ),
                      Text(
                        'ગ્રાહકોને વૉટ્સએપ દ્વારા ભાવ વધારો અથવા તહેવારની શુભેચ્છા સૂચના મોકલો',
                        style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 12),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close, color: AppColors.textMutedDark),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Tab Bar
            Container(
              decoration: BoxDecoration(
                color: AppColors.surfaceDark,
                borderRadius: BorderRadius.circular(10),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorColor: AppColors.primaryTeal,
                labelColor: AppColors.primaryTeal,
                unselectedLabelColor: AppColors.textSecondaryDark,
                onTap: (_) => setState(() {
                  _currentQueueIndex = 0;
                  _dispatchedCustomerIds.clear();
                }),
                tabs: const [
                  Tab(icon: Icon(Icons.trending_up, size: 18), text: '📈 ભાવ વધારો નોટિસ (Price Hike)'),
                  Tab(icon: Icon(Icons.celebration, size: 18), text: '🎊 સામાન્ય / તહેવાર નોટિસ (Festival & General)'),
                ],
              ),
            ),
            const SizedBox(height: 14),

            // Main Split Content
            Expanded(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left Pane: Config & Message Editor (55%)
                  Expanded(
                    flex: 55,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_tabController.index == 0) ...[
                            // Mode 1: Price Hike Controls
                            DropdownButtonFormField<int>(
                              value: _selectedItemId,
                              dropdownColor: AppColors.bgCardDark,
                              decoration: const InputDecoration(labelText: 'ન્યૂઝપેપર પસંદ કરો (Select Newspaper)', isDense: true),
                              items: db.items.map((it) {
                                return DropdownMenuItem(value: it.id, child: Text('${it.name} (${it.code})'));
                              }).toList(),
                              onChanged: _onItemChanged,
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    controller: _oldRateCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'જૂનો ભાવ (₹)', prefixText: '₹', isDense: true),
                                    onChanged: (_) => setState(_updateHikeMessageTemplate),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _newRateCtrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(labelText: 'નવો ભાવ (₹)', prefixText: '₹', isDense: true),
                                    onChanged: (_) => setState(_updateHikeMessageTemplate),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextField(
                                    controller: _effectiveDateCtrl,
                                    decoration: const InputDecoration(labelText: 'અમલ તારીખ', isDense: true),
                                    onChanged: (_) => setState(_updateHikeMessageTemplate),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ] else ...[
                            // Mode 2: General Notice Controls
                            Row(
                              children: [
                                Expanded(
                                  flex: 3,
                                  child: DropdownButtonFormField<String>(
                                    value: _presetType,
                                    dropdownColor: AppColors.bgCardDark,
                                    decoration: const InputDecoration(labelText: 'મેસેજ નમૂનો (Preset)', isDense: true),
                                    items: const [
                                      DropdownMenuItem(value: 'diwali', child: Text('🪔 દિવાળી / નૂતન વર્ષ & રજા')),
                                      DropdownMenuItem(value: 'monsoon', child: Text('🌧️ ચોમાસુ / વરસાદી સૂચના')),
                                      DropdownMenuItem(value: 'vacation', child: Text('🌴 વેકેશન / હોલ્ડ સૂચના')),
                                      DropdownMenuItem(value: 'general', child: Text('📝 સામાન્ય જાહેર સૂચના')),
                                    ],
                                    onChanged: (v) {
                                      if (v != null) {
                                        setState(() {
                                          _presetType = v;
                                          _updateGeneralMessageTemplate();
                                        });
                                      }
                                    },
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  flex: 2,
                                  child: DropdownButtonFormField<int?>(
                                    value: _selectedRouteId,
                                    dropdownColor: AppColors.bgCardDark,
                                    decoration: const InputDecoration(labelText: 'લાઇન ફિલ્ટર', isDense: true),
                                    items: [
                                      const DropdownMenuItem<int?>(value: null, child: Text('બધી લાઇન')),
                                      ...db.routes.map((r) => DropdownMenuItem<int?>(value: r.id, child: Text(r.name))),
                                    ],
                                    onChanged: (v) => setState(() => _selectedRouteId = v),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                          ],

                          // Message Body Editor
                          const Text('મેસેજ બોડી (સંદેશ સુધારો):', style: TextStyle(color: AppColors.textSecondaryDark, fontSize: 11, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 4),
                          TextField(
                            controller: _tabController.index == 0 ? _customHikeMsgCtrl : _generalMsgCtrl,
                            maxLines: 8,
                            style: const TextStyle(fontSize: 12, height: 1.4, fontFamily: 'monospace'),
                            decoration: InputDecoration(
                              filled: true,
                              fillColor: AppColors.surfaceDark,
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            ),
                            onChanged: (_) => setState(() {}),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(width: 16),

                  // Right Pane: Target Subscribers Queue (45%)
                  Expanded(
                    flex: 45,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceDark,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.borderDark),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Queue Header & Progress
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'લક્ષ્ય ગ્રાહકો (${targetRecipients.length})',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.white),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: AppColors.successGreen.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  '${_dispatchedCustomerIds.length} / ${targetRecipients.length} મોકલાયેલ',
                                  style: const TextStyle(color: AppColors.successGreen, fontSize: 11, fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),

                          // Linear Progress
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: targetRecipients.isNotEmpty ? _dispatchedCustomerIds.length / targetRecipients.length : 0.0,
                              backgroundColor: AppColors.bgCardDark,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.successGreen),
                              minHeight: 6,
                            ),
                          ),
                          const SizedBox(height: 10),

                          // Recipients List View
                          Expanded(
                            child: targetRecipients.isEmpty
                                ? const Center(child: Text('કોઈ ગ્રાહક મળ્યા નથી', style: TextStyle(color: AppColors.textMutedDark)))
                                : ListView.builder(
                                    itemCount: targetRecipients.length,
                                    itemBuilder: (ctx, i) {
                                      final c = targetRecipients[i];
                                      final isCurrent = i == _currentQueueIndex;
                                      final isSent = _dispatchedCustomerIds.contains(c.id);

                                      return InkWell(
                                        onTap: () => setState(() => _currentQueueIndex = i),
                                        child: Container(
                                          margin: const EdgeInsets.only(bottom: 6),
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                                          decoration: BoxDecoration(
                                            color: isCurrent
                                                ? AppColors.primaryTeal.withOpacity(0.15)
                                                : (isSent ? AppColors.bgCardDark.withOpacity(0.5) : AppColors.bgCardDark),
                                            borderRadius: BorderRadius.circular(8),
                                            border: Border.all(
                                              color: isCurrent ? AppColors.primaryTeal : (isSent ? AppColors.successGreen.withOpacity(0.4) : AppColors.borderDark),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              Icon(
                                                isSent ? Icons.check_circle : (isCurrent ? Icons.play_arrow : Icons.person_outline),
                                                size: 16,
                                                color: isSent ? AppColors.successGreen : (isCurrent ? AppColors.accentCyan : AppColors.textMutedDark),
                                              ),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                child: Column(
                                                  crossAxisAlignment: CrossAxisAlignment.start,
                                                  children: [
                                                    Text(c.name, style: TextStyle(fontSize: 12, fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal, color: Colors.white)),
                                                    Text('📞 ${c.phone.isNotEmpty ? c.phone : c.mobile}', style: const TextStyle(fontSize: 10, color: AppColors.textSecondaryDark)),
                                                  ],
                                                ),
                                              ),
                                              if (isSent)
                                                const Text('✅ મોકલાયું', style: TextStyle(fontSize: 10, color: AppColors.successGreen, fontWeight: FontWeight.bold))
                                              else if (isCurrent)
                                                const Text('▶️ આગળ', style: TextStyle(fontSize: 10, color: AppColors.accentCyan, fontWeight: FontWeight.bold)),
                                            ],
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                          ),

                          const Divider(color: AppColors.borderDark, height: 16),

                          // Active Recipient Action Box
                          if (currentTarget != null) ...[
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'હાલ પસંદ: ${currentTarget.name}',
                                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.accentCyan),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.copy, size: 16, color: AppColors.textSecondaryDark),
                                  tooltip: 'મેસેજ કોપી કરો',
                                  onPressed: () {
                                    final msg = _formatMessageForCustomer(currentTarget, firm);
                                    Clipboard.setData(ClipboardData(text: msg));
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('મેસેજ કોપી થઈ ગયો! 📋')),
                                    );
                                  },
                                ),
                                TextButton(
                                  onPressed: () => _skipNext(targetRecipients),
                                  child: const Text('સ્કીપ ⏭️', style: TextStyle(fontSize: 11)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF25D366),
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                ),
                                onPressed: () => _dispatchCurrentWhatsApp(targetRecipients, firm),
                                icon: const Icon(Icons.send, size: 16),
                                label: Text(
                                  'WhatsApp મોકલો અને આગળ વધો (${_currentQueueIndex + 1}/${targetRecipients.length})',
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
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
}
