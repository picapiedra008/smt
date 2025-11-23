import 'package:flutter/material.dart';

class CustomMessageBanner extends StatelessWidget {
  final String message;
  final bool isError;

  const CustomMessageBanner({
    super.key,
    required this.message,
    this.isError = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color color = isError
        ? Colors.redAccent.shade100
        : Colors.greenAccent.shade100;

    final Color textColor = isError
        ? Colors.red.shade900
        : Colors.green.shade900;

    final IconData icon = isError ? Icons.error : Icons.check_circle;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 18),
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Icon(icon, color: textColor, size: 26),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: FontWeight.w600,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
