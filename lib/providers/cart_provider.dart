import 'package:flutter/material.dart';

enum CartItemType { product, rental }

// Clase mejorada para definir qué es un item en el carrito
class CartItem {
  final String name;
  final double price;
  int quantity;
  final CartItemType type;
  
  // Metadatos para rentas
  final String? consoleName;
  final int? minutes;
  final int? extraControllers;

  CartItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.type = CartItemType.product,
    this.consoleName,
    this.minutes,
    this.extraControllers,
  });

  // Método helper para convertir a Map (útil para BD)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'type': type.name,
      'consoleName': consoleName,
      'minutes': minutes,
      'extraControllers': extraControllers,
    };
  }
}

// El cerebro que administra la lista de compras
class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get totalAmount {
    var total = 0.0;
    for (var item in _items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  int get totalItems {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // ========================================
  // AGREGAR PRODUCTO (CAFETERÍA)
  // ========================================
  void addItem(String name, double price) {
    final index = _items.indexWhere((item) => item.name == name && item.type == CartItemType.product);

    if (index >= 0) {
      _items[index].quantity += 1;
    } else {
      _items.add(CartItem(name: name, price: price, type: CartItemType.product));
    }
    notifyListeners();
  }

  // ========================================
  // AGREGAR RENTA (VIDEOJUEGOS)
  // ========================================
  void addRentalItem({
    required String consoleName,
    required int minutes,
    required int extraControllers,
    required double price,
  }) {
    // Si ya existe una renta para esta consola en el carrito, la reemplazamos
    _items.removeWhere((item) => item.consoleName == consoleName && item.type == CartItemType.rental);
    
    _items.add(CartItem(
      name: "Renta $consoleName ($minutes min)",
      price: price,
      type: CartItemType.rental,
      consoleName: consoleName,
      minutes: minutes,
      extraControllers: extraControllers,
    ));
    notifyListeners();
  }

  void decrementItem(String name, [CartItemType type = CartItemType.product]) {
    final index = _items.indexWhere((item) => item.name == name && item.type == type);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItemCompletely(String name, [CartItemType type = CartItemType.product]) {
    _items.removeWhere((item) => item.name == name && item.type == type);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  List<Map<String, dynamic>> getItemsForDatabase() {
    return _items.map((item) => item.toMap()).toList();
  }
}
