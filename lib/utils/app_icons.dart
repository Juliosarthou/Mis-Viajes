import 'package:flutter/material.dart';

class AppIcons {
  static const List<IconData> availableIcons = [
    Icons.restaurant_rounded,
    Icons.shopping_bag_rounded,
    Icons.local_taxi_rounded,
    Icons.hotel_rounded,
    Icons.flight_rounded,
    Icons.local_gas_station_rounded,
    Icons.medical_services_rounded,
    Icons.celebration_rounded,
    Icons.museum_rounded,
    Icons.coffee_rounded,
    Icons.card_giftcard_rounded,
    Icons.commute_rounded,
    Icons.category_rounded,
    Icons.payments_rounded,
    Icons.directions_bus_rounded,
    Icons.shopping_cart_rounded,
    Icons.attractions_rounded,
    Icons.local_pharmacy_rounded,
    Icons.beach_access_rounded,
  ];

  static IconData getIcon(String? code) {
    if (code == null) return Icons.category_rounded;
    final intCode = int.tryParse(code);
    if (intCode == null) return Icons.category_rounded;
    
    // Para evitar el error de tree shaking en iconos dinámicos,
    // buscamos el icono en nuestra lista de constantes predefinidas.
    try {
      return availableIcons.firstWhere(
        (icon) => icon.codePoint == intCode,
        orElse: () => Icons.category_rounded,
      );
    } catch (_) {
      return Icons.category_rounded;
    }
  }
}
