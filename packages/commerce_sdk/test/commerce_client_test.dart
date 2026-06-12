import 'package:commerce_sdk/commerce_sdk.dart';
import 'package:test/test.dart';

class FakeTransport implements CommerceTransport {
  final responses = <CommerceResponse>[];
  final requests =
      <({String method, Uri uri, Map<String, String> headers, Object? body})>[];

  @override
  void close() {}

  @override
  Future<CommerceResponse> send({
    required String method,
    required Uri uri,
    required Map<String, String> headers,
    Object? body,
  }) async {
    requests.add((method: method, uri: uri, headers: headers, body: body));
    return responses.removeAt(0);
  }
}

void main() {
  test('login stores the token and returns a typed user', () async {
    final transport = FakeTransport()
      ..responses.add(
        const CommerceResponse(
          statusCode: 200,
          body: {
            'token': 'jwt-token',
            'user': {
              '_id': 'user-1',
              'username': 'maxwell',
              'name': 'Maxwell Duedu',
              'email': 'maxwell@example.com',
              'role': 'user',
            },
          },
        ),
      );
    final tokenStore = MemoryTokenStore();
    final client = CommerceClient(
      baseUrl: 'https://example.com',
      transport: transport,
      tokenStore: tokenStore,
    );

    final session = await client.login(
      email: 'maxwell@example.com',
      password: 'secret',
    );

    expect(session.user.name, 'Maxwell Duedu');
    expect(await tokenStore.read(), 'jwt-token');
    expect(transport.requests.single.uri.path, '/api/users/login');
  });

  test('getProducts maps API data into typed products', () async {
    final transport = FakeTransport()
      ..responses.add(
        const CommerceResponse(
          statusCode: 200,
          body: {
            'items': [
              {
                '_id': 'product-1',
                'name': 'Keyboard',
                'description': 'Mechanical keyboard',
                'price': 250,
                'stock': 4,
              },
            ],
            'page': 1,
            'limit': 12,
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

    final products = await client.getProducts();

    expect(products.single.name, 'Keyboard');
    expect(products.single.price, 250);
  });

  test('product page includes filters and maps pagination metadata', () async {
    final transport = FakeTransport()
      ..responses.add(
        const CommerceResponse(
          statusCode: 200,
          body: {
            'items': <Object?>[],
            'page': 2,
            'limit': 8,
            'total': 10,
            'totalPages': 2,
            'categories': ['Home'],
            'sort': 'price_asc',
          },
        ),
      );
    final client = CommerceClient(
      baseUrl: 'https://example.com',
      transport: transport,
    );

    final page = await client.getProductPage(
      query: const ProductQuery(
        page: 2,
        limit: 8,
        search: 'lamp',
        category: 'Home',
        sort: ProductSort.priceLowToHigh,
      ),
    );

    expect(page.total, 10);
    expect(transport.requests.single.uri.queryParameters['search'], 'lamp');
    expect(transport.requests.single.uri.queryParameters['category'], 'Home');
    expect(transport.requests.single.uri.queryParameters['sort'], 'price_asc');
  });

  test('admin product create sends typed input and bearer token', () async {
    final transport = FakeTransport()
      ..responses.add(
        const CommerceResponse(
          statusCode: 201,
          body: {
            '_id': 'product-2',
            'name': 'Desk Lamp',
            'description': 'A warm adjustable desk lamp.',
            'price': 300,
            'stock': 5,
            'category': 'Home',
            'imageURL': 'https://example.com/lamp.jpg',
          },
        ),
      );
    final tokenStore = MemoryTokenStore();
    await tokenStore.write('admin-token');
    final client = CommerceClient(
      baseUrl: 'https://example.com',
      transport: transport,
      tokenStore: tokenStore,
    );

    final product = await client.createProduct(
      const ProductInput(
        name: 'Desk Lamp',
        description: 'A warm adjustable desk lamp.',
        price: 300,
        stock: 5,
        category: 'Home',
        imageUrl: 'https://example.com/lamp.jpg',
      ),
    );

    expect(product.id, 'product-2');
    expect(transport.requests.single.method, 'POST');
    expect(transport.requests.single.uri.path, '/api/products');
    expect(
      transport.requests.single.headers['authorization'],
      'Bearer admin-token',
    );
  });

  test('flushEvents retains queued events after a failed request', () async {
    final transport = FakeTransport()
      ..responses.add(
        const CommerceResponse(
          statusCode: 503,
          body: {'message': 'Unavailable'},
        ),
      );
    final tokenStore = MemoryTokenStore();
    await tokenStore.write('jwt-token');
    final client = CommerceClient(
      baseUrl: 'https://example.com',
      transport: transport,
      tokenStore: tokenStore,
      maxRetries: 0,
    );

    await client.track(name: 'product_viewed');

    await expectLater(client.flushEvents(), throwsA(isA<CommerceException>()));

    transport.responses.add(
      const CommerceResponse(statusCode: 202, body: {'accepted': 1}),
    );
    await client.flushEvents();
    expect(transport.requests, hasLength(2));
  });
}
