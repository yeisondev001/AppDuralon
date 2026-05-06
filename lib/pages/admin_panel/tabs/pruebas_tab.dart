import 'package:app_duralon/services/product_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';

class PruebasTab extends StatefulWidget {
  const PruebasTab({super.key});

  @override
  State<PruebasTab> createState() => _PruebasTabState();
}

class _PruebasTabState extends State<PruebasTab> {
  bool _crashlyticsSending = false;
  bool _migrandoPrecios = false;
  String? _resultado;

  Future<void> _enviarErrorPrueba() async {
    setState(() {
      _crashlyticsSending = true;
      _resultado = null;
    });
    try {
      await FirebaseCrashlytics.instance.recordError(
        Exception('Error de prueba desde el panel de admin'),
        StackTrace.current,
        reason: 'Test manual desde PruebasTab',
        fatal: false,
      );
      await FirebaseCrashlytics.instance.sendUnsentReports();
      if (mounted) {
        setState(
          () => _resultado =
              '✓ Reporte enviado. Revisa Firebase Console → Crashlytics.',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _resultado = '✗ Error al enviar: $e');
      }
    } finally {
      if (mounted) setState(() => _crashlyticsSending = false);
    }
  }

  void _forzarCrashFatal() {
    showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Crash fatal'),
        content: const Text(
          'Esto cerrará la app inmediatamente.\n'
          'Vuelve a abrirla para que se envíe el reporte a Firebase.\n\n'
          '¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            style: TextButton.styleFrom(
              foregroundColor: const Color(0xFFC62828),
            ),
            onPressed: () {
              Navigator.pop(ctx, true);
              Future<void>.delayed(const Duration(milliseconds: 300), () {
                FirebaseCrashlytics.instance.crash();
              });
            },
            child: const Text('Sí, crashear'),
          ),
        ],
      ),
    );
  }

  Future<void> _migrarPriceAPrecioAleatorio() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Migrar colección products'),
        content: const Text(
          'Esto actualizará todos los productos en Firebase:\n\n'
          '- Elimina el campo "price"\n'
          '- Escribe un nuevo campo "precio" con valor aleatorio\n\n'
          'Esta acción es para pruebas. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Sí, migrar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    setState(() {
      _migrandoPrecios = true;
      _resultado = null;
    });

    try {
      final total = await ProductService.migratePriceToPrecioWithRandomValues();
      if (!mounted) return;
      setState(() {
        _resultado = '✓ Migración completada. Productos actualizados: $total';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _resultado = '✗ Error en migración de precios: $e';
      });
    } finally {
      if (mounted) setState(() => _migrandoPrecios = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // ── Card: Crashlytics ─────────────────────────────────────
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 16, 18, 0),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFF3E0),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.bug_report_outlined,
                        color: Color(0xFFE65100),
                      ),
                    ),
                    const SizedBox(width: 12),
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Firebase Crashlytics',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2230),
                          ),
                        ),
                        Text(
                          'Prueba el reporte de errores',
                          style: TextStyle(
                            fontSize: 12,
                            color: Color(0xFF8A94A6),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(height: 24, indent: 18, endIndent: 18),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 0, 18, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Error no fatal',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2230),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Envía un error de prueba a Firebase sin cerrar la app. '
                      'Aparece en Crashlytics como "Non-fatal".',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFE65100),
                          side: const BorderSide(color: Color(0xFFE65100)),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _crashlyticsSending
                            ? null
                            : _enviarErrorPrueba,
                        icon: _crashlyticsSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Color(0xFFE65100),
                                ),
                              )
                            : const Icon(Icons.send_outlined),
                        label: const Text('Enviar error de prueba'),
                      ),
                    ),
                    if (_resultado != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _resultado!.startsWith('✓')
                              ? const Color(0xFFE8F5E9)
                              : const Color(0xFFFFEBEE),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _resultado!,
                          style: TextStyle(
                            fontSize: 12,
                            color: _resultado!.startsWith('✓')
                                ? const Color(0xFF2E7D32)
                                : const Color(0xFFC62828),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const Divider(height: 1, indent: 18, endIndent: 18),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Crash fatal',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2230),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Cierra la app inmediatamente. Vuelve a abrirla para '
                      'que se envíe el reporte. Aparece en Crashlytics como "Fatal".',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFC62828),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _forzarCrashFatal,
                        icon: const Icon(Icons.warning_amber_rounded),
                        label: const Text(
                          'Forzar crash fatal',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1, indent: 18, endIndent: 18),
              Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Firestore products (migración de prueba)',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF1A2230),
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Renombra campo price a precio y asigna precios aleatorios '
                      'en todos los documentos de products.',
                      style: TextStyle(fontSize: 12, color: Color(0xFF8A94A6)),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primaryBlue,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                        ),
                        onPressed: _migrandoPrecios
                            ? null
                            : _migrarPriceAPrecioAleatorio,
                        icon: _migrandoPrecios
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.swap_horiz_rounded),
                        label: Text(
                          _migrandoPrecios
                              ? 'Migrando precios...'
                              : 'Migrar price -> precio + aleatorio',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFE3F2FD),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.primaryBlue,
                size: 18,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Los reportes aparecen en Firebase Console → Crashlytics '
                  'en 1-2 minutos. En modo debug los errores no fatales '
                  'se envían, pero los crashes fatales requieren modo release.',
                  style: TextStyle(fontSize: 12, color: AppColors.primaryBlue),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
