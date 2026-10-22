import 'package:flutter/material.dart';

import '../../core/palette.dart';

class OverlayPanel extends StatelessWidget {
  const OverlayPanel({super.key, required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Palette.backgroundVeil,
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: children,
      ),
    );
  }
}

class OverlayButton extends StatelessWidget {
  const OverlayButton(this.label, this.onTap, {super.key, this.primary = true});
  final String label;
  final VoidCallback onTap;
  final bool primary;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: FilledButton(
        style: FilledButton.styleFrom(
          backgroundColor: primary ? Palette.accent : Palette.surface,
          foregroundColor: primary ? Palette.background : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 14),
        ),
        onPressed: onTap,
        child: Text(label,
            style: const TextStyle(
                fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1)),
      ),
    );
  }
}
