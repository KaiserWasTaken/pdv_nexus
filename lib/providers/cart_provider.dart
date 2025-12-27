import 'package:flutter/material.dart';

// Clase simple para definir qué es un item en el carrito
class CartItem {
  final String name;
  final double price;
  int quantity;

  CartItem({required this.name, required this.price, this.quantity = 1});
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

  // AGREGAR PRODUCTO
  void addItem(String name, double price) {
    // Revisamos si ya existe para solo aumentar la cantidad
    final index = _items.indexWhere((item) => item.name == name);

    if (index >= 0) {
      _items[index].quantity += 1;
    } else {
      _items.add(CartItem(name: name, price: price));
    }
    // ¡Avisar a todas las pantallas que hubo un cambio!
    notifyListeners();
  }

  // ELIMINAR UNO (Restar cantidad o borrar si es 0)
  void removeItem(String name) {
    final index = _items.indexWhere((item) => item.name == name);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // LIMPIAR TODO (Nueva venta)
  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}