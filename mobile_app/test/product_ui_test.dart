import 'package:commerce_sdk/commerce_sdk.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:theecommerce_mobile/app.dart';
import 'package:theecommerce_mobile/screens/admin_product_screen.dart';
import 'package:theecommerce_mobile/screens/catalog_screen.dart';

class FakeTransport implements CommerceTransport {
  final responses = <CommerceResponse>[];

  @override
  void close() {}

  @override
  Future<CommerceResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
  }) async {
    return responses.removeAt(0);
  }
}

const testUser = CommerceUser(
  id: 'user-1',
  username: 'maxwell',
  name: 'Maxwell Duedu',
  email: 'maxwell@example.com',
  role: 'user',
);

void main() {
  testWidgets('catalogue shows products, search, filters, and cart', (
    tester,
  ) async {
    final transport = FakeTransport()
      ..responses.add(
        const CommerceResponse(
          statusCode: 200,
          body: {
            'items': [
              {
                '_id': 'product-1',
                'name': 'Studio Headphones',
                'description':
                    'Comfortable wireless headphones with clear sound.',
                'price': 950,
                'stock': 12,
                'category': 'Electronics',
              },
            ],
            'page': 1,
            'limit': 24,
            'total': 1,
            'totalPages': 1,
            'categories': ['Electronics'],
            'sort': 'newest',
          },
        ),
      );
    final client = CommerceClient(
      baseUrl: 'https://example.com',
      transport: transport,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CatalogScreen(
          client: client,
          session: const AuthSession(token: 'token', user: testUser),
          onLogout: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Search products'), findsOneWidget);
    expect(find.text('Electronics'), findsWidgets);
    expect(find.text('Studio Headphones'), findsOneWidget);
    expect(find.text('Cart'), findsOneWidget);
    expect(find.byTooltip('Manage products'), findsNothing);
  });

  testWidgets('checkout dialog closes without using disposed controllers', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1000);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final transport = FakeTransport()
      ..responses.add(
        const CommerceResponse(
          statusCode: 200,
          body: {
            'items': [
              {
                '_id': 'product-1',
                'name': 'Studio Headphones',
                'description':
                    'Comfortable wireless headphones with clear sound.',
                'price': 950,
                'stock': 12,
                'category': 'Electronics',
              },
            ],
            'page': 1,
            'limit': 24,
            'total': 1,
            'totalPages': 1,
            'categories': ['Electronics'],
            'sort': 'newest',
          },
        ),
      );
    final client = CommerceClient(
      baseUrl: 'https://example.com',
      transport: transport,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: CatalogScreen(
          client: client,
          session: const AuthSession(token: 'token', user: testUser),
          onLogout: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    final addButton = find.text('Add');
    await tester.ensureVisible(addButton);
    await tester.tap(addButton);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cart'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Continue to checkout'));
    await tester.pumpAndSettle();

    expect(find.text('Shipping details'), findsOneWidget);
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Shipping details'), findsNothing);
  });

  testWidgets('catalogue scrolls with a mouse drag in the iOS simulator', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(430, 820);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final items = List<Map<String, Object?>>.generate(
      12,
      (index) => {
        '_id': 'product-$index',
        'name': 'Product ${index + 1}',
        'description': 'A detailed description for product ${index + 1}.',
        'price': 100 + index,
        'stock': 10,
        'category': 'Demo',
      },
    );
    final transport = FakeTransport()
      ..responses.add(
        CommerceResponse(
          statusCode: 200,
          body: {
            'items': items,
            'page': 1,
            'limit': 24,
            'total': 12,
            'totalPages': 1,
            'categories': const ['Demo'],
            'sort': 'newest',
          },
        ),
      );
    final client = CommerceClient(
      baseUrl: 'https://example.com',
      transport: transport,
    );

    await tester.pumpWidget(
      MaterialApp(
        scrollBehavior: const CommerceScrollBehavior(),
        home: CatalogScreen(
          client: client,
          session: const AuthSession(token: 'token', user: testUser),
          onLogout: () async {},
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Product 12'), findsNothing);
    final scrollable = find.descendant(
      of: find.byType(CustomScrollView),
      matching: find.byType(Scrollable),
    );
    final scrollableState = tester
        .stateList<ScrollableState>(scrollable)
        .firstWhere(
          (state) =>
              state.position.axisDirection == AxisDirection.down ||
              state.position.axisDirection == AxisDirection.up,
        );
    expect(scrollableState.position.pixels, 0);

    await tester.dragFrom(
      const Offset(220, 650),
      const Offset(0, -490),
      kind: PointerDeviceKind.mouse,
    );
    await tester.pumpAndSettle();

    expect(scrollableState.position.pixels, greaterThan(100));
  });

  testWidgets('admin product form validates required product fields', (
    tester,
  ) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: ProductFormSheet())),
    );

    expect(find.text('Add product'), findsOneWidget);
    expect(find.text('Product name'), findsOneWidget);
    expect(find.text('Image URL'), findsOneWidget);

    final submitButton = find.text('Create product');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pump();

    expect(find.text('Use at least 2 characters'), findsOneWidget);
    expect(find.text('Use at least 10 characters'), findsOneWidget);
    expect(find.text('Enter a valid HTTP or HTTPS URL'), findsOneWidget);
  });
}
