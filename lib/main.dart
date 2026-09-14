import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'core/theme/app_theme.dart';
import 'core/localization/app_localizations.dart';
import 'core/database/database_service.dart';
import 'core/providers/app_providers.dart';
import 'features/shell/main_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await DatabaseService.instance.init();
  runApp(
    const ProviderScope(
      child: VendorProApp(),
    ),
  );
}

class VendorProApp extends ConsumerStatefulWidget {
  const VendorProApp({super.key});

  @override
  ConsumerState<VendorProApp> createState() => _VendorProAppState();
}

class _VendorProAppState extends ConsumerState<VendorProApp> {
  Locale _currentLocale = const Locale('gu', 'IN');

  void _toggleLocale() {
    setState(() {
      _currentLocale = _currentLocale.languageCode == 'gu'
          ? const Locale('en', 'US')
          : const Locale('gu', 'IN');
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Vendor Pro',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: _currentLocale,
      supportedLocales: const [
        Locale('gu', 'IN'),
        Locale('en', 'US'),
      ],
      localizationsDelegates: const [
        _AppLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: MainShell(
        currentLocale: _currentLocale,
        onToggleLocale: _toggleLocale,
      ),
    );
  }
}

class _AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['gu', 'en'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
