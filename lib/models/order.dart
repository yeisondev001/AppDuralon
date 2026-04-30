import 'package:cloud_firestore/cloud_firestore.dart';

enum OrderStatus {
  pendiente,
  confirmado,
  enProceso,
  enviado,
  entregado,
  cancelado;

  String get label {
    switch (this) {
      case OrderStatus.pendiente:   return 'Pendiente';
      case OrderStatus.confirmado:  return 'Confirmado';
      case OrderStatus.enProceso:   return 'En proceso';
      case OrderStatus.enviado:     return 'Enviado';
      case OrderStatus.entregado:   return 'Entregado';
      case OrderStatus.cancelado:   return 'Cancelado';
    }
  }

  static OrderStatus fromString(String? s) {
    switch (s) {
      case 'confirmado':  return OrderStatus.confirmado;
      case 'en_proceso':  return OrderStatus.enProceso;
      case 'enviado':     return OrderStatus.enviado;
      case 'entregado':   return OrderStatus.entregado;
      case 'cancelado':   return OrderStatus.cancelado;
      default:            return OrderStatus.pendiente;
    }
  }

  String get firestoreValue {
    switch (this) {
      case OrderStatus.pendiente:   return 'pendiente';
      case OrderStatus.confirmado:  return 'confirmado';
      case OrderStatus.enProceso:   return 'en_proceso';
      case OrderStatus.enviado:     return 'enviado';
      case OrderStatus.entregado:   return 'entregado';
      case OrderStatus.cancelado:   return 'cancelado';
    }
  }
}

class OrderItem {
  const OrderItem({
    required this.productId,
    required this.codigo,
    required this.nombre,
    required this.categoria,
    this.color,
    required this.precio,
    required this.cantidad,
    this.imageUrl,
  });

  final String productId;
  final String codigo;
  final String nombre;
  final String categoria;
  final String? color;
  final double precio;
  final int cantidad;
  final String? imageUrl;

  double get total => precio * cantidad;

  Map<String, dynamic> toMap() => {
    'productId': productId,
    'codigo':    codigo,
    'nombre':    nombre,
    'categoria': categoria,
    if (color != null)    'color':    color,
    'precio':    precio,
    'cantidad':  cantidad,
    if (imageUrl != null) 'imageUrl': imageUrl,
  };

  factory OrderItem.fromMap(Map<String, dynamic> m) => OrderItem(
    productId: m['productId'] as String? ?? '',
    codigo:    m['codigo']    as String? ?? '',
    nombre:    m['nombre']    as String? ?? '',
    categoria: m['categoria'] as String? ?? '',
    color:     m['color']     as String?,
    precio:    (m['precio']   as num?)?.toDouble() ?? 0,
    cantidad:  (m['cantidad'] as num?)?.toInt()    ?? 1,
    imageUrl:  m['imageUrl']  as String?,
  );
}

class Order {
  const Order({
    required this.id,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.descuento,
    required this.itbis,
    required this.total,
    this.cupon,
    this.notas,
    required this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final OrderStatus status;
  final List<OrderItem> items;
  final double subtotal;
  final double descuento;
  final double itbis;
  final double total;
  final String? cupon;
  final String? notas;
  final DateTime createdAt;
  final DateTime? updatedAt;

  int get totalUnidades => items.fold(0, (s, it) => s + it.cantidad);

  Map<String, dynamic> toFirestore() => {
    'customerId':    customerId,
    'customerName':  customerName,
    'customerEmail': customerEmail,
    'status':        status.firestoreValue,
    'items':         items.map((i) => i.toMap()).toList(),
    'subtotal':      subtotal,
    'descuento':     descuento,
    'itbis':         itbis,
    'total':         total,
    if (cupon != null) 'cupon': cupon,
    if (notas != null && notas!.isNotEmpty) 'notas': notas,
    'createdAt':     FieldValue.serverTimestamp(),
    'updatedAt':     FieldValue.serverTimestamp(),
  };

  factory Order.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final rawItems = d['items'] as List<dynamic>? ?? [];
    final ts = d['createdAt'] as Timestamp?;
    final tsUp = d['updatedAt'] as Timestamp?;
    return Order(
      id:            doc.id,
      customerId:    d['customerId']    as String? ?? '',
      customerName:  d['customerName']  as String? ?? '',
      customerEmail: d['customerEmail'] as String? ?? '',
      status:        OrderStatus.fromString(d['status'] as String?),
      items:         rawItems.map((e) => OrderItem.fromMap(e as Map<String, dynamic>)).toList(),
      subtotal:      (d['subtotal']  as num?)?.toDouble() ?? 0,
      descuento:     (d['descuento'] as num?)?.toDouble() ?? 0,
      itbis:         (d['itbis']     as num?)?.toDouble() ?? 0,
      total:         (d['total']     as num?)?.toDouble() ?? 0,
      cupon:         d['cupon']  as String?,
      notas:         d['notas']  as String?,
      createdAt:     ts?.toDate()   ?? DateTime.now(),
      updatedAt:     tsUp?.toDate(),
    );
  }
}
