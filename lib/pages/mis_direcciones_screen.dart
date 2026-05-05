import 'package:app_duralon/models/customer_address.dart';
import 'package:app_duralon/services/address_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class MisDireccionesScreen extends StatelessWidget {
  const MisDireccionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A2230),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Mis direcciones',
          style: TextStyle(
            color: Color(0xFF1A2230),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.add_rounded, color: AppColors.primaryBlue),
            tooltip: 'Agregar dirección',
            onPressed: () => _openForm(context, uid, null),
          ),
        ],
      ),
      body: StreamBuilder<List<CustomerAddress>>(
        stream: AddressService.stream(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: Text(
                'Error: ${snap.error}',
                style: const TextStyle(color: Color(0xFF94A3B8)),
              ),
            );
          }
          final addresses = snap.data ?? [];
          if (addresses.isEmpty) {
            return _buildEmpty(context, uid);
          }
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: addresses.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _AddressCard(
              address: addresses[i],
              uid: uid,
              onEdit: () => _openForm(context, uid, addresses[i]),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openForm(context, uid, null),
        backgroundColor: AppColors.primaryBlue,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text(
          'Agregar',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
    );
  }

  Widget _buildEmpty(BuildContext context, String uid) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.location_off_rounded,
            size: 72,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin direcciones guardadas',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Agrega tu primera dirección de entrega',
            style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8)),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () => _openForm(context, uid, null),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            icon: const Icon(Icons.add_location_alt_rounded),
            label: const Text(
              'Agregar dirección',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  void _openForm(BuildContext context, String uid, CustomerAddress? existing) {
    Navigator.push<void>(
      context,
      MaterialPageRoute<void>(
        builder: (_) => _AddressFormScreen(uid: uid, existing: existing),
        fullscreenDialog: true,
      ),
    );
  }
}

// ── Tarjeta de dirección ───────────────────────────────────────────────────────

class _AddressCard extends StatelessWidget {
  const _AddressCard({
    required this.address,
    required this.uid,
    required this.onEdit,
  });
  final CustomerAddress address;
  final String uid;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: address.isDefault
            ? Border.all(color: AppColors.primaryBlue, width: 1.5)
            : null,
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 4,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: address.isDefault
                        ? AppColors.primaryBlue
                        : const Color(0xFFF1F3F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _iconForLabel(address.label),
                        size: 14,
                        color: address.isDefault
                            ? Colors.white
                            : const Color(0xFF64748B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        address.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: address.isDefault
                              ? Colors.white
                              : const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                if (address.isDefault) ...[
                  const SizedBox(width: 8),
                  const Text(
                    'Principal',
                    style: TextStyle(
                      fontSize: 11,
                      color: AppColors.primaryBlue,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const Spacer(),
                PopupMenuButton<String>(
                  icon: const Icon(
                    Icons.more_vert_rounded,
                    size: 20,
                    color: Color(0xFF94A3B8),
                  ),
                  onSelected: (v) => _onAction(context, v),
                  itemBuilder: (_) => [
                    const PopupMenuItem(value: 'edit', child: Text('Editar')),
                    if (!address.isDefault)
                      const PopupMenuItem(
                        value: 'default',
                        child: Text('Marcar como principal'),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Text(
                        'Eliminar',
                        style: TextStyle(color: Color(0xFFDC2626)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              address.calle,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              [
                address.ciudad,
                if (address.provincia.isNotEmpty) address.provincia,
              ].join(', '),
              style: const TextStyle(fontSize: 13, color: Color(0xFF64748B)),
            ),
            if (address.referencia.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                address.referencia,
                style: const TextStyle(fontSize: 12, color: Color(0xFF94A3B8)),
              ),
            ],
            if (address.hasCoords) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(
                    Icons.gps_fixed_rounded,
                    size: 12,
                    color: Color(0xFF22C55E),
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '${address.lat!.toStringAsFixed(5)}, ${address.lng!.toStringAsFixed(5)}',
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 11,
                      color: Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  IconData _iconForLabel(String label) {
    switch (label.toLowerCase()) {
      case 'casa':
        return Icons.home_rounded;
      case 'trabajo':
        return Icons.work_rounded;
      case 'otro':
        return Icons.place_rounded;
      default:
        return Icons.location_on_rounded;
    }
  }

  Future<void> _onAction(BuildContext context, String action) async {
    switch (action) {
      case 'edit':
        onEdit();
      case 'default':
        await AddressService.setDefault(uid, address.id);
      case 'delete':
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Eliminar dirección'),
            content: Text('¿Eliminar "${address.label} - ${address.calle}"?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancelar'),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFDC2626),
                ),
                child: const Text('Eliminar'),
              ),
            ],
          ),
        );
        if (ok == true) await AddressService.delete(uid, address.id);
    }
  }
}

// ── Formulario agregar / editar ────────────────────────────────────────────────

class _AddressFormScreen extends StatefulWidget {
  const _AddressFormScreen({required this.uid, this.existing});
  final String uid;
  final CustomerAddress? existing;

  @override
  State<_AddressFormScreen> createState() => _AddressFormScreenState();
}

class _AddressFormScreenState extends State<_AddressFormScreen> {
  final _formKey = GlobalKey<FormState>();

  late String _label;
  late final TextEditingController _calleCtrl;
  late final TextEditingController _ciudadCtrl;
  late final TextEditingController _provCtrl;
  late final TextEditingController _refCtrl;
  late bool _isDefault;
  double? _lat;
  double? _lng;

  bool _loadingGps = false;
  bool _saving = false;
  String? _gpsError;

  static const _labels = ['Casa', 'Trabajo', 'Otro'];

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _label = e?.label ?? 'Casa';
    _calleCtrl = TextEditingController(text: e?.calle ?? '');
    _ciudadCtrl = TextEditingController(text: e?.ciudad ?? '');
    _provCtrl = TextEditingController(text: e?.provincia ?? '');
    _refCtrl = TextEditingController(text: e?.referencia ?? '');
    _isDefault = e?.isDefault ?? false;
    _lat = e?.lat;
    _lng = e?.lng;
  }

  @override
  void dispose() {
    _calleCtrl.dispose();
    _ciudadCtrl.dispose();
    _provCtrl.dispose();
    _refCtrl.dispose();
    super.dispose();
  }

  Future<void> _captureGps() async {
    setState(() {
      _loadingGps = true;
      _gpsError = null;
    });
    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission perm = permission;
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
      }
      if (perm == LocationPermission.deniedForever ||
          perm == LocationPermission.denied) {
        setState(() {
          _gpsError = 'Permiso de ubicación denegado.';
          _loadingGps = false;
        });
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      setState(() {
        _lat = pos.latitude;
        _lng = pos.longitude;
        _loadingGps = false;
      });
    } catch (e) {
      setState(() {
        _gpsError = 'No se pudo obtener ubicación.';
        _loadingGps = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);
    try {
      final address = CustomerAddress(
        id: widget.existing?.id ?? '',
        label: _label,
        calle: _calleCtrl.text.trim(),
        ciudad: _ciudadCtrl.text.trim(),
        provincia: _provCtrl.text.trim(),
        referencia: _refCtrl.text.trim(),
        lat: _lat,
        lng: _lng,
        isDefault: _isDefault,
        createdAt: widget.existing?.createdAt ?? DateTime.now(),
      );
      if (widget.existing == null) {
        await AddressService.add(widget.uid, address);
      } else {
        await AddressService.update(widget.uid, address);
      }
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error al guardar: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close_rounded, color: Color(0xFF1A2230)),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          isEdit ? 'Editar dirección' : 'Nueva dirección',
          style: const TextStyle(
            color: Color(0xFF1A2230),
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            // Tipo de dirección
            const Text(
              'Tipo',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: _labels.map((l) {
                final selected = _label == l;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(l),
                    selected: selected,
                    onSelected: (_) => setState(() => _label = l),
                    selectedColor: AppColors.primaryBlue,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : const Color(0xFF475569),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 20),

            // GPS
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _lat != null
                    ? const Color(0xFFF0FDF4)
                    : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: _lat != null
                      ? const Color(0xFF22C55E)
                      : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    _lat != null
                        ? Icons.gps_fixed_rounded
                        : Icons.gps_not_fixed_rounded,
                    color: _lat != null
                        ? const Color(0xFF22C55E)
                        : const Color(0xFF94A3B8),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _lat != null
                        ? Text(
                            '${_lat!.toStringAsFixed(5)}, ${_lng!.toStringAsFixed(5)}',
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 13,
                              color: Color(0xFF15803D),
                              fontWeight: FontWeight.w600,
                            ),
                          )
                        : Text(
                            _gpsError ?? 'Sin coordenadas GPS',
                            style: TextStyle(
                              fontSize: 13,
                              color: _gpsError != null
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF94A3B8),
                            ),
                          ),
                  ),
                  const SizedBox(width: 8),
                  _loadingGps
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: AppColors.primaryBlue,
                          ),
                        )
                      : TextButton.icon(
                          onPressed: _captureGps,
                          icon: const Icon(Icons.my_location_rounded, size: 16),
                          label: Text(_lat != null ? 'Actualizar' : 'Capturar'),
                          style: TextButton.styleFrom(
                            foregroundColor: AppColors.primaryBlue,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 6,
                            ),
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Calle / dirección principal
            _field(
              controller: _calleCtrl,
              label: 'Calle y número',
              hint: 'Ej: Av. Winston Churchill 1099',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 14),

            // Ciudad
            _field(
              controller: _ciudadCtrl,
              label: 'Ciudad / Municipio',
              hint: 'Ej: Santo Domingo',
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Campo requerido' : null,
            ),
            const SizedBox(height: 14),

            // Provincia
            _field(
              controller: _provCtrl,
              label: 'Provincia',
              hint: 'Ej: Distrito Nacional',
            ),
            const SizedBox(height: 14),

            // Referencia
            _field(
              controller: _refCtrl,
              label: 'Referencia (opcional)',
              hint: 'Ej: Frente al supermercado Nacional',
              maxLines: 2,
            ),
            const SizedBox(height: 20),

            // Predeterminada
            SwitchListTile(
              value: _isDefault,
              onChanged: (v) => setState(() => _isDefault = v),
              title: const Text(
                'Dirección principal',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
              subtitle: const Text(
                'Se usará por defecto al confirmar pedidos',
                style: TextStyle(fontSize: 12),
              ),
              activeThumbColor: AppColors.primaryBlue,
              contentPadding: EdgeInsets.zero,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _saving ? null : _save,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryBlue,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 0,
                ),
                child: _saving
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2.5,
                        ),
                      )
                    : Text(
                        isEdit ? 'Guardar cambios' : 'Agregar dirección',
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    String? hint,
    String? Function(String?)? validator,
    int maxLines = 1,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: Color(0xFF64748B),
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Color(0xFFCBD5E1)),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(
                color: AppColors.primaryBlue,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Color(0xFFDC2626)),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 12,
            ),
          ),
        ),
      ],
    );
  }
}
