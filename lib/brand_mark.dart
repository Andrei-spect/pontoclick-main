import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Marca do PontoClick: um cronômetro cujos ponteiros formam um "✓"
/// (hora marcada + ponto confirmado), com o vértice em pêssego.
///
/// Usada no ícone do app (tool/generate_icon.dart) e na marca dentro do app
/// ([BrandMark]), para os dois ficarem idênticos.
void paintBrandMark(
  Canvas canvas,
  Offset center,
  double radius, {
  Color line = Colors.white,
  Color accent = const Color(0xFFE3A081),
}) {
  final stroke = radius * 0.17;

  // Aro do cronômetro.
  canvas.drawCircle(
    center,
    radius,
    Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke,
  );

  // Botão no topo (a "coroa" do cronômetro).
  final crown = RRect.fromRectAndRadius(
    Rect.fromCenter(
      center: center + Offset(0, -radius - stroke * 1.35),
      width: radius * 0.42,
      height: stroke * 0.95,
    ),
    Radius.circular(stroke * 0.5),
  );
  canvas.drawRRect(crown, Paint()..color = line);
  // Haste ligando o botão ao aro.
  canvas.drawRect(
    Rect.fromCenter(center: center + Offset(0, -radius - stroke * 0.75), width: stroke * 0.7, height: stroke * 0.8),
    Paint()..color = line,
  );

  // Ponteiros em forma de visto: braço curto para cima-esquerda, longo para cima-direita.
  final pivot = center + Offset(-radius * 0.10, radius * 0.22);
  Offset arm(double angleDeg, double length) {
    final a = angleDeg * math.pi / 180;
    return pivot + Offset(math.sin(a), -math.cos(a)) * length;
  }

  final check = Path()
    ..moveTo(arm(-52, radius * 0.40).dx, arm(-52, radius * 0.40).dy)
    ..lineTo(pivot.dx, pivot.dy)
    ..lineTo(arm(38, radius * 0.74).dx, arm(38, radius * 0.74).dy);
  canvas.drawPath(
    check,
    Paint()
      ..color = line
      ..style = PaintingStyle.stroke
      ..strokeWidth = stroke * 1.05
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round,
  );

  // Vértice em pêssego (a cor de destaque do app).
  canvas.drawCircle(pivot, stroke * 0.62, Paint()..color = accent);
}

/// Marca pequena para usar dentro do app: círculo violeta + cronômetro com visto.
class BrandMark extends StatelessWidget {
  final double size;
  const BrandMark({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return SizedBox.square(dimension: size, child: CustomPaint(painter: _BrandMarkPainter()));
  }
}

class _BrandMarkPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    canvas.drawOval(
      rect,
      Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF7472FF), Color(0xFF3F3CD8)],
        ).createShader(rect),
    );
    // Um pouco abaixo do centro, para o conjunto aro + coroa ficar centralizado no círculo.
    paintBrandMark(canvas, size.center(Offset(0, size.height * 0.04)), size.width * 0.27);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
