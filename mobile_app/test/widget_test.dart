import 'package:commerce_sdk/commerce_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theecommerce_mobile/app.dart';

void main() {
  testWidgets('shows the authentication screen', (tester) async {
    final client = CommerceClient(
      baseUrl: 'https://example.com',
      tokenStore: MemoryTokenStore(),
    );

    await tester.pumpWidget(CommerceMobileApp(client: client));

    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Find something worth keeping.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('New here? Create an account'), findsOneWidget);
  });
}
