import 'package:commerce_sdk/commerce_sdk.dart';
import 'package:flutter/material.dart';

class AdminProductScreen extends StatefulWidget {
  const AdminProductScreen({required this.client, super.key});

  final CommerceClient client;

  @override
  State<AdminProductScreen> createState() => _AdminProductScreenState();
}

class _AdminProductScreenState extends State<AdminProductScreen> {
  late Future<ProductPage> _products;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    setState(() {
      _products = widget.client.getProductPage(
        query: const ProductQuery(limit: 50, sort: ProductSort.name),
      );
    });
  }

  Future<void> _openForm([Product? product]) async {
    final input = await showModalBottomSheet<ProductInput>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => ProductFormSheet(product: product),
    );
    if (input == null || !mounted) {
      return;
    }

    try {
      if (product == null) {
        await widget.client.createProduct(input);
      } else {
        await widget.client.updateProduct(product.id, input);
      }
      if (!mounted) {
        return;
      }
      _reload();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            product == null ? 'Product created' : 'Product updated',
          ),
        ),
      );
    } on CommerceException catch (error) {
      if (mounted) {
        _showError(error.message);
      }
    }
  }

  Future<void> _restock(Product product) async {
    var stockValue = product.stock;
    final stock = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Restock ${product.name}'),
        content: TextFormField(
          initialValue: '${product.stock}',
          autofocus: true,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Available stock'),
          onChanged: (value) {
            stockValue = int.tryParse(value) ?? -1;
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (stockValue >= 0) {
                Navigator.pop(context, stockValue);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );

    if (stock == null) {
      return;
    }
    try {
      await widget.client.restockProduct(product.id, stock);
      if (mounted) {
        _reload();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Stock updated')));
      }
    } on CommerceException catch (error) {
      if (mounted) {
        _showError(error.message);
      }
    }
  }

  Future<void> _delete(Product product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete product?'),
        content: Text(
          '${product.name} will be removed from the storefront. This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed != true) {
      return;
    }
    try {
      await widget.client.deleteProduct(product.id);
      if (mounted) {
        _reload();
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Product deleted')));
      }
    } on CommerceException catch (error) {
      if (mounted) {
        _showError(error.message);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Inventory'),
        actions: [
          IconButton(
            tooltip: 'Refresh products',
            onPressed: _reload,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: FutureBuilder<ProductPage>(
        future: _products,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const _AdminLoadingState();
          }
          if (snapshot.hasError) {
            return _AdminErrorState(onRetry: _reload);
          }

          final products = snapshot.data?.items ?? const <Product>[];
          if (products.isEmpty) {
            return _AdminEmptyState(onCreate: _openForm);
          }

          return LayoutBuilder(
            builder: (context, constraints) {
              final wide = constraints.maxWidth >= 720;
              if (wide) {
                return GridView.builder(
                  padding: const EdgeInsets.all(24),
                  gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                    maxCrossAxisExtent: 520,
                    mainAxisExtent: 150,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  itemCount: products.length,
                  itemBuilder: (context, index) => _AdminProductTile(
                    product: products[index],
                    onEdit: () => _openForm(products[index]),
                    onRestock: () => _restock(products[index]),
                    onDelete: () => _delete(products[index]),
                  ),
                );
              }
              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: products.length,
                separatorBuilder: (_, _) => const SizedBox(height: 12),
                itemBuilder: (context, index) => _AdminProductTile(
                  product: products[index],
                  onEdit: () => _openForm(products[index]),
                  onRestock: () => _restock(products[index]),
                  onDelete: () => _delete(products[index]),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openForm,
        icon: const Icon(Icons.add),
        label: const Text('Add product'),
      ),
    );
  }
}

class ProductFormSheet extends StatefulWidget {
  const ProductFormSheet({this.product, super.key});

  final Product? product;

  @override
  State<ProductFormSheet> createState() => _ProductFormSheetState();
}

class _ProductFormSheetState extends State<ProductFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _description;
  late final TextEditingController _price;
  late final TextEditingController _stock;
  late final TextEditingController _category;
  late final TextEditingController _imageUrl;

  @override
  void initState() {
    super.initState();
    final product = widget.product;
    _name = TextEditingController(text: product?.name);
    _description = TextEditingController(text: product?.description);
    _price = TextEditingController(
      text: product == null ? '' : product.price.toStringAsFixed(2),
    );
    _stock = TextEditingController(
      text: product == null ? '' : '${product.stock}',
    );
    _category = TextEditingController(text: product?.category);
    _imageUrl = TextEditingController(text: product?.imageUrl)
      ..addListener(_refreshPreview);
  }

  void _refreshPreview() {
    setState(() {});
  }

  @override
  void dispose() {
    _imageUrl.removeListener(_refreshPreview);
    _name.dispose();
    _description.dispose();
    _price.dispose();
    _stock.dispose();
    _category.dispose();
    _imageUrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }
    Navigator.pop(
      context,
      ProductInput(
        name: _name.text,
        description: _description.text,
        price: double.parse(_price.text),
        stock: int.parse(_stock.text),
        category: _category.text,
        imageUrl: _imageUrl.text,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final imageUri = Uri.tryParse(_imageUrl.text);
    final canPreview =
        imageUri != null &&
        (imageUri.scheme == 'http' || imageUri.scheme == 'https');

    return Padding(
      padding: EdgeInsets.fromLTRB(20, 12, 20, bottomInset + 20),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.product == null ? 'Add product' : 'Edit product',
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
              AspectRatio(
                aspectRatio: 16 / 8,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: ColoredBox(
                    color: Theme.of(
                      context,
                    ).colorScheme.surfaceContainerHighest,
                    child: canPreview
                        ? Image.network(
                            _imageUrl.text,
                            fit: BoxFit.cover,
                            errorBuilder: (_, _, _) => const Center(
                              child: Icon(
                                Icons.broken_image_outlined,
                                size: 40,
                              ),
                            ),
                          )
                        : const Center(
                            child: Icon(Icons.image_outlined, size: 40),
                          ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _name,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Product name'),
                validator: (value) => _required(value, minLength: 2),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _description,
                minLines: 3,
                maxLines: 5,
                decoration: const InputDecoration(labelText: 'Description'),
                validator: (value) => _required(value, minLength: 10),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      decoration: const InputDecoration(
                        labelText: 'Price',
                        prefixText: 'GHS ',
                      ),
                      validator: (value) {
                        final parsed = double.tryParse(value ?? '');
                        return parsed == null || parsed < 0
                            ? 'Enter a valid price'
                            : null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _stock,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(labelText: 'Stock'),
                      validator: (value) {
                        final parsed = int.tryParse(value ?? '');
                        return parsed == null || parsed < 0
                            ? 'Enter valid stock'
                            : null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _category,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(labelText: 'Category'),
                validator: _required,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _imageUrl,
                keyboardType: TextInputType.url,
                decoration: const InputDecoration(labelText: 'Image URL'),
                validator: (value) {
                  final uri = Uri.tryParse(value ?? '');
                  if (uri == null ||
                      (uri.scheme != 'http' && uri.scheme != 'https')) {
                    return 'Enter a valid HTTP or HTTPS URL';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: _submit,
                icon: const Icon(Icons.save_outlined),
                label: Text(
                  widget.product == null ? 'Create product' : 'Save changes',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String? _required(String? value, {int minLength = 1}) {
    if (value == null || value.trim().length < minLength) {
      return minLength == 1
          ? 'This field is required'
          : 'Use at least $minLength characters';
    }
    return null;
  }
}

class _AdminProductTile extends StatelessWidget {
  const _AdminProductTile({
    required this.product,
    required this.onEdit,
    required this.onRestock,
    required this.onDelete,
  });

  final Product product;
  final VoidCallback onEdit;
  final VoidCallback onRestock;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).colorScheme.surface,
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onEdit,
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              SizedBox.square(
                dimension: 86,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: _ProductImage(product: product),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      product.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.category} · GHS ${product.price.toStringAsFixed(2)}',
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${product.stock} in stock',
                      style: TextStyle(
                        color: product.stock <= 5
                            ? Theme.of(context).colorScheme.error
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                tooltip: 'Product actions',
                onSelected: (value) {
                  switch (value) {
                    case 'edit':
                      onEdit();
                    case 'restock':
                      onRestock();
                    case 'delete':
                      onDelete();
                  }
                },
                itemBuilder: (context) => const [
                  PopupMenuItem(value: 'edit', child: Text('Edit')),
                  PopupMenuItem(value: 'restock', child: Text('Restock')),
                  PopupMenuItem(value: 'delete', child: Text('Delete')),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProductImage extends StatelessWidget {
  const _ProductImage({required this.product});

  final Product product;

  @override
  Widget build(BuildContext context) {
    if (product.imageUrl == null) {
      return const ColoredBox(
        color: Color(0xFFE8ECF4),
        child: Icon(Icons.inventory_2_outlined),
      );
    }
    return Image.network(
      product.imageUrl!,
      fit: BoxFit.cover,
      errorBuilder: (_, _, _) => const ColoredBox(
        color: Color(0xFFE8ECF4),
        child: Icon(Icons.broken_image_outlined),
      ),
    );
  }
}

class _AdminLoadingState extends StatelessWidget {
  const _AdminLoadingState();

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: 6,
      separatorBuilder: (_, _) => const SizedBox(height: 12),
      itemBuilder: (_, _) => Container(
        height: 110,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }
}

class _AdminErrorState extends StatelessWidget {
  const _AdminErrorState({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_outlined, size: 48),
          const SizedBox(height: 12),
          const Text('Could not load inventory.'),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }
}

class _AdminEmptyState extends StatelessWidget {
  const _AdminEmptyState({required this.onCreate});

  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.inventory_2_outlined, size: 52),
          const SizedBox(height: 12),
          const Text('No products yet'),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onCreate,
            icon: const Icon(Icons.add),
            label: const Text('Create first product'),
          ),
        ],
      ),
    );
  }
}
