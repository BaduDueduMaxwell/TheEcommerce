import 'package:commerce_sdk/commerce_sdk.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theecommerce_mobile/app.dart';

class FakeTransport implements CommerceTransport {
  @override
  void close() {}

  @override
  Future<CommerceResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
  }) async {
    return const CommerceResponse(statusCode: 500, body: null);
  }
}

void main() {
  testWidgets('shows the authentication screen', (tester) async {
    final client = CommerceClient(
      baseUrl: 'https://example.com',
      tokenStore: MemoryTokenStore(),
      transport: FakeTransport(),
    );

    await tester.pumpWidget(CommerceMobileApp(client: client));

    expect(find.text('Everything Store'), findsOneWidget);
    expect(find.text('Find something worth keeping.'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
    expect(find.text('New here? Create an account'), findsOneWidget);
  });
}
