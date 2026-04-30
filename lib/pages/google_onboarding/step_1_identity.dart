// =============================================================================
// Pantalla 1 de 2 — Identidad fiscal
// Agrupa: Tipo de cliente · Nombre · RNC / Cédula
// =============================================================================
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_duralon/pages/google_onboarding/app_colors.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_data.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_scaffold.dart';
import 'package:app_duralon/pages/google_onboarding/shared_inputs.dart';
import 'package:app_duralon/pages/google_onboarding/step_2_location.dart';
import 'package:app_duralon/pages/login_screen.dart';

class Step1IdentityScreen extends StatefulWidget {
  const Step1IdentityScreen({super.key, required this.data});
  final OnboardingData data;

  @override
  State<Step1IdentityScreen> createState() => _Step1IdentityScreenState();
}

class _Step1IdentityScreenState extends State<Step1IdentityScreen> {
  ClientType? _selectedType;
  late final TextEditingController _nameCtrl;
  late final TextEditingController _taxIdCtrl;
  final FocusNode _nameFocus = FocusNode();
  final FocusNode _taxFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _selectedType = widget.data.clientType;
    _nameCtrl  = TextEditingController(text: widget.data.name  ?? '');
    _taxIdCtrl = TextEditingController(text: widget.data.taxId ?? '');
    _nameCtrl.addListener(() => setState(() {}));
    _taxIdCtrl.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _taxIdCtrl.dispose();
    _nameFocus.dispose();
    _taxFocus.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get _isDominican => widget.data.isDominicanRepublic;

  bool get _isCompany =>
      _selectedType == ClientType.empresa ||
      _selectedType == ClientType.zonaFranca ||
      _selectedType == ClientType.gubernamental;

  bool get _taxIdValid {
    final raw = _taxIdCtrl.text.trim();
    if (raw.isEmpty) return false;
    if (!_isDominican) return true;
    final d = raw.replaceAll(RegExp(r'\D'), '');
    return _isCompany ? d.length == 9 : d.length == 11;
  }

  bool get _canContinue =>
      _selectedType != null &&
      _nameCtrl.text.trim().length >= 2 &&
      _taxIdValid;

  String? get _taxIdBadge {
    if (!_isDominican) return null;
    final d = _taxIdCtrl.text.replaceAll(RegExp(r'\D'), '');
    if (_isCompany  && d.length == 9)  return 'RNC válido';
    if (!_isCompany && d.length == 11) return 'Cédula válida';
    return null;
  }

  Color get _accentColor {
    if (_selectedType == null) return AppColors.accentBlue;
    return _typeColor(_selectedType!);
  }

  // ── Navegación ────────────────────────────────────────────────────────────

  void _next() {
    widget.data.clientType = _selectedType;
    widget.data.name       = _nameCtrl.text.trim();
    widget.data.taxId      = _taxIdCtrl.text.trim();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => Step2LocationScreen(data: widget.data),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isCompany = _isCompany;

    return OnboardingScaffold(
      step: 1,
      totalSteps: 2,
      title: 'Tu identidad fiscal',
      subtitle: 'Selecciona tu tipo de cliente, tu nombre\ny tu número de identificación.',
      canContinue: _canContinue,
      onContinue: _next,
      onBack: () async {
        await FirebaseAuth.instance.signOut();
        if (!context.mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute<void>(builder: (_) => const LoginScreen()),
          (_) => false,
        );
      },
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Tipo de cliente ──────────────────────────────────────────
            const _SectionLabel('Tipo de cliente'),
            const SizedBox(height: 10),
            DropdownButtonFormField<ClientType>(
              value: _selectedType,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textMuted,
              ),
              hint: const Row(
                children: [
                  SizedBox(width: 4),
                  Icon(Icons.category_outlined,
                      color: AppColors.textMuted, size: 20),
                  SizedBox(width: 10),
                  Text(
                    'Selecciona el tipo de cliente',
                    style: TextStyle(
                      color: AppColors.textMuted,
                      fontSize: 15,
                    ),
                  ),
                ],
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _accentColor, width: 1.5),
                ),
              ),
              selectedItemBuilder: (_) => ClientType.values.map((t) {
                final color = _typeColor(t);
                return Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(7),
                      ),
                      child: Icon(_typeIcon(t),
                          color: Colors.white, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      t.label,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: color,
                      ),
                    ),
                  ],
                );
              }).toList(),
              items: ClientType.values.map((t) {
                final color = _typeColor(t);
                return DropdownMenuItem<ClientType>(
                  value: t,
                  child: Row(
                    children: [
                      Container(
                        width: 34,
                        height: 34,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: Icon(_typeIcon(t), color: color, size: 18),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              t.label,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            Text(
                              _typeDescription(t),
                              style: const TextStyle(
                                fontSize: 11,
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (t) {
                setState(() {
                  _selectedType = t;
                  // Limpiar el taxId al cambiar tipo para evitar que
                  // quede un RNC en el campo de cédula o vice versa.
                  _taxIdCtrl.clear();
                });
                if (t != null) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _nameCtrl.text.trim().isEmpty
                        ? _nameFocus.requestFocus()
                        : _taxFocus.requestFocus();
                  });
                }
              },
            ),

            const SizedBox(height: 26),

            // ── Datos de identificación ───────────────────────────────────
            const _SectionLabel('Datos de identificación'),
            const SizedBox(height: 12),

            // Nombre
            RoundedTextField(
              controller: _nameCtrl,
              focusNode: _nameFocus,
              hint: isCompany ? 'Razón social' : 'Nombre y apellido',
              icon: isCompany ? Icons.apartment : Icons.person_outline,
              iconColor: isCompany
                  ? const Color(0xFFE53935)
                  : const Color(0xFF43A047),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _taxFocus.requestFocus(),
            ),

            const SizedBox(height: 12),

            // RNC / Cédula / Tax ID
            TextField(
              controller: _taxIdCtrl,
              focusNode: _taxFocus,
              keyboardType: _isDominican
                  ? TextInputType.number
                  : TextInputType.text,
              inputFormatters: _isDominican
                  ? [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(isCompany ? 9 : 11),
                      _TaxIdFormatter(isCompany: isCompany),
                    ]
                  : null,
              onSubmitted: (_) {
                if (_canContinue) _next();
              },
              style: const TextStyle(
                fontSize: 16,
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
              ),
              decoration: InputDecoration(
                hintText: !_isDominican
                    ? 'Tax ID / VAT / EIN'
                    : isCompany
                        ? '000-00000-0'
                        : '000-0000000-0',
                hintStyle: const TextStyle(
                  color: AppColors.textMuted,
                  letterSpacing: 1.0,
                ),
                prefixIcon: Icon(
                  isCompany
                      ? Icons.business_outlined
                      : Icons.badge_outlined,
                  color: _accentColor,
                  size: 22,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 18,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.border,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: _accentColor, width: 1.5),
                ),
              ),
            ),

            // Badge de validación
            const SizedBox(height: 8),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: _taxIdBadge == null
                  ? const SizedBox.shrink()
                  : Container(
                      key: ValueKey(_taxIdBadge),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 7,
                      ),
                      decoration: BoxDecoration(
                        color: _accentColor.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(99),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle,
                              color: _accentColor, size: 15),
                          const SizedBox(width: 5),
                          Text(
                            _taxIdBadge!,
                            style: TextStyle(
                              color: _accentColor,
                              fontWeight: FontWeight.w600,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}

// ─── Tarjeta compacta de tipo de cliente (grid 2×2) ───────────────────────────

Color _typeColor(ClientType type) {
  switch (type) {
    case ClientType.empresa:       return const Color(0xFFE53935);
    case ClientType.zonaFranca:    return const Color(0xFF1E88E5);
    case ClientType.gubernamental: return const Color(0xFF6D4C41);
    case ClientType.personaFisica: return const Color(0xFF43A047);
  }
}

IconData _typeIcon(ClientType type) {
  switch (type) {
    case ClientType.empresa:       return Icons.business_center_outlined;
    case ClientType.zonaFranca:    return Icons.local_shipping_outlined;
    case ClientType.gubernamental: return Icons.account_balance_outlined;
    case ClientType.personaFisica: return Icons.person_outline;
  }
}

String _typeDescription(ClientType type) {
  switch (type) {
    case ClientType.empresa:       return 'Negocios privados con RNC activo';
    case ClientType.zonaFranca:    return 'Empresas operando en zonas francas';
    case ClientType.gubernamental: return 'Instituciones del estado y municipales';
    case ClientType.personaFisica: return 'Cuenta individual con cédula';
  }
}

// ─── Label de sección ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text.toUpperCase(),
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w700,
        color: AppColors.textMuted,
        letterSpacing: 0.8,
      ),
    );
  }
}

// ─── Formatter para RNC (000-00000-0) y Cédula (000-0000000-0) ───────────────

class _TaxIdFormatter extends TextInputFormatter {
  const _TaxIdFormatter({required this.isCompany});
  final bool isCompany;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldV,
    TextEditingValue newV,
  ) {
    final d   = newV.text.replaceAll(RegExp(r'\D'), '');
    final buf = StringBuffer();

    if (isCompany) {
      // RNC: 000-00000-0  (guiones en posición 3 y 8)
      for (var i = 0; i < d.length; i++) {
        if (i == 3 || i == 8) buf.write('-');
        buf.write(d[i]);
      }
    } else {
      // Cédula: 000-0000000-0  (guiones en posición 3 y 10)
      for (var i = 0; i < d.length; i++) {
        if (i == 3 || i == 10) buf.write('-');
        buf.write(d[i]);
      }
    }

    final f = buf.toString();
    return TextEditingValue(
      text: f,
      selection: TextSelection.collapsed(offset: f.length),
    );
  }
}
