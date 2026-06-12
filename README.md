# TheEcommerce

[![CI](https://github.com/BaduDueduMaxwell/TheEcommerce/actions/workflows/ci.yml/badge.svg)](https://github.com/BaduDueduMaxwell/TheEcommerce/actions/workflows/ci.yml)

TheEcommerce is a full-stack ecommerce project with a Flutter app, a
reusable Dart SDK, and an Express API. Customers can browse products, manage a
cart, place orders, and continue to Paystack checkout. Admin users can manage
the catalogue from the same mobile app.

The repository began as a Node.js API and now includes the mobile client and SDK
needed to support the complete purchase flow.

## What Works

### Customer app

- Registration and login with secure token storage
- Product search, categories, sorting, pagination, and pull-to-refresh
- Product details with prices and stock status
- Cart quantity limits based on current stock
- Server-calculated order totals
- Paystack checkout handoff
- Order history
- Loading, empty, validation, and connection error states

### Admin tools

- Admin-only product management
- Create, edit, restock, and delete products
- Image URL preview and form validation
- Confirmation prompts and operation feedback
- Server-side role checks on every product mutation

### Engineering

- Typed Dart client in `packages/commerce_sdk`
- API calls kept outside Flutter widgets
- Pluggable SDK transport and token storage
- Retry handling for network and server failures
- Batched analytics with duplicate-event protection
- Signed Paystack webhook verification
- Automated Node, Dart, and Flutter checks in GitHub Actions

## Architecture

```text
Flutter app
    |
    v
commerce_sdk
    |
    v
Express API ---- MongoDB
    |
    +------------ Paystack
```

```text
.
├── controllers/              Express request handlers
├── middlewares/              Authentication and authorization
├── models/                   Mongoose models
├── routes/                   API routes
├── scripts/                  Product seed and admin promotion
├── packages/commerce_sdk/    Reusable Dart client
├── mobile_app/               Flutter app for Android and iOS
└── test/                     Backend unit tests
```

## Requirements

- Node.js 20 or later
- MongoDB, local or hosted
- Flutter 3.41.6 or compatible
- Paystack test credentials for checkout

## Setup

The API and Flutter app run in separate terminals.

### 1. Configure the API

```bash
cd ~/Desktop/TheEcommerce
cp .env.example .env
```

Set the following values in `.env`:

```dotenv
PORT=3000
NODE_ENV=development
MONGODB_URI=mongodb://127.0.0.1:27017/theecommerce
JWT_SECRET=replace-with-a-long-random-secret
JWT_EXPIRES_IN=1h
PAYSTACK_SECRET_KEY=sk_test_replace_me
```

Install dependencies, seed the catalogue, and start the server:

```bash
npm ci
npm run seed
npm run dev
```

The seed command adds 12 products across footwear, electronics, bags,
accessories, apparel, and home. It can be run again without creating duplicate
products.

Check that the API is running:

```bash
curl http://localhost:3000/health
```

### 2. Run the iOS app

In a second terminal:

```bash
cd ~/Desktop/TheEcommerce/mobile_app
/Users/macbookprom1/Downloads/flutter/bin/flutter pub get
/Users/macbookprom1/Downloads/flutter/bin/flutter run \
  -d "iPhone 17" \
  --dart-define=API_BASE_URL=http://localhost:3000
```

For Android Emulator:

```bash
/Users/macbookprom1/Downloads/flutter/bin/flutter run \
  --dart-define=API_BASE_URL=http://10.0.2.2:3000
```

For a physical phone, use the computer's LAN address or a deployed HTTPS API.

## Admin Demo

Signup never accepts an admin role from the client. To test product management:

1. Create a normal account in the app.
2. Promote that account from the backend directory:

```bash
cd ~/Desktop/TheEcommerce
npm run promote-admin -- your-email@example.com
```

3. Sign out and sign in again to receive a new JWT.
4. Open the inventory icon in the app bar.

The promotion script is disabled when `NODE_ENV=production`.

## Product API

Public endpoints:

```text
GET /api/products
GET /api/products/:productId
```

Admin endpoints:

```text
POST   /api/products
PUT    /api/products/:productId
PATCH  /api/products/:productId
DELETE /api/products/:productId
```

Product list query parameters:

| Parameter | Description |
| --- | --- |
| `page` | Page number, starting at 1 |
| `limit` | Results per page, maximum 50 |
| `search` | Match name, description, or category |
| `category` | Exact category match |
| `sort` | `newest`, `name`, `price_asc`, `price_desc`, or `stock_desc` |

Example response:

```json
{
  "items": [],
  "page": 1,
  "limit": 12,
  "total": 0,
  "totalPages": 1,
  "categories": [],
  "sort": "newest"
}
```

## SDK Usage

```dart
final client = CommerceClient(
  baseUrl: 'https://api.example.com',
  tokenStore: SecureTokenStore(),
);

final page = await client.getProductPage(
  query: const ProductQuery(
    search: 'headphones',
    category: 'Electronics',
    sort: ProductSort.priceLowToHigh,
  ),
);

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

Flutter screens use typed SDK operations rather than making HTTP requests
directly.

## Tests

Backend:

```bash
cd ~/Desktop/TheEcommerce
npm test
```

Dart SDK:

```bash
cd ~/Desktop/TheEcommerce/packages/commerce_sdk
/Users/macbookprom1/Downloads/flutter/bin/dart format --output=none --set-exit-if-changed .
/Users/macbookprom1/Downloads/flutter/bin/dart analyze
/Users/macbookprom1/Downloads/flutter/bin/dart test
```

Flutter:

```bash
cd ~/Desktop/TheEcommerce/mobile_app
/Users/macbookprom1/Downloads/flutter/bin/dart format --output=none --set-exit-if-changed .
/Users/macbookprom1/Downloads/flutter/bin/flutter analyze
/Users/macbookprom1/Downloads/flutter/bin/flutter test
```

## Security Notes

- Signup always creates a normal user.
- Product writes require a verified admin JWT.
- User-owned resources are checked before cart, order, and payment operations.
- Prices and checkout totals are read from MongoDB instead of client input.
- Product input is allow-listed and validated before storage.
- Webhook signatures are checked against the original request body.
- Secrets and mobile tokens are excluded from Git.

## Known Limits

This project does not yet include inventory reservations, refresh tokens, rate
limiting, background payment reconciliation, or persistent offline analytics.

## License

ISC
