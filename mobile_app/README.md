# TheEcommerce Mobile App

The Flutter storefront for TheEcommerce. It uses the local
[`commerce_sdk`](../packages/commerce_sdk) package for authentication, product
discovery, cart checkout, orders, analytics, and admin product management.

## Run locally

Start the API from the repository root first:

```bash
cd ~/Desktop/TheEcommerce
npm run dev
```

Then run the iOS app:

```bash
cd ~/Desktop/TheEcommerce/mobile_app
/Users/macbookprom1/Downloads/flutter/bin/flutter pub get
/Users/macbookprom1/Downloads/flutter/bin/flutter run \
  -d "iPhone 17" \
  --dart-define=API_BASE_URL=http://localhost:3000
```

For Android Emulator, use `http://10.0.2.2:3000` as the API URL.

## Checks

```bash
/Users/macbookprom1/Downloads/flutter/bin/dart format --output=none --set-exit-if-changed .
/Users/macbookprom1/Downloads/flutter/bin/flutter analyze
/Users/macbookprom1/Downloads/flutter/bin/flutter test
```
