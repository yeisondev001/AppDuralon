import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/services/product_service.dart';
import 'package:app_duralon/styles/app_style.dart';
import 'package:flutter/material.dart';

class AdminWholesaleRulesScreen extends StatefulWidget {
  const AdminWholesaleRulesScreen({super.key});

  @override
  State<AdminWholesaleRulesScreen> createState() =>
      _AdminWholesaleRulesScreenState();
}

class _AdminWholesaleRulesScreenState
    extends State<AdminWholesaleRulesScreen> {
  final Map<String, TextEditingController> _minControllers = {};
  final Map<String, TextEditingController> _stepControllers = {};
  final Set<String> _savingIds = {};

  @override
  void dispose() {
    for (final c in _minControllers.values) {
      c.dispose();
    }
    for (final c in _stepControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  TextEditingController _minControllerFor(Product p) =>
      _minControllers.putIfAbsent(
        p.id,
        () => TextEditingController(text: p.minOrderQty.toString()),
      );

  TextEditingController _stepControllerFor(Product p) =>
      _stepControllers.putIfAbsent(
        p.id,
        () => TextEditingController(text: p.stepQty.toString()),
      );

  Future<void> _saveRule(Product product) async {
    final minQty =
        int.tryParse(_minControllerFor(product).text.trim());
    final stepQty =
        int.tryParse(_stepControllerFor(product).text.trim());

    if (minQty == null || minQty <= 0) {
      _msg('Mínimo inválido para ${product.name}.');
      return;
    }
    if (stepQty == null || stepQty <= 0) {
      _msg('Múltiplo inválido para ${product.name}.');
      return;
    }

    setState(() => _savingIds.add(product.id));
    try {
      await ProductService.update(product.id, {
        'minOrderQty': minQty,
        'stepQty': stepQty,
      });
      _msg('Regla guardada para ${product.name}.');
    } catch (_) {
      _msg('No se pudo guardar ${product.name}.');
    } finally {
      if (mounted) setState(() => _savingIds.remove(product.id));
    }
  }

  void _msg(String text) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(text)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF3F5F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Color(0xFF1A2230)),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Reglas mayoristas',
          style: TextStyle(
              color: Color(0xFF1A2230),
              fontWeight: FontWeight.w700,
              fontSize: 18),
        ),
        centerTitle: true,
      ),
      body: StreamBuilder<List<Product>>(
        stream: ProductService.streamAdmin(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                  color: AppColors.primaryBlue),
            );
          }
          final products = snapshot.data!;
          if (products.isEmpty) {
            return const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'No hay productos en Firebase aún.\nAgrégalos desde el Panel de administración.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Color(0xFF8A94A6)),
                ),
              ),
            );
          }
          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            itemCount: products.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final product = products[i];
              final saving = _savingIds.contains(product.id);
              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(14),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2230)),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${product.category} • ID: ${product.id}',
                        style: const TextStyle(
                            color: Color(0xFF8A94A6), fontSize: 12),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _minControllerFor(product),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Mínimo',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: TextField(
                              controller: _stepControllerFor(product),
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(
                                labelText: 'Múltiplo',
                                border: OutlineInputBorder(),
                                isDense: true,
                                contentPadding: EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primaryBlue),
                          onPressed:
                              saving ? null : () => _saveRule(product),
                          child: saving
                              ? const SizedBox(
                                  width: 16,
                                  height: 16,
                                  child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white),
                                )
                              : const Text('Guardar regla'),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
