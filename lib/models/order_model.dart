import 'package:flutter/material.dart';

class OrderItemResponse {
  final int id;
  final int orderId;
  final int itemId;
  final int quantity;
  final String? observation;
  final double unitPrice;
  final String? itemName;
  final String? itemCategory;

  OrderItemResponse({
    required this.id,
    required this.orderId,
    required this.itemId,
    required this.quantity,
    this.observation,
    required this.unitPrice,
    this.itemName,
    this.itemCategory,
  });

  factory OrderItemResponse.fromJson(Map<String, dynamic> json) {
    final item = json['item'] as Map<String, dynamic>?;
    return OrderItemResponse(
      id: json['id'] as int,
      orderId: json['order_id'] as int,
      itemId: json['item_id'] as int,
      quantity: json['quantity'] as int,
      observation: json['observation'] as String?,
      unitPrice: (json['unit_price'] as num).toDouble(),
      itemName: item?['name'] as String?,
      itemCategory: item?['category'] as String?,
    );
  }

  double get total => unitPrice * quantity;
}

class OrderResponse {
  final int id;
  final int userId;
  final String status;
  final double totalValue;
  final DateTime createdAt;
  final List<OrderItemResponse> items;

  OrderResponse({
    required this.id,
    required this.userId,
    required this.status,
    required this.totalValue,
    required this.createdAt,
    required this.items,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      id: json['id'] as int,
      userId: json['user_id'] as int,
      status: json['status'] as String,
      totalValue: (json['total_value'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      items: (json['items'] as List? ?? [])
          .map((j) => OrderItemResponse.fromJson(j as Map<String, dynamic>))
          .toList(),
    );
  }

  String get statusLabel => switch (status.toUpperCase()) {
    'PENDING' => 'Pendente',
    'PREPARING' => 'Em preparo',
    'READY' => 'Pronto',
    'DELIVERED' => 'Entregue',
    'CANCELLED' => 'Cancelado',
    _ => status,
  };

  Color get statusColor => switch (status.toUpperCase()) {
    'PENDING' => const Color(0xFFFB8C00),
    'PREPARING' => const Color(0xFF1E88E5),
    'READY' => const Color(0xFF43A047),
    'DELIVERED' => const Color(0xFF546E7A),
    'CANCELLED' => const Color(0xFFE53935),
    _ => const Color(0xFF9E9E9E),
  };

  IconData get statusIcon => switch (status.toUpperCase()) {
    'PENDING' => Icons.schedule,
    'PREPARING' => Icons.restaurant,
    'READY' => Icons.check_circle_outline,
    'DELIVERED' => Icons.done_all,
    'CANCELLED' => Icons.cancel_outlined,
    _ => Icons.help_outline,
  };
}
