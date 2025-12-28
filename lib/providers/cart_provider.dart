import 'package:flutter/material.dart';

// Clase simple para definir qué es un item en el carrito
class CartItem {
  final String name;
  final double price;
  int quantity;

  CartItem({required this.name, required this.price, this.quantity = 1});

  // Método helper para convertir a Map (útil para BD)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }
}

// El cerebro que administra la lista de compras
class CartProvider extends ChangeNotifier {
  // Lista privada de items
  final List<CartItem> _items = [];

  // Para que la pantalla pueda leer la lista
  List<CartItem> get items => _items;

  // Calcular el total automáticamente
  double get totalAmount {
    var total = 0.0;
    for (var item in _items) {
      total += item.price * item.quantity;
    }
    return total;
  }

  // Contador total de items (suma de cantidades)
  int get totalItems {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  // ========================================
  // AGREGAR PRODUCTO
  // ========================================
  void addItem(String name, double price) {
    // Revisamos si ya existe para solo aumentar la cantidad
    final index = _items.indexWhere((item) => item.name == name);

    if (index >= 0) {
      _items[index].quantity += 1;
    } else {
      _items.add(CartItem(name: name, price: price));
    }
    notifyListeners();
  }

  // ========================================
  // RESTAR UNO (Corregido - decrementa de 1 en 1)
  // ========================================
  void decrementItem(String name) {
    final index = _items.indexWhere((item) => item.name == name);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
      } else {
        // Si la cantidad es 1, eliminamos el item completo
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // ========================================
  // ELIMINAR TODO EL PRODUCTO (nuevo método)
  // ========================================
  void removeItemCompletely(String name) {
    _items.removeWhere((item) => item.name == name);
    notifyListeners();
  }

  // ========================================
  // LIMPIAR TODO (Nueva venta)
  // ========================================
  void clearCart() {
    _items.clear();
    notifyListeners();
  }

  // ========================================
  // OBTENER ITEMS COMO LISTA DE MAPS (para BD)
  // ========================================
  List<Map<String, dynamic>> getItemsForDatabase() {
    return _items.map((item) => item.toMap()).toList();
  }

  // ========================================
  // VERIFICAR SI UN PRODUCTO YA ESTÁ EN EL CARRITO
  // ========================================
  bool containsProduct(String name) {
    return _items.any((item) => item.name == name);
  }

  // ========================================
  // OBTENER CANTIDAD DE UN PRODUCTO ESPECÍFICO
  // ========================================
  int getQuantityOf(String name) {
    final item = _items.firstWhere(
          (item) => item.name == name,
      orElse: () => CartItem(name: '', price: 0, quantity: 0),
    );
    return item.quantity;
  }
}