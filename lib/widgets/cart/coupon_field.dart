import 'package:app_duralon/styles/app_style.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class CouponField extends StatefulWidget {
  const CouponField({
    super.key,
    required this.onApply,
    required this.onClear,
    this.codigo,
    this.etiqueta,
    this.invalido = false,
  });

  final void Function(String) onApply;
  final VoidCallback onClear;
  final String? codigo;
  final String? etiqueta;
  final bool invalido;

  @override
  State<CouponField> createState() => _CouponFieldState();
}

class _CouponFieldState extends State<CouponField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: SizedBox(
                height: 44,
                child: TextField(
                  controller: _controller,
                  textCapitalization: TextCapitalization.characters,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[A-Za-z0-9]')),
                  ],
                  style: const TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                  ),
                  decoration: InputDecoration(
                    hintText: 'CÓDIGO DE DESCUENTO',
                    hintStyle: TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 13,
                      color: Colors.grey.shade400,
                      letterSpacing: 1,
                    ),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14),
                    filled: true,
                    fillColor: Colors.white,
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
                      borderSide:
                          BorderSide(color: AppColors.primaryBlue, width: 1.5),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              height: 44,
              child: ElevatedButton(
                onPressed: () => widget.onApply(_controller.text),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1C1C1C),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Aplicar',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
        if (widget.codigo != null) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: widget.invalido
                  ? const Color(0xFFFFE5E8)
                  : const Color(0xFFFFF9C4),
              border: Border.all(
                color: widget.invalido
                    ? AppColors.primaryRed
                    : AppColors.primaryYellow,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Text(
                  widget.codigo!,
                  style: TextStyle(
                    fontFamily: 'monospace',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: widget.invalido
                        ? const Color(0xFF991B1B)
                        : const Color(0xFF854D0E),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    widget.etiqueta ?? '',
                    style: TextStyle(
                      fontSize: 12,
                      color: widget.invalido
                          ? const Color(0xFF991B1B)
                          : const Color(0xFF854D0E),
                    ),
                  ),
                ),
                InkWell(
                  onTap: () {
                    _controller.clear();
                    widget.onClear();
                  },
                  child: Icon(
                    Icons.close,
                    size: 16,
                    color: widget.invalido
                        ? const Color(0xFF991B1B)
                        : const Color(0xFF854D0E),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
