// Gera as imagens-base do ícone do app a partir da marca (cronômetro com visto,
// desenhada em lib/brand_mark.dart, a mesma usada dentro do app).
//
//   flutter test tool/generate_icon.dart
//   dart run flutter_launcher_icons
//
// Saída em assets/icon/: icon.png (ícone completo, 1024 px) e
// icon_foreground.png (só a marca, fundo transparente, para o ícone
// adaptativo do Android, que usa a cor de fundo definida no pubspec.yaml).
import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/painting.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pontoclick/brand_mark.dart';

const _size = 1024.0;

// Centro um pouco abaixo do meio: o aro + a coroa do cronômetro ficam centralizados.
const _center = Offset(_size / 2, _size / 2 + _size * 0.035);

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
      // Ícone completo: fundo violeta em degradê (sem transparência, exigência da App Store)
      // com um brilho suave no canto superior esquerdo, e a marca em branco.
      await _save('assets/icon/icon.png', (canvas) {
        const rect = Rect.fromLTWH(0, 0, _size, _size);
        canvas.drawRect(
          rect,
          Paint()
            ..shader = const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF7472FF), Color(0xFF5351F3), Color(0xFF3B38D2)],
              stops: [0, 0.5, 1],
            ).createShader(rect),
        );
        canvas.drawRect(
          rect,
          Paint()
            ..shader = RadialGradient(
              center: const Alignment(-0.7, -0.8),
              radius: 0.9,
              colors: [const Color(0xFFFFFFFF).withValues(alpha: 0.22), const Color(0x00FFFFFF)],
            ).createShader(rect),
        );
        paintBrandMark(canvas, _center, _size * 0.27);
      });

      // Primeiro plano do ícone adaptativo do Android. O flutter_launcher_icons já aplica
      // uma margem e o sistema recorta as bordas; este tamanho fica dentro da área segura.
      await _save('assets/icon/icon_foreground.png', (canvas) => paintBrandMark(canvas, _center, _size * 0.27));
    });
  });
}
