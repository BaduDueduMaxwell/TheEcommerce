import 'dart:async';
import 'dart:io';

import 'errors.dart';
import 'models.dart';
import 'token_store.dart';
import 'transport.dart';

class CommerceClient {
  CommerceClient({
    required String baseUrl,
    TokenStore? tokenStore,
    CommerceTransport? transport,
    this.maxRetries = 2,
  }) : baseUri = Uri.parse(baseUrl.endsWith('/') ? baseUrl : '$baseUrl/'),
       tokenStore = tokenStore ?? MemoryTokenStore(),
       _transport = transport ?? IoCommerceTransport();

  final Uri baseUri;
  final TokenStore tokenStore;
  final int maxRetries;
  final CommerceTransport _transport;
  final List<AnalyticsEvent> _eventQueue = [];
  int _eventSequence = 0;

  Future<CommerceUser> signUp({
    required String username,
    required String name,
    required String email,
    required String password,
  }) async {
    final body = await _request(
      'POST',
      'api/users/signup',
      authenticated: false,
      body: {
        'username': username,
        'name': name,
        'email': email,
        'password': password,
      },
    );
    return CommerceUser.fromJson(_map(body)['user'] as Map<String, Object?>);
  }

  Future<AuthSession> login({
    required String email,
    required String password,
  }) async {
    final body = _map(
      await _request(
        'POST',
        'api/users/login',
        authenticated: false,
        body: {'email': email, 'password': password},
      ),
    );
    final token = body['token'] as String;
    final user = CommerceUser.fromJson(body['user'] as Map<String, Object?>);
    await tokenStore.write(token);
    return AuthSession(token: token, user: user);
  }

  Future<void> logout() => tokenStore.clear();

  Future<List<Product>> getProducts() async {
    return (await getProductPage()).items;
  }

  Future<ProductPage> getProductPage({
    ProductQuery query = const ProductQuery(),
  }) async {
    final uri = Uri(
      path: 'api/products',
      queryParameters: query.toQueryParameters(),
    );
    final body = _map(
      await _request('GET', uri.toString(), authenticated: false),
    );
    return ProductPage.fromJson(body);
  }

  Future<Product> getProduct(String productId) async {
    final body = _map(
      await _request('GET', 'api/products/$productId', authenticated: false),
    );
    return Product.fromJson(body);
  }

  Future<Product> createProduct(ProductInput input) async {
    final body = _map(
      await _request('POST', 'api/products', body: input.toJson()),
    );
    return Product.fromJson(body);
  }

  Future<Product> updateProduct(String productId, ProductInput input) async {
    final body = _map(
      await _request('PUT', 'api/products/$productId', body: input.toJson()),
    );
    return Product.fromJson(body);
  }

  Future<Product> restockProduct(String productId, int stock) async {
    final body = _map(
      await _request(
        'PATCH',
        'api/products/$productId',
        body: {'stock': stock},
      ),
    );
    return Product.fromJson(body);
  }

  Future<void> deleteProduct(String productId) async {
    await _request('DELETE', 'api/products/$productId');
  }

  Future<Cart> getCart(String userId) async {
    return Cart.fromJson(_map(await _request('GET', 'api/cart/$userId')));
  }

  Future<Cart> createCart(String userId, List<CartItemInput> items) async {
    return Cart.fromJson(
      _map(
        await _request(
          'POST',
          'api/cart',
          body: {
            'userId': userId,
            'items': items.map((item) => item.toJson()).toList(),
          },
        ),
      ),
    );
  }

  Future<Cart> updateCart(String userId, List<CartItemInput> items) async {
    return Cart.fromJson(
      _map(
        await _request(
          'PUT',
          'api/cart/$userId',
          body: {'items': items.map((item) => item.toJson()).toList()},
        ),
      ),
    );
  }

  Future<Order> placeOrder({
    required List<CartItemInput> items,
    required ShippingAddress shippingAddress,
    String paymentMethod = 'Paystack',
  }) async {
    final response = _map(
      await _request(
        'POST',
        'api/orders/place-order',
        body: {
          'items': items.map((item) => item.toJson()).toList(),
          'shippingAddress': shippingAddress.toJson(),
          'paymentMethod': paymentMethod,
        },
      ),
    );
    return Order.fromJson(response['order'] as Map<String, Object?>);
  }

  Future<List<Order>> getOrders(String userId) async {
    final body = _list(await _request('GET', 'api/orders/my-orders/$userId'));
    return body
        .map((item) => Order.fromJson(item as Map<String, Object?>))
        .toList(growable: false);
  }

  Future<PaymentSession> initializePayment({
    required String orderId,
    required String email,
    String currency = 'GHS',
  }) async {
    final body = _map(
      await _request(
        'POST',
        'api/payment',
        body: {'orderId': orderId, 'email': email, 'currency': currency},
      ),
    );
    return PaymentSession.fromJson(body);
  }

  Future<void> verifyPayment(String reference) async {
    await _request('GET', 'api/payment/verify/$reference');
  }

  Future<void> track({
    required String name,
    Map<String, Object?> properties = const {},
    String? platform,
    String? appVersion,
  }) async {
    _eventSequence += 1;
    _eventQueue.add(
      AnalyticsEvent(
        eventId:
            '${DateTime.now().microsecondsSinceEpoch.toRadixString(36)}-$_eventSequence',
        name: name,
        occurredAt: DateTime.now(),
        properties: properties,
        platform: platform,
        appVersion: appVersion,
      ),
    );

    if (_eventQueue.length >= 10) {
      await flushEvents();
    }
  }

  Future<void> flushEvents() async {
    if (_eventQueue.isEmpty) {
      return;
    }

    final batch = List<AnalyticsEvent>.from(_eventQueue);
    await _request(
      'POST',
      'api/events',
      body: {'events': batch.map((event) => event.toJson()).toList()},
    );
    _eventQueue.removeRange(0, batch.length);
  }

  Future<Object?> _request(
    String method,
    String path, {
    Object? body,
    bool authenticated = true,
  }) async {
    final headers = <String, String>{
      HttpHeaders.acceptHeader: ContentType.json.mimeType,
      HttpHeaders.contentTypeHeader: ContentType.json.mimeType,
    };

    if (authenticated) {
      final token = await tokenStore.read();
      if (token == null || token.isEmpty) {
        throw const CommerceException('Authentication is required');
      }
      headers[HttpHeaders.authorizationHeader] = 'Bearer $token';
    }

    Object? lastError;
    for (var attempt = 0; attempt <= maxRetries; attempt += 1) {
      try {
        final response = await _transport.send(
          method: method,
          uri: baseUri.resolve(path),
          headers: headers,
          body: body,
        );

        if (response.statusCode >= 200 && response.statusCode < 300) {
          return response.body;
        }

        final responseMap = response.body is Map ? response.body as Map : null;
        final nestedError = responseMap?['error'];
        final message = nestedError is Map
            ? (nestedError['message']?.toString() ?? 'Request failed')
            : (responseMap?['message']?.toString() ?? 'Request failed');
        final error = CommerceException(
          message,
          statusCode: response.statusCode,
        );

        if (response.statusCode < 500 || attempt == maxRetries) {
          throw error;
        }
        lastError = error;
      } on CommerceException {
        rethrow;
      } on Object catch (error) {
        lastError = error;
        if (attempt == maxRetries) {
          throw CommerceException('Network request failed', cause: error);
        }
      }

      await Future<void>.delayed(Duration(milliseconds: 150 * (attempt + 1)));
    }

    throw CommerceException('Request failed', cause: lastError);
  }

  Map<String, Object?> _map(Object? value) {
    if (value is Map<String, Object?>) {
      return value;
    }
    throw const CommerceException('The API returned an invalid object');
  }

  List<Object?> _list(Object? value) {
    if (value is List<Object?>) {
      return value;
    }
    throw const CommerceException('The API returned an invalid list');
  }

  void close() => _transport.close();
}
