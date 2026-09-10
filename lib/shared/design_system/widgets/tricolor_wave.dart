import 'package:flutter/material.dart';

class TricolorWave extends StatelessWidget {
  const TricolorWave({super.key, this.height});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: const CustomPaint(painter: _TricolorWavePainter()),
    );
  }
}

class _TricolorWavePainter extends CustomPainter {
  const _TricolorWavePainter();

  static const Color _saffron = Color(0xFFF4801F);
  static const Color _green = Color(0xFF1E8E3E);

  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double h = size.height;

    final Path green = Path()
      ..moveTo(0, h * 0.72)
      ..quadraticBezierTo(w * 0.28, h * 0.60, w * 0.55, h * 0.70)
      ..quadraticBezierTo(w * 0.82, h * 0.80, w, h * 0.64)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(green, Paint()..color = _green);

    final Path saffron = Path()
      ..moveTo(0, h * 0.66)
      ..quadraticBezierTo(w * 0.28, h * 0.54, w * 0.55, h * 0.64)
      ..quadraticBezierTo(w * 0.82, h * 0.74, w, h * 0.58)
      ..lineTo(w, h * 0.64)
      ..quadraticBezierTo(w * 0.82, h * 0.80, w * 0.55, h * 0.70)
      ..quadraticBezierTo(w * 0.28, h * 0.60, 0, h * 0.72)
      ..close();
    canvas.drawPath(saffron, Paint()..color = _saffron);
  }

  @override
  bool shouldRepaint(covariant _TricolorWavePainter oldDelegate) => false;
}
