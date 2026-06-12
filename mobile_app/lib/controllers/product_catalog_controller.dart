import 'dart:async';

import 'package:commerce_sdk/commerce_sdk.dart';
import 'package:flutter/foundation.dart';

class ProductCatalogController extends ChangeNotifier {
  ProductCatalogController({required CommerceClient client}) : _client = client;

  final CommerceClient _client;
  Timer? _searchDebounce;
  List<Product> _products = const [];
  List<String> _categories = const [];
  bool _isLoading = false;
  bool _isLoadingMore = false;
  String? _error;
  String _search = '';
  String? _category;
  ProductSort _sort = ProductSort.newest;
  int _page = 1;
  int _totalPages = 1;

  List<Product> get products => _products;
  List<String> get categories => _categories;
  bool get isLoading => _isLoading;
  bool get isLoadingMore => _isLoadingMore;
  bool get canLoadMore => _page < _totalPages;
  String? get error => _error;
  String get search => _search;
  String? get category => _category;
  ProductSort get sort => _sort;

  Future<void> load({bool refresh = false}) async {
    if (_isLoading) {
      return;
    }

    _isLoading = true;
    _error = null;
    if (refresh) {
      _page = 1;
    }
    notifyListeners();

    try {
      final result = await _client.getProductPage(
        query: ProductQuery(
          page: 1,
          limit: 24,
          search: _search,
          category: _category,
          sort: _sort,
        ),
      );
      _products = result.items;
      _categories = result.categories;
      _page = result.page;
      _totalPages = result.totalPages;
    } on CommerceException catch (error) {
      _error = error.message;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadMore() async {
    if (_isLoadingMore || !canLoadMore) {
      return;
    }
    _isLoadingMore = true;
    notifyListeners();

    try {
      final result = await _client.getProductPage(
        query: ProductQuery(
          page: _page + 1,
          limit: 24,
          search: _search,
          category: _category,
          sort: _sort,
        ),
      );
      _products = [..._products, ...result.items];
      _categories = result.categories;
      _page = result.page;
      _totalPages = result.totalPages;
    } on CommerceException catch (error) {
      _error = error.message;
    } finally {
      _isLoadingMore = false;
      notifyListeners();
    }
  }

  void setSearch(String value) {
    _search = value;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 350), load);
  }

  void setCategory(String? value) {
    if (_category == value) {
      return;
    }
    _category = value;
    unawaited(load(refresh: true));
  }

  void setSort(ProductSort value) {
    if (_sort == value) {
      return;
    }
    _sort = value;
    unawaited(load(refresh: true));
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    super.dispose();
  }
}
