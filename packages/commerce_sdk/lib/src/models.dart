double _number(Object? value) => (value as num).toDouble();

class CommerceUser {
  const CommerceUser({
    required this.id,
    required this.username,
    required this.name,
    required this.email,
    required this.role,
  });

  factory CommerceUser.fromJson(Map<String, Object?> json) => CommerceUser(
    id: json['_id'] as String,
    username: json['username'] as String,
    name: json['name'] as String,
    email: json['email'] as String,
    role: (json['role'] as String?) ?? 'user',
  );

  final String id;
  final String username;
  final String name;
  final String email;
  final String role;
}

class AuthSession {
  const AuthSession({required this.token, required this.user});

  final String token;
  final CommerceUser user;
}

class Product {
  const Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    this.imageUrl,
    this.category,
    this.createdAt,
    this.updatedAt,
  });

  factory Product.fromJson(Map<String, Object?> json) => Product(
    id: json['_id'] as String,
    name: json['name'] as String,
    description: json['description'] as String,
    price: _number(json['price']),
    stock: (json['stock'] as num).toInt(),
    imageUrl: json['imageURL'] as String?,
    category: json['category'] as String?,
    createdAt: DateTime.tryParse(json['createdAt'] as String? ?? ''),
    updatedAt: DateTime.tryParse(json['updatedAt'] as String? ?? ''),
  );

  final String id;
  final String name;
  final String description;
  final double price;
  final int stock;
  final String? imageUrl;
  final String? category;
  final DateTime? createdAt;
  final DateTime? updatedAt;
}

enum ProductSort {
  newest('newest'),
  name('name'),
  priceLowToHigh('price_asc'),
  priceHighToLow('price_desc'),
  stockHighToLow('stock_desc');

  const ProductSort(this.apiValue);

  final String apiValue;
}

class ProductQuery {
  const ProductQuery({
    this.page = 1,
    this.limit = 12,
    this.search,
    this.category,
    this.sort = ProductSort.newest,
  });

  final int page;
  final int limit;
  final String? search;
  final String? category;
  final ProductSort sort;

  Map<String, String> toQueryParameters() => {
    'page': '$page',
    'limit': '$limit',
    'sort': sort.apiValue,
    if (search != null && search!.trim().isNotEmpty) 'search': search!.trim(),
    if (category != null && category!.trim().isNotEmpty)
      'category': category!.trim(),
  };
}

class ProductPage {
  const ProductPage({
    required this.items,
    required this.page,
    required this.limit,
    required this.total,
    required this.totalPages,
    required this.categories,
    required this.sort,
  });

  factory ProductPage.fromJson(Map<String, Object?> json) => ProductPage(
    items: (json['items'] as List<Object?>)
        .map((item) => Product.fromJson(item as Map<String, Object?>))
        .toList(growable: false),
    page: (json['page'] as num).toInt(),
    limit: (json['limit'] as num).toInt(),
    total: (json['total'] as num).toInt(),
    totalPages: (json['totalPages'] as num).toInt(),
    categories: (json['categories'] as List<Object?>)
        .map((category) => category as String)
        .toList(growable: false),
    sort: json['sort'] as String,
  );

  final List<Product> items;
  final int page;
  final int limit;
  final int total;
  final int totalPages;
  final List<String> categories;
  final String sort;
}

class ProductInput {
  const ProductInput({
    required this.name,
    required this.description,
    required this.price,
    required this.stock,
    required this.category,
    required this.imageUrl,
  });

  final String name;
  final String description;
  final double price;
  final int stock;
  final String category;
  final String imageUrl;

  Map<String, Object> toJson() => {
    'name': name.trim(),
    'description': description.trim(),
    'price': price,
    'stock': stock,
    'category': category.trim(),
    'imageURL': imageUrl.trim(),
  };
}

class CartItemInput {
  const CartItemInput({required this.productId, required this.quantity});

  final String productId;
  final int quantity;

  Map<String, Object> toJson() => {
    'productId': productId,
    'quantity': quantity,
  };
}

class Cart {
  const Cart({
    required this.id,
    required this.userId,
    required this.items,
    required this.totalPrice,
  });

  factory Cart.fromJson(Map<String, Object?> json) => Cart(
    id: json['_id'] as String,
    userId: json['userId'] as String,
    items: (json['items'] as List<Object?>)
        .map((item) => CartLine.fromJson(item as Map<String, Object?>))
        .toList(growable: false),
    totalPrice: _number(json['totalPrice']),
  );

  final String id;
  final String userId;
  final List<CartLine> items;
  final double totalPrice;
}

class CartLine {
  const CartLine({required this.productId, required this.quantity});

  factory CartLine.fromJson(Map<String, Object?> json) => CartLine(
    productId: json['productId'] as String,
    quantity: (json['quantity'] as num).toInt(),
  );

  final String productId;
  final int quantity;
}

class ShippingAddress {
  const ShippingAddress({
    required this.street,
    required this.city,
    required this.postalCode,
    required this.country,
  });

  final String street;
  final String city;
  final String postalCode;
  final String country;

  Map<String, Object> toJson() => {
    'street': street,
    'city': city,
    'postalCode': postalCode,
    'country': country,
  };
}

class Order {
  const Order({
    required this.id,
    required this.totalAmount,
    required this.status,
    required this.paymentStatus,
  });

  factory Order.fromJson(Map<String, Object?> json) => Order(
    id: json['_id'] as String,
    totalAmount: _number(json['totalAmount']),
    status: json['status'] as String,
    paymentStatus: json['paymentStatus'] as String,
  );

  final String id;
  final double totalAmount;
  final String status;
  final String paymentStatus;
}

class PaymentSession {
  const PaymentSession({
    required this.authorizationUrl,
    required this.reference,
  });

  factory PaymentSession.fromJson(Map<String, Object?> json) => PaymentSession(
    authorizationUrl: json['paymentUrl'] as String,
    reference: json['reference'] as String,
  );

  final String authorizationUrl;
  final String reference;
}

class AnalyticsEvent {
  const AnalyticsEvent({
    required this.eventId,
    required this.name,
    required this.occurredAt,
    required this.properties,
    this.platform,
    this.appVersion,
  });

  final String eventId;
  final String name;
  final DateTime occurredAt;
  final Map<String, Object?> properties;
  final String? platform;
  final String? appVersion;

  Map<String, Object?> toJson() => {
    'eventId': eventId,
    'name': name,
    'occurredAt': occurredAt.toUtc().toIso8601String(),
    'properties': properties,
    if (platform != null) 'platform': platform,
    if (appVersion != null) 'appVersion': appVersion,
  };
}
