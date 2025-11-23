import 'package:flutter/material.dart';
import 'package:food_point/ui/core/themes/app_theme.dart';

class CustomInputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final IconData? icon;
  final TextInputType keyboardType;
  final bool enabled;
  final String? Function(String?)? validator;

  const CustomInputField({
    super.key,
    required this.label,
    required this.controller,
    this.icon,
    this.keyboardType = TextInputType.text,
    this.enabled = true,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          enabled: enabled,
          validator: validator,
          decoration: InputDecoration(
            prefixIcon: icon != null ? Icon(icon, color: Colors.grey) : null,
            // Solo sobrescribimos esto, lo demás viene del AppTheme
            hintStyle: const TextStyle(color: Colors.black),
          ),
        ),
      ],
    );
  }
}
