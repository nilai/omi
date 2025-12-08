import 'package:flutter/material.dart';

/// A button widget for BLE debug commands
class CommandButton extends StatelessWidget {
  final String title;
  final String hexCode;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool isDangerous;

  const CommandButton({
    super.key,
    required this.title,
    required this.hexCode,
    this.onPressed,
    this.isLoading = false,
    this.isDangerous = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: isDangerous
            ? Colors.red.withValues(alpha: 0.15)
            : const Color(0xFF2A2A2E),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onPressed,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          color: isDangerous ? Colors.red.shade300 : Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hexCode,
                        style: TextStyle(
                          color: Colors.grey.shade500,
                          fontSize: 12,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLoading)
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  Icon(
                    Icons.send,
                    color: onPressed != null
                        ? (isDangerous ? Colors.red.shade300 : Colors.white54)
                        : Colors.grey.shade700,
                    size: 18,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
