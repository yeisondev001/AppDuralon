// =============================================================================
// Pantalla 2 de 2 — Ubicación y contacto
// Agrupa: País · Ciudad · Dirección fiscal · Teléfono
// Último paso: guarda los datos en Firestore al finalizar.
// =============================================================================
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:app_duralon/pages/google_onboarding/app_colors.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_data.dart';
import 'package:app_duralon/pages/google_onboarding/onboarding_scaffold.dart';
import 'package:app_duralon/pages/google_onboarding/shared_inputs.dart';
import 'package:app_duralon/pages/home_screen.dart';
import 'package:app_duralon/services/auth_service.dart';
import 'package:app_duralon/utils/slide_right_route.dart';

// ─── Lista de países ──────────────────────────────────────────────────────────

const _kCountries = <_Country>[
  _Country('República Dominicana', '🇩🇴'),
  _Country('Puerto Rico', '🇵🇷'),
  _Country('Costa Rica', '🇨🇷'),
  _Country('Canadá', '🇨🇦'),
  _Country('Estados Unidos', '🇺🇸'),
  _Country('Panamá', '🇵🇦'),
  _Country('Trinidad y Tobago', '🇹🇹'),
  _Country('Haití', '🇭🇹'),
  _Country('Aruba', '🇦🇼'),
  _Country('Jamaica', '🇯🇲'),
  _Country('Barbados', '🇧🇧'),
];

class _Country {
  final String name;
  final String flag;
  const _Country(this.name, this.flag);
}

// ─── Pantalla ─────────────────────────────────────────────────────────────────

class Step2LocationScreen extends StatefulWidget {
  const Step2LocationScreen({super.key, required this.data});
  final OnboardingData data;

  @override
  State<Step2LocationScreen> createState() => _Step2LocationScreenState();
}

class _Step2LocationScreenState extends State<Step2LocationScreen> {
  final _authService = AuthService();

  late String _country;
  late final TextEditingController _cityCtrl;
  late final TextEditingController _addressCtrl;
  late final TextEditingController _phoneCtrl;

  final FocusNode _cityFocus = FocusNode();
  final FocusNode _addressFocus = FocusNode();
  final FocusNode _phoneFocus = FocusNode();

  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _country = widget.data.country;
    _cityCtrl = TextEditingController(text: widget.data.city ?? '');
    _addressCtrl = TextEditingController(text: widget.data.address ?? '');
    _phoneCtrl = TextEditingController(text: widget.data.phone ?? '');

    _cityCtrl.addListener(() => setState(() {}));
    _addressCtrl.addListener(() => setState(() {}));
    _phoneCtrl.addListener(() => setState(() {}));

    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _cityFocus.requestFocus(),
    );
  }

  @override
  void dispose() {
    _cityCtrl.dispose();
    _addressCtrl.dispose();
    _phoneCtrl.dispose();
    _cityFocus.dispose();
    _addressFocus.dispose();
    _phoneFocus.dispose();
    super.dispose();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  bool get _canFinish =>
      _country.isNotEmpty &&
      _cityCtrl.text.trim().length >= 2 &&
      _addressCtrl.text.trim().length >= 5 &&
      _phoneCtrl.text.trim().isNotEmpty &&
      !_saving;

  String _taxpayerType(ClientType? t) {
    switch (t) {
      case ClientType.empresa:
        return 'empresa';
      case ClientType.zonaFranca:
        return 'zona_franca';
      case ClientType.gubernamental:
        return 'gubernamental';
      default:
        return 'persona_fisica';
    }
  }

  // ── Guardar en Firebase ───────────────────────────────────────────────────

  Future<void> _finish() async {
    if (!_canFinish) return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    widget.data.country = _country;
    widget.data.city = _cityCtrl.text.trim();
    widget.data.address = _addressCtrl.text.trim();
    widget.data.phone = _phoneCtrl.text.trim();

    setState(() => _saving = true);
    try {
      await _authService.completeGoogleCustomerOnboarding(
        user: user,
        taxpayerType: _taxpayerType(widget.data.clientType),
        fullName: widget.data.name ?? '',
        identification: widget.data.taxId ?? '',
        city: widget.data.city ?? '',
        country: widget.data.country,
        phone: widget.data.phone ?? '',
        fiscalAddress: widget.data.address ?? '',
      );
      if (!mounted) return;
      Navigator.pushAndRemoveUntil<void>(
        context,
        slideRightRoute<void>(const HomeScreen(isGuestMode: false)),
        (route) => false,
      );
    } on DuplicateIdentificationException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Esa identificación ya está registrada.')),
      );
    } on InvalidIdentificationException {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Identificación inválida. Verifica el RNC o Cédula ingresado.',
          ),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      // Muestra el código Firebase para facilitar el diagnóstico
      final msg = e.code == 'permission-denied'
          ? 'Sin permisos en Firestore. Verifica las reglas de seguridad.'
          : 'Error Firebase [${e.code}]: ${e.message}';
      debugPrint('FirebaseException en onboarding: $e');
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
    } catch (e) {
      if (!mounted) return;
      debugPrint('Error inesperado en onboarding: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            kDebugMode
                ? 'Error: $e'
                : 'No se pudo completar el registro. Inténtalo de nuevo.',
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  // ── Selector de país (bottom sheet) ──────────────────────────────────────

  void _showCountryPicker() {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.white,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (ctx) {
        String query = '';
        return StatefulBuilder(
          builder: (ctx, setModal) {
            final filtered = _kCountries
                .where(
                  (c) => c.name.toLowerCase().contains(query.toLowerCase()),
                )
                .toList();
            return DraggableScrollableSheet(
              expand: false,
              initialChildSize: 0.6,
              maxChildSize: 0.85,
              builder: (_, scrollCtrl) => Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
                child: Column(
                  children: [
                    // Handle
                    Center(
                      child: Container(
                        width: 36,
                        height: 4,
                        decoration: BoxDecoration(
                          color: AppColors.border,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    const Text(
                      'Selecciona tu país',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 14),
                    // Búsqueda
                    TextField(
                      onChanged: (v) => setModal(() => query = v),
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: 'Buscar país…',
                        hintStyle: const TextStyle(color: AppColors.textMuted),
                        prefixIcon: const Icon(
                          Icons.search,
                          color: AppColors.accentBlue,
                          size: 20,
                        ),
                        filled: true,
                        fillColor: AppColors.surface,
                        isDense: true,
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: AppColors.accentBlue,
                            width: 1.5,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    // Lista
                    Expanded(
                      child: ListView.separated(
                        controller: scrollCtrl,
                        itemCount: filtered.length,
                        separatorBuilder: (_, _) => const SizedBox(height: 6),
                        itemBuilder: (_, i) {
                          final c = filtered[i];
                          final sel = _country == c.name;
                          return Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(12),
                              onTap: () {
                                setState(() => _country = c.name);
                                Navigator.pop(ctx);
                              },
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 150),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 11,
                                ),
                                decoration: BoxDecoration(
                                  color: sel
                                      ? AppColors.accentBlue.withValues(
                                          alpha: 0.08,
                                        )
                                      : AppColors.surface,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: sel
                                        ? AppColors.accentBlue
                                        : AppColors.border,
                                    width: sel ? 1.5 : 1,
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Text(
                                      c.flag,
                                      style: const TextStyle(fontSize: 20),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        c.name,
                                        style: const TextStyle(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: AppColors.textPrimary,
                                        ),
                                      ),
                                    ),
                                    if (sel)
                                      const Icon(
                                        Icons.check_circle,
                                        color: AppColors.accentBlue,
                                        size: 18,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final selectedCountry = _kCountries.firstWhere(
      (c) => c.name == _country,
      orElse: () => _Country(_country, '🌎'),
    );

    return OnboardingScaffold(
      step: 2,
      totalSteps: 2,
      title: 'Ubicación y contacto',
      subtitle: 'Dinos dónde encontrarte y\ncómo comunicarnos contigo.',
      canContinue: _canFinish,
      continueLabel: _saving ? 'Guardando...' : 'Finalizar',
      onContinue: _finish,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── País ─────────────────────────────────────────────────────
            const _SectionLabel('País'),
            const SizedBox(height: 10),
            GestureDetector(
              onTap: _showCountryPicker,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.border, width: 1),
                ),
                child: Row(
                  children: [
                    Text(
                      selectedCountry.flag,
                      style: const TextStyle(fontSize: 22),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        selectedCountry.name,
                        style: const TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                    const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ── Dirección ────────────────────────────────────────────────
            const _SectionLabel('Dirección'),
            const SizedBox(height: 12),

            // Ciudad
            RoundedTextField(
              controller: _cityCtrl,
              focusNode: _cityFocus,
              hint: 'Ciudad (ej: Santo Domingo)',
              icon: Icons.location_city_outlined,
              iconColor: const Color(0xFF8E24AA),
              textCapitalization: TextCapitalization.words,
              onSubmitted: (_) => _addressFocus.requestFocus(),
            ),

            const SizedBox(height: 12),

            // Dirección fiscal — campo de 2 líneas
            TextField(
              controller: _addressCtrl,
              focusNode: _addressFocus,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              onSubmitted: (_) => _phoneFocus.requestFocus(),
              style: const TextStyle(
                fontSize: 15,
                color: AppColors.textPrimary,
              ),
              decoration: InputDecoration(
                hintText: 'Dirección fiscal completa\n(Calle, número, sector)',
                hintStyle: const TextStyle(color: AppColors.textMuted),
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(
                    left: 8,
                    right: 8,
                    top: 12,
                    bottom: 12,
                  ),
                  child: Icon(
                    Icons.home_outlined,
                    color: Color(0xFFFB8C00),
                    size: 20,
                  ),
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 52,
                  minHeight: 0,
                ),
                filled: true,
                fillColor: AppColors.surface,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
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
                  borderSide: const BorderSide(
                    color: AppColors.accentBlue,
                    width: 1.5,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ── Contacto ─────────────────────────────────────────────────
            const _SectionLabel('Contacto'),
            const SizedBox(height: 12),

            // Teléfono
            RoundedTextField(
              controller: _phoneCtrl,
              focusNode: _phoneFocus,
              hint: '(809) 000-0000',
              icon: Icons.phone_outlined,
              iconColor: const Color(0xFF43A047),
              keyboardType: TextInputType.phone,
              letterSpacing: 1.0,
              fontWeight: FontWeight.w600,
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9()+\-\s]')),
                LengthLimitingTextInputFormatter(20),
              ],
              onSubmitted: (_) {
                if (_canFinish) _finish();
              },
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
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
