import 'package:commerce_sdk/commerce_sdk.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

import 'screens/auth_screen.dart';
import 'screens/catalog_screen.dart';
import 'secure_token_store.dart';

const apiBaseUrl = String.fromEnvironment(
  'API_BASE_URL',
  defaultValue: 'http://localhost:3000',
);

class CommerceScrollBehavior extends MaterialScrollBehavior {
  const CommerceScrollBehavior();

  @override
  Set<PointerDeviceKind> get dragDevices => const {
    PointerDeviceKind.touch,
    PointerDeviceKind.mouse,
    PointerDeviceKind.stylus,
    PointerDeviceKind.invertedStylus,
    PointerDeviceKind.trackpad,
  };
}

class CommerceMobileApp extends StatefulWidget {
  const CommerceMobileApp({super.key, this.client});

  final CommerceClient? client;

  @override
  State<CommerceMobileApp> createState() => _CommerceMobileAppState();
}

class _CommerceMobileAppState extends State<CommerceMobileApp> {
  late final CommerceClient _client;
  AuthSession? _session;

  @override
  void initState() {
    super.initState();
    _client =
        widget.client ??
        CommerceClient(baseUrl: apiBaseUrl, tokenStore: SecureTokenStore());
  }

  @override
  void dispose() {
    _client.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = ColorScheme.fromSeed(
      seedColor: const Color(0xFF176B4D),
      brightness: Brightness.light,
    );

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Everything Store',
      scrollBehavior: const CommerceScrollBehavior(),
      theme: ThemeData(
        colorScheme: colorScheme,
        scaffoldBackgroundColor: const Color(0xFFF5F7F5),
        useMaterial3: true,
        appBarTheme: const AppBarTheme(
          centerTitle: false,
          backgroundColor: Color(0xFFF5F7F5),
          surfaceTintColor: Colors.transparent,
        ),
        inputDecorationTheme: const InputDecorationTheme(
          border: OutlineInputBorder(),
          filled: true,
          fillColor: Colors.white,
        ),
        cardTheme: const CardThemeData(
          elevation: 0,
          color: Colors.white,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(48, 48),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        ),
      ),
      home: _session == null
          ? AuthScreen(
              client: _client,
              onAuthenticated: (session) {
                setState(() => _session = session);
              },
            )
          : CatalogScreen(
              client: _client,
              session: _session!,
              onLogout: () async {
                await _client.logout();
                if (mounted) {
                  setState(() => _session = null);
                }
              },
            ),
    );
  }
}
