import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

enum CartItemType { product, rental }

// Clase mejorada para definir qué es un item en el carrito
class CartItem {
  final String name;
  final double price;
  int quantity;
  final CartItemType type;
  final String category; // ✅ NUEVO: Para distinguir en el monitor
  
  // Metadatos para rentas
  final String? consoleName;
  final int? minutes;
  final int? extraControllers;

  // ✅ NUEVO: Modificadores para personalización
  final List<String> modifiers;

  // ✅ NUEVO: Componentes estructurados para el monitor
  final List<Map<String, dynamic>>? comboComponents; 

  CartItem({
    required this.name,
    required this.price,
    this.quantity = 1,
    this.type = CartItemType.product,
    required this.category, // ✅ Requerido
    this.consoleName,
    this.minutes,
    this.extraControllers,
    this.modifiers = const [],
    this.comboComponents, // Opcional
  });

  // Método helper para convertir a Map (útil para BD)
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'price': price,
      'quantity': quantity,
      'type': type.name,
      'category': category, // ✅ Añadido
      'consoleName': consoleName,
      'minutes': minutes,
      'extraControllers': extraControllers,
      'modifiers': modifiers.join(', '), 
    };
  }

  // Helper para comparar si dos items son idénticos (incluyendo modificadores)
  bool isSameAs(String otherName, CartItemType otherType, List<String> otherModifiers) {
    if (name != otherName || type != otherType) return false;
    return listEquals(modifiers, otherModifiers);
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
  // AGREGAR PRODUCTO O ITEM GENÉRICO
  // ========================================
  void addItem(String name, double price, {
    required String category, // ✅ Obligatorio
    List<String> modifiers = const [], 
    CartItemType type = CartItemType.product,
    List<Map<String, dynamic>>? comboComponents, // ✅ NUEVO
  }) {
    // Revisamos si ya existe un item EXACTAMENTE IGUAL (mismo nombre y modificadores)
    final index = _items.indexWhere((item) => item.isSameAs(name, type, modifiers));

    if (index >= 0 && comboComponents == null) {
      _items[index].quantity += 1;
    } else {
      _items.add(CartItem(
        name: name, 
        price: price, 
        category: category, // ✅ Guardar categoría
        type: type,
        modifiers: List.from(modifiers), // Copia de la lista
        comboComponents: comboComponents, // ✅ Guardar componentes
      ));
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
      category: 'Rentas', // ✅ Categoría fija para rentas
      type: CartItemType.rental,
      consoleName: consoleName,
      minutes: minutes,
      extraControllers: extraControllers,
    ));
    notifyListeners();
  }

  void decrementItem(String name, [CartItemType type = CartItemType.product, List<String> modifiers = const []]) {
    final index = _items.indexWhere((item) => item.isSameAs(name, type, modifiers));
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItemCompletely(String name, [CartItemType type = CartItemType.product, List<String> modifiers = const []]) {
    _items.removeWhere((item) => item.isSameAs(name, type, modifiers));
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
