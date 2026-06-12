import 'dart:async';

import 'package:commerce_sdk/commerce_sdk.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../controllers/product_catalog_controller.dart';
import 'admin_product_screen.dart';

class CatalogScreen extends StatefulWidget {
  const CatalogScreen({
    required this.client,
    required this.session,
    required this.onLogout,
    super.key,
  });

  final CommerceClient client;
  final AuthSession session;
  final Future<void> Function() onLogout;

  @override
  State<CatalogScreen> createState() => _CatalogScreenState();
}

class _CatalogScreenState extends State<CatalogScreen> {
  late final ProductCatalogController _catalog;
  final Map<String, int> _cart = {};
  final Map<String, Product> _cartProducts = {};

  int get _cartCount => _cart.values.fold(0, (total, value) => total + value);

  @override
  void initState() {
    super.initState();
    _catalog = ProductCatalogController(client: widget.client)..load();
  }

  @override
  void dispose() {
    _catalog.dispose();
    super.dispose();
  }

  void _addToCart(Product product) {
    final quantity = _cart[product.id] ?? 0;
    if (quantity >= product.stock) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Only ${product.stock} left')));
      return;
    }

    setState(() {
      _cart[product.id] = quantity + 1;
      _cartProducts[product.id] = product;
    });
    unawaited(
      widget.client.track(
        name: 'add_to_cart',
        properties: {'productId': product.id, 'price': product.price},
        platform: Theme.of(context).platform.name,
        appVersion: '1.0.0',
      ),
    );
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('${product.name} added to cart')));
  }

  Future<void> _showProduct(Product product) async {
    unawaited(
      widget.client.track(
        name: 'product_viewed',
        properties: {'productId': product.id},
        platform: Theme.of(context).platform.name,
        appVersion: '1.0.0',
      ),
    );
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => _ProductDetails(
        product: product,
        onAdd: () {
          Navigator.pop(context);
          _addToCart(product);
        },
      ),
    );
  }

  Future<void> _openCart() async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => StatefulBuilder(
        builder: (context, setSheetState) {
          final products = _cartProducts.values
              .where((product) => (_cart[product.id] ?? 0) > 0)
              .toList(growable: false);
          final total = products.fold<double>(
            0,
            (sum, product) => sum + product.price * (_cart[product.id] ?? 0),
          );

          void updateQuantity(Product product, int quantity) {
            setState(() {
              if (quantity <= 0) {
                _cart.remove(product.id);
                _cartProducts.remove(product.id);
              } else {
                _cart[product.id] = quantity.clamp(1, product.stock);
              }
            });
            setSheetState(() {});
          }

          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Your cart',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.w800),
                      ),
                    ),
                    IconButton(
                      tooltip: 'Close',
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                if (products.isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 48),
                    child: Column(
                      children: [
                        Icon(Icons.shopping_cart_outlined, size: 48),
                        SizedBox(height: 12),
                        Text('Your cart is empty'),
                      ],
                    ),
                  )
                else
                  Flexible(
                    child: ListView.separated(
                      shrinkWrap: true,
                      itemCount: products.length,
                      separatorBuilder: (_, _) => const Divider(height: 24),
                      itemBuilder: (context, index) {
                        final product = products[index];
                        final quantity = _cart[product.id] ?? 0;
                        return Row(
                          children: [
                            SizedBox.square(
                              dimension: 64,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(6),
                                child: _ProductImage(product: product),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'GHS ${product.price.toStringAsFixed(2)}',
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              tooltip: 'Decrease quantity',
                              onPressed: () =>
                                  updateQuantity(product, quantity - 1),
                              icon: const Icon(Icons.remove_circle_outline),
                            ),
                            Text(
                              '$quantity',
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Increase quantity',
                              onPressed: quantity >= product.stock
                                  ? null
                                  : () => updateQuantity(product, quantity + 1),
                              icon: const Icon(Icons.add_circle_outline),
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                const Divider(height: 28),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    Text(
                      'GHS ${total.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: products.isEmpty
                      ? null
                      : () {
                          Navigator.pop(context);
                          _showCheckout();
                        },
                  child: const Text('Continue to checkout'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCheckout() async {
    final platform = Theme.of(context).platform.name;

    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => _CheckoutDialog(
        onSubmit: (shippingAddress) async {
          final order = await widget.client.placeOrder(
            items: _cart.entries
                .map(
                  (entry) => CartItemInput(
                    productId: entry.key,
                    quantity: entry.value,
                  ),
                )
                .toList(),
            shippingAddress: shippingAddress,
          );
          final payment = await widget.client.initializePayment(
            orderId: order.id,
            email: widget.session.user.email,
          );
          final opened = await launchUrl(
            Uri.parse(payment.authorizationUrl),
            mode: LaunchMode.externalApplication,
          );
          if (!opened) {
            throw const CommerceException('Could not open the payment page');
          }

          unawaited(_trackCheckout(order, platform));
          _cart.clear();
          _cartProducts.clear();
          if (mounted) {
            setState(() {});
          }
        },
      ),
    );
  }

  Future<void> _trackCheckout(Order order, String platform) async {
    try {
      await widget.client.track(
        name: 'checkout_started',
        properties: {'orderId': order.id, 'amount': order.totalAmount},
        platform: platform,
        appVersion: '1.0.0',
      );
      await widget.client.flushEvents();
    } on CommerceException {
      // Telemetry must never block the purchase flow.
    }
  }

  void _showOrders() {
    showModalBottomSheet<void>(
      context: context,
      useSafeArea: true,
      builder: (context) => FutureBuilder<List<Order>>(
        future: widget.client.getOrders(widget.session.user.id),
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const _MessageState(
              icon: Icons.receipt_long_outlined,
              title: 'Could not load orders',
              message: 'Check your connection and try again.',
            );
          }
          final orders = snapshot.data ?? const <Order>[];
          if (orders.isEmpty) {
            return const _MessageState(
              icon: Icons.receipt_long_outlined,
              title: 'No orders yet',
              message: 'Your purchases will appear here.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              Text(
                'Order history',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 16),
              for (final order in orders)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    child: Icon(Icons.local_shipping_outlined),
                  ),
                  title: Text('Order ${order.id.substring(0, 8)}'),
                  subtitle: Text('${order.status} · ${order.paymentStatus}'),
                  trailing: Text(
                    'GHS ${order.totalAmount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Future<void> _openAdmin() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (context) => AdminProductScreen(client: widget.client),
      ),
    );
    await _catalog.load(refresh: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _catalog,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text(
              'Everything Store',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
            actions: [
              if (widget.session.user.role == 'admin')
                IconButton(
                  tooltip: 'Manage products',
                  onPressed: _openAdmin,
                  icon: const Icon(Icons.inventory_2_outlined),
                ),
              IconButton(
                tooltip: 'Order history',
                onPressed: _showOrders,
                icon: const Icon(Icons.receipt_long_outlined),
              ),
              IconButton(
                tooltip: 'Sign out',
                onPressed: widget.onLogout,
                icon: const Icon(Icons.logout),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: RefreshIndicator(
            onRefresh: () => _catalog.load(refresh: true),
            child: CustomScrollView(
              physics: const BouncingScrollPhysics(
                parent: AlwaysScrollableScrollPhysics(),
              ),
              slivers: [
                SliverToBoxAdapter(
                  child: _StoreHeader(
                    userName: widget.session.user.name,
                    catalog: _catalog,
                  ),
                ),
                if (_catalog.isLoading && _catalog.products.isEmpty)
                  const SliverPadding(
                    padding: EdgeInsets.all(16),
                    sliver: _ProductLoadingGrid(),
                  )
                else if (_catalog.error != null && _catalog.products.isEmpty)
                  SliverFillRemaining(
                    hasScrollBody: false,
                    child: _CatalogErrorState(
                      message: _catalog.error!,
                      onRetry: _catalog.load,
                    ),
                  )
                else if (_catalog.products.isEmpty)
                  const SliverFillRemaining(
                    hasScrollBody: false,
                    child: _MessageState(
                      icon: Icons.search_off_outlined,
                      title: 'No products found',
                      message: 'Try a different search or category.',
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
                    sliver: _ProductGrid(
                      products: _catalog.products,
                      onAdd: _addToCart,
                      onOpen: _showProduct,
                    ),
                  ),
                if (_catalog.canLoadMore)
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                      child: Center(
                        child: OutlinedButton.icon(
                          onPressed: _catalog.isLoadingMore
                              ? null
                              : _catalog.loadMore,
                          icon: _catalog.isLoadingMore
                              ? const SizedBox.square(
                                  dimension: 16,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                  ),
                                )
                              : const Icon(Icons.expand_more),
                          label: const Text('Load more'),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          floatingActionButton: FloatingActionButton.extended(
            onPressed: _openCart,
            icon: Badge(
              isLabelVisible: _cartCount > 0,
              label: Text('$_cartCount'),
              child: const Icon(Icons.shopping_cart_outlined),
            ),
            label: const Text('Cart'),
          ),
        );
      },
    );
  }
}

class _StoreHeader extends StatelessWidget {
  const _StoreHeader({required this.userName, required this.catalog});

  final String userName;
  final ProductCatalogController catalog;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Hello, ${userName.split(' ').first}',
            style: Theme.of(
              context,
            ).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 4),
          Text(
            'Find something worth keeping.',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            onChanged: catalog.setSearch,
            decoration: const InputDecoration(
              hintText: 'Search products',
              prefixIcon: Icon(Icons.search),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      ChoiceChip(
                        label: const Text('All'),
                        selected: catalog.category == null,
                        onSelected: (_) => catalog.setCategory(null),
                      ),
                      for (final category in catalog.categories) ...[
                        const SizedBox(width: 8),
                        ChoiceChip(
                          label: Text(category),
                          selected: catalog.category == category,
                          onSelected: (_) => catalog.setCategory(category),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              PopupMenuButton<ProductSort>(
                tooltip: 'Sort products',
                initialValue: catalog.sort,
                onSelected: catalog.setSort,
                itemBuilder: (context) => const [
                  PopupMenuItem(
                    value: ProductSort.newest,
                    child: Text('Newest'),
                  ),
                  PopupMenuItem(value: ProductSort.name, child: Text('Name')),
                  PopupMenuItem(
                    value: ProductSort.priceLowToHigh,
                    child: Text('Price: low to high'),
                  ),
                  PopupMenuItem(
                    value: ProductSort.priceHighToLow,
                    child: Text('Price: high to low'),
                  ),
                ],
                icon: const Icon(Icons.sort),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CheckoutDialog extends StatefulWidget {
  const _CheckoutDialog({required this.onSubmit});

  final Future<void> Function(ShippingAddress shippingAddress) onSubmit;

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  final _formKey = GlobalKey<FormState>();
  final _street = TextEditingController();
  final _city = TextEditingController();
  final _postalCode = TextEditingController();
  final _country = TextEditingController(text: 'Ghana');
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _street.dispose();
    _city.dispose();
    _postalCode.dispose();
    _country.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      await widget.onSubmit(
        ShippingAddress(
          street: _street.text.trim(),
          city: _city.text.trim(),
          postalCode: _postalCode.text.trim(),
          country: _country.text.trim(),
        ),
      );
      if (mounted) {
        Navigator.pop(context);
      }
    } on CommerceException catch (error) {
      if (mounted) {
        setState(() {
          _error = error.message;
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Shipping details'),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (final field in [
                (_street, 'Street'),
                (_city, 'City'),
                (_postalCode, 'Postal code'),
                (_country, 'Country'),
              ]) ...[
                TextFormField(
                  controller: field.$1,
                  decoration: InputDecoration(labelText: field.$2),
                  validator: (value) =>
                      value == null || value.trim().isEmpty ? 'Required' : null,
                ),
                const SizedBox(height: 12),
              ],
              if (_error != null)
                Text(
                  _error!,
                  style: TextStyle(color: Theme.of(context).colorScheme.error),
                ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox.square(
                  dimension: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Pay with Paystack'),
        ),
      ],
    );
  }
}

class _ProductGrid extends StatelessWidget {
  const _ProductGrid({
    required this.products,
    required this.onAdd,
    required this.onOpen,
  });

  final List<Product> products;
  final ValueChanged<Product> onAdd;
  final ValueChanged<Product> onOpen;

  @override
  Widget build(BuildContext context) {
    return SliverLayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.crossAxisExtent;
        final columns = width >= 1000
            ? 4
            : width >= 680
            ? 3
            : 2;

        return SliverGrid.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: width < 420 ? 0.61 : 0.67,
          ),
          itemCount: products.length,
          itemBuilder: (context, index) {
            final product = products[index];
            return Material(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(8),
              clipBehavior: Clip.antiAlias,
              child: InkWell(
                onTap: () => onOpen(product),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          _ProductImage(product: product),
                          Positioned(
                            top: 8,
                            left: 8,
                            child: _StockBadge(stock: product.stock),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            product.category ?? 'Uncategorized',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.labelMedium
                                ?.copyWith(
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 5),
                          Text(
                            'GHS ${product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 10),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.tonalIcon(
                              onPressed: product.stock > 0
                                  ? () => onAdd(product)
                                  : null,
                              icon: const Icon(
                                Icons.add_shopping_cart,
                                size: 18,
                              ),
                              label: Text(
                                product.stock > 0 ? 'Add' : 'Out of stock',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}

class _ProductDetails extends StatelessWidget {
  const _ProductDetails({required this.product, required this.onAdd});

  final Product product;
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          AspectRatio(
            aspectRatio: 1.25,
            child: Stack(
              fit: StackFit.expand,
              children: [
                _ProductImage(product: product),
                Positioned(
                  top: 12,
                  right: 12,
                  child: IconButton.filledTonal(
                    tooltip: 'Close',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.category ?? 'Uncategorized',
                  style: Theme.of(context).textTheme.labelLarge?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  product.name,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'GHS ${product.price.toStringAsFixed(2)}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 16),
                Text(product.description),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: product.stock > 0 ? onAdd : null,
                    icon: const Icon(Icons.add_shopping_cart),
                    label: Text(
                      product.stock > 0
                          ? 'Add to cart · ${product.stock} available'
                          : 'Out of stock',
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    if (product.imageUrl == null || product.imageUrl!.isEmpty) {
      return const ColoredBox(
        color: Color(0xFFE8ECF4),
        child: Icon(Icons.inventory_2_outlined, size: 42),
      );
    }
    return Image.network(
      product.imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFFE8ECF4),
        child: Icon(Icons.broken_image_outlined, size: 42),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  const _StockBadge({required this.stock});

  final int stock;

  @override
  Widget build(BuildContext context) {
    final low = stock > 0 && stock <= 5;
    final label = stock == 0
        ? 'Sold out'
        : low
        ? 'Only $stock left'
        : 'In stock';
    return DecoratedBox(
      decoration: BoxDecoration(
        color: stock == 0 || low
            ? Theme.of(context).colorScheme.errorContainer
            : Theme.of(context).colorScheme.secondaryContainer,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        child: Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}

class _ProductLoadingGrid extends StatelessWidget {
  const _ProductLoadingGrid();

  @override
  Widget build(BuildContext context) {
    return SliverGrid.builder(
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.67,
      ),
      itemCount: 6,
      itemBuilder: (context, index) => DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _CatalogErrorState extends StatelessWidget {
  const _CatalogErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined, size: 52),
            const SizedBox(height: 12),
            const Text(
              'Could not load products',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 14),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

class _MessageState extends StatelessWidget {
  const _MessageState({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 52),
            const SizedBox(height: 12),
            Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
            const SizedBox(height: 5),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
