import 'package:flutter/material.dart';

class CategoryModel {
  static const int _fallbackColorValue = 0xFF9E9E9E;

  final String id;
  final String label;
  final int iconCode;
  final String colorHex;

  CategoryModel({
    required this.id,
    required this.label,
    required this.iconCode,
    required this.colorHex,
  });

  factory CategoryModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return CategoryModel(
      id: id ?? json['id']?.toString() ?? json['categoryId']?.toString() ?? '',
      label: json['label'] ?? json['name'] ?? '',
      iconCode:
          json['iconCode'] ??
          int.tryParse(json['icon']?.toString() ?? '') ??
          Icons.help_outline.codePoint,
      colorHex: (json['colorHex'] ?? json['color'] ?? '0xFF9E9E9E').toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'label': label,
      'iconCode': iconCode,
      'colorHex': colorHex,
    };
  }

  Color get color => _parseColor(colorHex);

  static Color _parseColor(String rawColor) {
    final normalized = rawColor.trim();
    if (normalized.isEmpty) {
      return const Color(_fallbackColorValue);
    }

    var candidate = normalized;
    final hasHexPrefix =
        candidate.startsWith('#') ||
        candidate.startsWith('0x') ||
        candidate.startsWith('0X');

    if (candidate.startsWith('#')) {
      candidate = candidate.substring(1);
    } else if (candidate.startsWith('0x') || candidate.startsWith('0X')) {
      candidate = candidate.substring(2);
    }

    final looksLikeHex =
        hasHexPrefix ||
        RegExp(r'[A-Fa-f]').hasMatch(candidate) ||
        candidate.length == 3 ||
        candidate.length == 6 ||
        candidate.length == 8;

    if (looksLikeHex && RegExp(r'^[0-9A-Fa-f]+$').hasMatch(candidate)) {
      if (candidate.length == 3) {
        candidate = candidate.split('').map((char) => '$char$char').join();
      }
      if (candidate.length == 6) {
        candidate = 'FF$candidate';
      }
      if (candidate.length == 8) {
        return Color(int.parse(candidate, radix: 16));
      }
    }

    final decimalValue = int.tryParse(normalized);
    if (decimalValue != null) {
      return Color(decimalValue);
    }

    return const Color(_fallbackColorValue);
  }

  IconData get icon {
    // 1. Guess icon from label name first (more reliable than test DB data)
    final l = label.toLowerCase();
    if (l.contains('food') || l.contains('restaurant')) return Icons.restaurant_rounded;
    if (l.contains('cafe') || l.contains('coffee') || l.contains('beverage')) return Icons.local_cafe_rounded;
    if (l.contains('shopping') || l.contains('store')) return Icons.shopping_cart_rounded;
    if (l.contains('health') || l.contains('pharmacy')) return Icons.local_hospital_rounded;
    if (l.contains('gas') || l.contains('petrol')) return Icons.local_gas_station_rounded;
    if (l.contains('hotel') || l.contains('stay') || l.contains('travel')) return Icons.hotel_rounded;

    // 2. Fallback to the icon code from the database
    final fromDb = _iconRegistry[iconCode];
    if (fromDb != null) return fromDb;

    return Icons.category_rounded;
  }

  static const Map<int, IconData> _iconRegistry = {
    0xe51c: Icons.restaurant,
    0xe362: Icons.local_cafe,
    0xe51f: Icons.shopping_cart,
    0xe3f1: Icons.local_hospital,
    0xe3e7: Icons.local_gas_station,
    0xe30b: Icons.hotel,
    0xe0c8: Icons.location_on,
    0xe8b8: Icons.settings,
    0xe7fd: Icons.person,
    0xe88a: Icons.home,
    0xe8b6: Icons.search,
    0xe872: Icons.delete,
    0xe150: Icons.edit,
    0xe53f: Icons.navigation,
    0xe5cd: Icons.close,
    0xe5cc: Icons.chevron_right,
    0xe5cb: Icons.chevron_left,
    0xe8f0: Icons.view_in_ar,
    0xe85e: Icons.local_offer,
    0xe89a: Icons.label,
    0xe913: Icons.tag,
    0xeb48: Icons.local_pizza,
    0xe56c: Icons.directions_run,
  };
}

class TagModel {
  final String id;
  final String name;
  final String? color;
  final int iconCode;

  TagModel({
    required this.id,
    required this.name,
    this.color,
    required this.iconCode,
  });

  factory TagModel.fromJson(Map<String, dynamic> json, {String? id}) {
    return TagModel(
      id: id ?? json['id']?.toString() ?? json['tagId']?.toString() ?? '',
      name: json['name'] ?? '',
      color: json['color']?.toString(),
      iconCode:
          json['iconCode'] ??
          int.tryParse(json['icon']?.toString() ?? '') ??
          CategoryModel._iconRegistry.entries
              .firstWhere(
                (e) => e.value == TagModel.guessIcon(json['name'] ?? ''),
                orElse: () => const MapEntry(0, Icons.tag),
              )
              .key,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'color': color, 'iconCode': iconCode};
  }

  IconData get icon =>
      CategoryModel._iconRegistry[iconCode] ?? Icons.tag_rounded;

  Color get displayColor => CategoryModel._parseColor(color ?? '');

  /// Guesses an appropriate icon based on the tag name.
  static IconData guessIcon(String name) {
    final lower = name.toLowerCase();
    if (lower.contains('pizza')) return Icons.local_pizza_rounded;
    if (lower.contains('burger') || lower.contains('food')) {
      return Icons.restaurant_rounded;
    }
    if (lower.contains('coffee') || lower.contains('cafe')) {
      return Icons.local_cafe_rounded;
    }
    if (lower.contains('drink') || lower.contains('bar')) {
      return Icons.local_bar_rounded;
    }
    if (lower.contains('cloth') || lower.contains('fashion')) {
      return Icons.checkroom_rounded;
    }
    if (lower.contains('tech') || lower.contains('electr')) {
      return Icons.devices_other_rounded;
    }
    if (lower.contains('shop') || lower.contains('store')) {
      return Icons.shopping_bag_rounded;
    }
    if (lower.contains('gas') || lower.contains('petrol')) {
      return Icons.local_gas_station_rounded;
    }
    if (lower.contains('money') || lower.contains('bank')) {
      return Icons.account_balance_rounded;
    }
    if (lower.contains('pharmacy') || lower.contains('med')) {
      return Icons.local_pharmacy_rounded;
    }
    return Icons.label_rounded;
  }
}
