import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:app_duralon/services/auth_service.dart';
import 'package:app_duralon/styles/app_style.dart';

class ClientesTab extends StatefulWidget {
  const ClientesTab({super.key});

  @override
  State<ClientesTab> createState() => _ClientesTabState();
}

class _ClientesTabState extends State<ClientesTab> {
  final _search = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildSearchBar(),
        Expanded(
          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('clientes')
                .orderBy('nombre')
                .snapshots(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primaryBlue),
                );
              }
              if (snap.hasError) {
                return Center(child: Text('Error: ${snap.error}'));
              }

              final docs = snap.data?.docs ?? [];
              final q = _query.trim().toLowerCase();
              final filtered = q.isEmpty
                  ? docs
                  : docs.where((d) {
                      final data = d.data();
                      final nombre = (data['nombre'] as String? ?? '').toLowerCase();
                      final rnc = (data['rnc'] as String? ?? '').toLowerCase();
                      final codigo = (data['codigo'] as String? ?? '').toLowerCase();
                      return nombre.contains(q) || rnc.contains(q) || codigo.contains(q);
                    }).toList();

              if (filtered.isEmpty) {
                return Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.people_outline_rounded,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          q.isEmpty ? 'No hay clientes' : 'Sin resultados para "$_query"',
                          style: const TextStyle(color: Color(0xFF8A94A6), fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
                itemCount: filtered.length,
                separatorBuilder: (context, i) => const SizedBox(height: 10),
                itemBuilder: (_, i) => _ClienteCard(doc: filtered[i]),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSearchBar() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      child: TextField(
        controller: _search,
        onChanged: (v) => setState(() => _query = v),
        decoration: InputDecoration(
          hintText: 'Buscar por nombre, RNC o código…',
          hintStyle: const TextStyle(color: Color(0xFFA5ADBA), fontSize: 14),
          prefixIcon: const Icon(Icons.search_rounded, color: Color(0xFFA5ADBA)),
          suffixIcon: _query.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _search.clear();
                    setState(() => _query = '');
                  },
                )
              : null,
          filled: true,
          fillColor: const Color(0xFFF1F3F6),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
      ),
    );
  }
}

// ── Tarjeta de cliente ─────────────────────────────────────────────────────────

class _ClienteCard extends StatelessWidget {
  const _ClienteCard({required this.doc});
  final QueryDocumentSnapshot<Map<String, dynamic>> doc;

  @override
  Widget build(BuildContext context) {
    final data = doc.data();
    final nombre = data['nombre'] as String? ?? '—';
    final rnc = data['rnc'] as String? ?? '—';
    final codigo = data['codigo'] as String? ?? '';
    final direccion = data['direccion'] as String? ?? '';
    final tel1 = data['telefono1'] as String?;
    final tel2 = data['telefono2'] as String?;
    final activo = data['activo'] as bool? ?? false;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFE8ECF1)),
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: Text(
                  nombre.isNotEmpty ? nombre[0].toUpperCase() : 'C',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryBlue,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombre,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF0F172A),
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Text(
                          'RNC: $rnc',
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontSize: 12,
                            color: Color(0xFF64748B),
                          ),
                        ),
                        if (codigo.isNotEmpty) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(5),
                            ),
                            child: Text(
                              codigo,
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 11,
                                color: Color(0xFF475569),
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              _StatusBadge(activo: activo),
            ],
          ),
          if (direccion.isNotEmpty || tel1 != null) ...[
            const SizedBox(height: 10),
            const Divider(height: 1, color: Color(0xFFF1F5F9)),
            const SizedBox(height: 10),
            if (direccion.isNotEmpty)
              _InfoRow(icon: Icons.location_on_outlined, text: direccion),
            if (tel1 != null && tel1.trim().isNotEmpty && tel1 != '1')
              _InfoRow(icon: Icons.phone_outlined, text: tel1),
            if (tel2 != null && tel2.toString().trim().isNotEmpty)
              _InfoRow(icon: Icons.phone_outlined, text: tel2.toString()),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: () => _mostrarDialogoContrasena(context, nombre, rnc),
              icon: const Icon(Icons.key_outlined, size: 16),
              label: const Text('Asignar contraseña'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryBlue,
                side: BorderSide(color: AppColors.primaryBlue.withValues(alpha: 0.4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoContrasena(
      BuildContext context, String nombre, String rnc) async {
    await showDialog<void>(
      context: context,
      builder: (_) => _AsignarContrasenaDialog(nombre: nombre, rnc: rnc),
    );
  }
}

// ── Diálogo de asignación de contraseña ───────────────────────────────────────

class _AsignarContrasenaDialog extends StatefulWidget {
  const _AsignarContrasenaDialog({required this.nombre, required this.rnc});
  final String nombre;
  final String rnc;

  @override
  State<_AsignarContrasenaDialog> createState() =>
      _AsignarContrasenaDialogState();
}

class _AsignarContrasenaDialogState extends State<_AsignarContrasenaDialog> {
  final _formKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _showPass = false;
  bool _showConfirm = false;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  String get _rncNorm => rnc.replaceAll(RegExp(r'\D'), '');
  String get rnc => widget.rnc;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });

    try {
      await AuthService().crearClienteConRnc(
        rnc: rnc,
        nombre: widget.nombre,
        password: _passCtrl.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Acceso creado para ${widget.nombre}'),
            backgroundColor: Colors.green.shade600,
          ),
        );
      }
    } on DuplicateRncException {
      setState(() => _error = 'Este cliente ya tiene acceso creado.');
    } on InvalidRncException {
      setState(() => _error = 'El RNC "$rnc" no tiene un formato válido.');
    } catch (e) {
      setState(() => _error = 'Error al crear acceso: $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final emailPreview = '${_rncNorm.isNotEmpty ? _rncNorm : 'rnc'}@duralon.com';

    return AlertDialog(
      title: const Text('Asignar contraseña', style: TextStyle(fontSize: 16)),
      content: SizedBox(
        width: 320,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(widget.nombre,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.email_outlined, size: 13, color: Color(0xFF94A3B8)),
                  const SizedBox(width: 4),
                  Text(emailPreview,
                      style: const TextStyle(fontSize: 12, color: Color(0xFF64748B),
                          fontFamily: 'monospace')),
                ],
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _passCtrl,
                obscureText: !_showPass,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(_showPass ? Icons.visibility_off : Icons.visibility,
                        size: 18),
                    onPressed: () => setState(() => _showPass = !_showPass),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (v.trim().length < 6) return 'Mínimo 6 caracteres';
                  return null;
                },
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _confirmCtrl,
                obscureText: !_showConfirm,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  suffixIcon: IconButton(
                    icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility,
                        size: 18),
                    onPressed: () => setState(() => _showConfirm = !_showConfirm),
                  ),
                ),
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return 'Requerido';
                  if (v.trim() != _passCtrl.text.trim()) return 'Las contraseñas no coinciden';
                  return null;
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!,
                    style: const TextStyle(color: Colors.red, fontSize: 12)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _loading ? null : _submit,
          child: _loading
              ? const SizedBox(
                  width: 16, height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Crear acceso'),
        ),
      ],
    );
  }
}

// ── Widgets auxiliares ─────────────────────────────────────────────────────────

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.activo});
  final bool activo;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: activo ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        activo ? 'Activo' : 'Inactivo',
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: activo ? const Color(0xFF059669) : const Color(0xFFDC2626),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 13, color: const Color(0xFF94A3B8)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 12, color: Color(0xFF64748B)),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
