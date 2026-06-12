import 'package:commerce_sdk/commerce_sdk.dart';

Future<void> main() async {
  final client = CommerceClient(baseUrl: 'http://localhost:3000');
  final products = await client.getProducts();
  print('Loaded ${products.length} products');
  client.close();
}
