import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Avatar redondo: mostra a foto do usuário e, se não houver (ou se não
/// conseguir carregar), as iniciais.
class AppAvatar extends StatelessWidget {
  final String initials;
  final String? imageUrl;
  final double size;
  final Color? backgroundColor;

  const AppAvatar({
    super.key,
    required this.initials,
    this.imageUrl,
    this.size = 40,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    final initialsText = Text(
      initials,
      style: AppText.body(weight: FontWeight.w600, color: context.violetText).copyWith(fontSize: size * 0.32),
    );

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: backgroundColor ?? context.violetSoft,
      ),
      child: imageUrl == null
          ? initialsText
          : Image.network(
              imageUrl!,
              width: size,
              height: size,
              fit: BoxFit.cover,
              // Enquanto carrega, ou se a foto falhar, mostra as iniciais.
              loadingBuilder: (context, child, progress) => progress == null ? child : initialsText,
              errorBuilder: (context, error, stackTrace) => initialsText,
            ),
    );
  }
}
