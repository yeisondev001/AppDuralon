import 'package:flutter/material.dart';

class AdminSectionLabel extends StatelessWidget {
  const AdminSectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: Color(0xFF8A94A6),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}
