import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Seta de voltar padrão, usada em todas as telas secundárias.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: Icon(Icons.arrow_back_ios_new_rounded, color: Theme.of(context).colorScheme.onSurface, size: 20),
      onPressed: () => Navigator.pop(context),
      padding: EdgeInsets.zero,
      alignment: Alignment.centerLeft,
    );
  }
}

/// Campo de texto padrão: rótulo + fundo do card + 24px de radius.
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData icon;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;

  const AppTextField({
    super.key,
    required this.label,
    required this.icon,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: AppText.caption(color: context.textSecondary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscureText,
          keyboardType: keyboardType,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          style: AppText.body(color: Theme.of(context).colorScheme.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: AppText.body(color: context.textTertiary),
            prefixIcon: Icon(icon, size: 18, color: context.textSecondary),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.inputs), borderSide: BorderSide.none),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.inputs), borderSide: const BorderSide(color: AppColors.statusRed)),
            focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AppRadius.inputs),
                borderSide: const BorderSide(color: AppColors.statusRed, width: 1.5)),
          ),
        ),
      ],
    );
  }
}

/// Botão principal — a única cor de commit/confirmação do sistema (violeta).
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const AppPrimaryButton({super.key, required this.label, required this.onPressed, this.isLoading = false});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 50,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.twilightViolet,
          disabledBackgroundColor: AppColors.twilightViolet.withOpacity(0.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.buttons)),
        ),
        child: isLoading
            ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text(label, style: AppText.body(color: Colors.white, weight: FontWeight.w600).copyWith(fontSize: 14)),
      ),
    );
  }
}

/// Botão secundário — contorno neutro (Ghost Outline Button).
class AppOutlineButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const AppOutlineButton({super.key, required this.label, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurface;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        side: BorderSide(color: color.withOpacity(0.8)),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.buttons)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 13, color: color), const SizedBox(width: 6)],
          Text(label, style: AppText.caption(color: color, weight: FontWeight.w500)),
        ],
      ),
    );
  }
}

/// Rótulo de seção em caixa alta (ex: "CONTA", "SUPORTE").
class AppSectionLabel extends StatelessWidget {
  final String text;
  const AppSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) =>
      Text(text, style: AppText.caption(color: context.textTertiary, weight: FontWeight.w600));
}

class AppMenuItemData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const AppMenuItemData({required this.icon, required this.label, required this.onTap});
}

/// Card com uma lista de itens de menu (ícone + texto + seta), usado no Perfil.
class AppMenuCard extends StatelessWidget {
  final List<AppMenuItemData> items;
  const AppMenuCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppRadius.cards)),
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                borderRadius: BorderRadius.vertical(
                  top: i == 0 ? const Radius.circular(AppRadius.cards) : Radius.zero,
                  bottom: isLast ? const Radius.circular(AppRadius.cards) : Radius.zero,
                ),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(
                    children: [
                      Icon(item.icon, color: AppColors.twilightViolet, size: 20),
                      const SizedBox(width: 14),
                      Expanded(
                          child: Text(item.label,
                              style: AppText.body(color: Theme.of(context).colorScheme.onSurface).copyWith(fontSize: 14))),
                      Icon(Icons.chevron_right_rounded, color: context.textTertiary, size: 18),
                    ],
                  ),
                ),
              ),
              if (!isLast) Divider(height: 1, color: Theme.of(context).dividerColor, indent: 16, endIndent: 16),
            ],
          );
        }),
      ),
    );
  }
}

/// Nav inferior em pill, compartilhada entre Home / Registros / Perfil.
/// Cada tela decide o que fazer no onTap (a navegação fica na própria tela,
/// evitando importação cruzada entre os arquivos).
class AppBottomNav extends StatelessWidget {
  final int activeIndex; // 0 = Ponto, 1 = Registros, 2 = Perfil
  final ValueChanged<int> onTap;

  const AppBottomNav({super.key, required this.activeIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(60, 0, 60, 20),
      padding: const EdgeInsets.symmetric(vertical: 14),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.pills),
        boxShadow: [BoxShadow(color: const Color(0xFF68410D).withOpacity(0.23), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _NavLabel(label: 'Ponto', active: activeIndex == 0, onTap: () => onTap(0)),
          _NavLabel(label: 'Registros', active: activeIndex == 1, onTap: () => onTap(1)),
          _NavLabel(label: 'Perfil', active: activeIndex == 2, onTap: () => onTap(2)),
        ],
      ),
    );
  }
}

class _NavLabel extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavLabel({required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Text(
        label,
        style: AppText.caption(
          color: active ? Theme.of(context).colorScheme.onSurface : context.textTertiary,
          weight: active ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
    );
  }
}

/// Transição com fade — mais leve que o slide padrão do MaterialPageRoute.
Route fadeRoute(Widget screen) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 200),
  );
}