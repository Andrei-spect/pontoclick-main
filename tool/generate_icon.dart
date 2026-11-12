// Gera as imagens-base do ícone do app a partir do logo (relógio no violeta).
//
//   flutter test tool/generate_icon.dart
//   dart run flutter_launcher_icons
//
// Saída em assets/icon/: icon.png (ícone completo, 1024 px) e
// icon_foreground.png (só o relógio, fundo transparente, para o ícone
// adaptativo do Android, que usa a cor de fundo definida no pubspec.yaml).
import 'dart:io';
import 'dart:math' as math;
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';

const _size = 1024.0;
const _violet = Color(0xFF5351F3);
const _violetDark = Color(0xFF3F3DD6);
const _peach = Color(0xFFE3A081);
const _white = Color(0xFFFFFFFF);

/// Desenha o relógio centralizado, com raio [radius].
void _paintClock(Canvas canvas, double radius) {
  const c = Offset(_size / 2, _size / 2);

  // Mostrador branco.
  canvas.drawCircle(c, radius, Paint()..color = _white);

  // Marcas das 12, 3, 6 e 9 horas.
  final tick = Paint()
    ..color = _violet.withValues(alpha: 0.35)
    ..strokeWidth = radius * 0.06
    ..strokeCap = StrokeCap.round;
  for (var i = 0; i < 4; i++) {
    final a = i * math.pi / 2;
    final dir = Offset(math.sin(a), -math.cos(a));
    canvas.drawLine(c + dir * radius * 0.78, c + dir * radius * 0.88, tick);
  }

  // Ponteiros (horário ~10:10, o mais legível) em violeta.
  final hand = Paint()
    ..color = _violetDark
    ..strokeCap = StrokeCap.round;
  void drawHand(double angleDeg, double length, double width) {
    final a = angleDeg * math.pi / 180;
    hand.strokeWidth = width;
    canvas.drawLine(c, c + Offset(math.sin(a), -math.cos(a)) * length, hand);
  }

  drawHand(-60, radius * 0.48, radius * 0.13); // horas
  drawHand(60, radius * 0.66, radius * 0.10); // minutos

  // Centro em pêssego (a cor de destaque do app).
  canvas.drawCircle(c, radius * 0.11, Paint()..color = _peach);
}

Future<void> _save(String path, void Function(Canvas) paint) async {
  final recorder = ui.PictureRecorder();
  paint(Canvas(recorder));
  final image = await recorder.endRecording().toImage(_size.toInt(), _size.toInt());
  final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
  await File(path).create(recursive: true);
  await File(path).writeAsBytes(bytes!.buffer.asUint8List());
}

void main() {
  testWidgets('gera assets/icon/*.png', (tester) async {
    await tester.runAsync(() async {
      // Ícone completo: fundo violeta (sem transparência, exigência da App Store) + relógio.
      await _save('assets/icon/icon.png', (canvas) {
        final rect = const Rect.fromLTWH(0, 0, _size, _size);
        canvas.drawRect(
          rect,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF6563F6), _violet],
            ).createShader(rect),
        );
        _paintClock(canvas, _size * 0.31);
      });

      // Primeiro plano do ícone adaptativo do Android. O flutter_launcher_icons já aplica
      // uma margem de 16% e o sistema recorta as bordas; com raio de 31% o relógio
      // fica do mesmo tamanho visual do ícone completo e dentro da área segura.
      await _save('assets/icon/icon_foreground.png', (canvas) => _paintClock(canvas, _size * 0.31));
    });
  });
}
