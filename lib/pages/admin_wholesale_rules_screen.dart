import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:app_duralon/data/mock_products.dart';
import 'package:app_duralon/models/product.dart';
import 'package:app_duralon/services/product_rules_service.dart';
import 'package:flutter/material.dart';

class AdminWholesaleRulesScreen extends StatefulWidget {
  const AdminWholesaleRulesScreen({super.key});

  @override
  State<AdminWholesaleRulesScreen> createState() => _AdminWholesaleRulesScreenState();
}

class _AdminWholesaleRulesScreenState extends State<AdminWholesaleRulesScreen> {
  final ProductRulesService _rulesService = ProductRulesService();
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
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

  TextEditingController _minControllerFor(Product product) {
    return _minControllers.putIfAbsent(
      product.id,
      () => TextEditingController(text: product.minOrderQty.toString()),
    );
  }

  TextEditingController _stepControllerFor(Product product) {
    return _stepControllers.putIfAbsent(
      product.id,
      () => TextEditingController(text: product.stepQty.toString()),
    );
  }

  Future<void> _loadExistingRule(Product product) async {
    final existing = await _rulesService.getRuleByProductId(product.id);
    if (!mounted || existing == null) return;
    _minControllerFor(product).text = existing.minOrderQty.toString();
    _stepControllerFor(product).text = existing.stepQty.toString();
  }

  Future<void> _saveRule(Product product) async {
    final minText = _minControllerFor(product).text.trim();
    final stepText = _stepControllerFor(product).text.trim();
    final minQty = int.tryParse(minText);
    final stepQty = int.tryParse(stepText);

    if (minQty == null || minQty <= 0) {
      _showMessage('Minimo invalido para ${product.name}.');
      return;
    }
    if (stepQty == null || stepQty <= 0) {
      _showMessage('Multiplo invalido para ${product.name}.');
      return;
    }

    setState(() => _savingIds.add(product.id));
    try {
      await _firestore.collection('products').doc(product.id).set({
        'name': product.name,
        'category': product.category,
        'minOrderQty': minQty,
        'stepQty': stepQty,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _showMessage('Regla guardada para ${product.name}.');
    } catch (_) {
      _showMessage('No se pudo guardar ${product.name}.');
    } finally {
      if (mounted) {
        setState(() => _savingIds.remove(product.id));
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reglas mayoristas'),
      ),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: mockProducts.length,
        separatorBuilder: (_, _) => const SizedBox(height: 10),
        itemBuilder: (context, index) {
          final product = mockProducts[index];
          final minController = _minControllerFor(product);
          final stepController = _stepControllerFor(product);
          final saving = _savingIds.contains(product.id);
          return Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${product.category} • ID: ${product.id}',
                    style: const TextStyle(color: Colors.black54, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: minController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Minimo',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: TextField(
                          controller: stepController,
                          keyboardType: TextInputType.number,
                          decoration: const InputDecoration(
                            labelText: 'Multiplo',
                            border: OutlineInputBorder(),
                            isDense: true,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      OutlinedButton(
                        onPressed: () => _loadExistingRule(product),
                        child: const Text('Cargar Firebase'),
                      ),
                      const SizedBox(width: 10),
                      FilledButton(
                        onPressed: saving ? null : () => _saveRule(product),
                        child: saving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : const Text('Guardar'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
