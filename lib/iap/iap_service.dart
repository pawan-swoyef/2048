import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import '../ui/theme_controller.dart';

/// Service to handle in-app purchases using the official [in_app_purchase] plugin.
class IAPService extends ChangeNotifier {
  final ThemeController themeController;
  late StreamSubscription<List<PurchaseDetails>> _subscription;

  bool _isAvailable = false;
  bool _isLoading = false;
  List<ProductDetails> _products = [];
  String? _errorMessage;

  bool get isAvailable => _isAvailable;
  bool get isLoading => _isLoading;
  List<ProductDetails> get products => _products;
  String? get errorMessage => _errorMessage;

  static const Set<String> _kProductIds = {'monthly', 'yearly', 'lifetime2048'};

  IAPService(this.themeController);

  /// Subscribes to the purchase update stream and queries available products.
  void initialize() {
    final purchaseUpdated = InAppPurchase.instance.purchaseStream;
    _subscription = purchaseUpdated.listen(
      _onPurchaseUpdate,
      onError: (error) {
        _errorMessage = 'Purchase Stream Error: $error';
        notifyListeners();
      },
    );
    loadProducts();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  /// Queries the store for product details.
  Future<void> loadProducts() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _isAvailable = await InAppPurchase.instance.isAvailable();
      if (_isAvailable) {
        final response = await InAppPurchase.instance.queryProductDetails(_kProductIds);
        if (response.notFoundIDs.isNotEmpty) {
          debugPrint('Products not found in store: ${response.notFoundIDs}');
        }
        _products = response.productDetails;
      } else {
        _errorMessage = 'Store is not available on this device';
      }
    } catch (e) {
      _errorMessage = 'Failed to load products: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initiates the purchase flow for a product.
  Future<void> buyProduct(ProductDetails product) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final purchaseParam = PurchaseParam(productDetails: product);
      // Subscriptions and non-consumables are purchased using buyNonConsumable
      await InAppPurchase.instance.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _errorMessage = 'Failed to start purchase: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Initiates the restoration flow for past purchases.
  Future<void> restorePurchases() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await InAppPurchase.instance.restorePurchases();
    } catch (e) {
      _errorMessage = 'Failed to restore purchases: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Handles purchase updates from the store.
  Future<void> _onPurchaseUpdate(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchaseDetails in purchaseDetailsList) {
      if (purchaseDetails.status == PurchaseStatus.pending) {
        _isLoading = true;
        notifyListeners();
      } else {
        if (purchaseDetails.status == PurchaseStatus.error) {
          _errorMessage = purchaseDetails.error?.message ?? 'An error occurred during purchase';
          _isLoading = false;
          notifyListeners();
        } else if (purchaseDetails.status == PurchaseStatus.canceled) {
          _isLoading = false;
          notifyListeners();
        } else if (purchaseDetails.status == PurchaseStatus.purchased ||
                   purchaseDetails.status == PurchaseStatus.restored) {
          // Unlock premium features
          themeController.setPremiumUnlocked(true);
          _isLoading = false;
          _errorMessage = null;
          notifyListeners();
        }

        if (purchaseDetails.pendingCompletePurchase) {
          await InAppPurchase.instance.completePurchase(purchaseDetails);
        }
      }
    }
  }
}

/// Exposes the [IAPService] to the widget tree and rebuilds dependents
/// when the product details or purchase state changes.
class IAPScope extends InheritedNotifier<IAPService> {
  const IAPScope({
    super.key,
    required IAPService service,
    required super.child,
  }) : super(notifier: service);

  static IAPService of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<IAPScope>();
    assert(scope != null, 'No IAPScope found in context');
    return scope!.notifier!;
  }
}
