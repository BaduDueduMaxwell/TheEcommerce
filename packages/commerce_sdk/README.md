# commerce_sdk

A typed Dart client for TheEcommerce API.

## Features

- Authentication and pluggable token storage
- Paginated product discovery and admin product CRUD
- Carts, orders, and Paystack payment sessions
- Structured API errors
- Retry handling for transient failures
- Batched, duplicate-safe analytics events
- Injectable transport for deterministic tests

## Example

```dart
final client = CommerceClient(
  baseUrl: 'https://api.example.com',
  tokenStore: MemoryTokenStore(),
);

final session = await client.login(
  email: 'developer@example.com',
  password: 'secret',
);

final page = await client.getProductPage(
  query: const ProductQuery(
    category: 'Electronics',
    sort: ProductSort.priceLowToHigh,
  ),
);
await client.track(
  name: 'product_viewed',
  properties: {'productId': page.items.first.id},
);
```

Admin sessions can create and update products through typed input:

```dart
await client.createProduct(
  const ProductInput(
    name: 'Studio Headphones',
    description: 'Comfortable wireless headphones with clear sound.',
    price: 950,
    stock: 12,
    category: 'Electronics',
    imageUrl: 'https://example.com/headphones.jpg',
  ),
);
```

Applications should provide persistent, secure token storage. The Flutter app
uses `flutter_secure_storage`.

## Verification

```bash
dart format --output=none --set-exit-if-changed .
dart analyze
dart test
```
