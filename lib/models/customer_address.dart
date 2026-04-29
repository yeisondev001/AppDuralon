import 'package:cloud_firestore/cloud_firestore.dart';

class CustomerAddress {
  const CustomerAddress({
    required this.id,
    required this.label,
    required this.calle,
    required this.ciudad,
    this.provincia = '',
    this.referencia = '',
    this.lat,
    this.lng,
    this.isDefault = false,
    required this.createdAt,
  });

  final String id;
  final String label;      // Casa, Trabajo, Otro…
  final String calle;
  final String ciudad;
  final String provincia;
  final String referencia; // Notas adicionales
  final double? lat;
  final double? lng;
  final bool isDefault;
  final DateTime createdAt;

  bool get hasCoords => lat != null && lng != null;

  CustomerAddress copyWith({
    String? label,
    String? calle,
    String? ciudad,
    String? provincia,
    String? referencia,
    double? lat,
    double? lng,
    bool? isDefault,
  }) =>
      CustomerAddress(
        id: id,
        label: label ?? this.label,
        calle: calle ?? this.calle,
        ciudad: ciudad ?? this.ciudad,
        provincia: provincia ?? this.provincia,
        referencia: referencia ?? this.referencia,
        lat: lat ?? this.lat,
        lng: lng ?? this.lng,
        isDefault: isDefault ?? this.isDefault,
        createdAt: createdAt,
      );

  Map<String, dynamic> toFirestore() => {
        'label': label,
        'calle': calle,
        'ciudad': ciudad,
        'provincia': provincia,
        'referencia': referencia,
        if (lat != null) 'lat': lat,
        if (lng != null) 'lng': lng,
        'isDefault': isDefault,
        'createdAt': FieldValue.serverTimestamp(),
      };

  factory CustomerAddress.fromFirestore(
      DocumentSnapshot<Map<String, dynamic>> doc) {
    final d = doc.data() ?? {};
    final ts = d['createdAt'] as Timestamp?;
    return CustomerAddress(
      id: doc.id,
      label: d['label'] as String? ?? 'Dirección',
      calle: d['calle'] as String? ?? '',
      ciudad: d['ciudad'] as String? ?? '',
      provincia: d['provincia'] as String? ?? '',
      referencia: d['referencia'] as String? ?? '',
      lat: (d['lat'] as num?)?.toDouble(),
      lng: (d['lng'] as num?)?.toDouble(),
      isDefault: d['isDefault'] as bool? ?? false,
      createdAt: ts?.toDate() ?? DateTime.now(),
    );
  }
}
