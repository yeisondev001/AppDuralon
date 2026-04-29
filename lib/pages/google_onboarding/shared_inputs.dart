import 'package:flutter/material.dart';
import 'package:app_duralon/pages/google_onboarding/app_colors.dart';

class RoundedTextField extends StatelessWidget {
  const RoundedTextField({
    super.key,
    required this.controller,
    required this.focusNode,
    required this.hint,
    required this.icon,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.onSubmitted,
    this.maxLength,
    this.inputFormatters,
    this.letterSpacing,
    this.fontWeight = FontWeight.w500,
    this.iconColor = AppColors.accentBlue,
    this.iconBackgroundColor,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final String hint;
  final IconData icon;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final ValueChanged<String>? onSubmitted;
  final int? maxLength;
  final List<dynamic>? inputFormatters;
  final double? letterSpacing;
  final FontWeight fontWeight;
  final Color iconColor;
  final Color? iconBackgroundColor;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      focusNode: focusNode,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      maxLength: maxLength,
      onSubmitted: onSubmitted,
      inputFormatters: inputFormatters?.cast(),
      style: TextStyle(
        fontSize: 16,
        color: AppColors.textPrimary,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
      ),
      decoration: InputDecoration(
        counterText: '',
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textMuted,
          letterSpacing: letterSpacing,
        ),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 8, right: 8),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: iconBackgroundColor ?? iconColor.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
        ),
        filled: true,
        fillColor: AppColors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 18,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.border, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.accentBlue, width: 1.5),
        ),
      ),
    );
  }
}
