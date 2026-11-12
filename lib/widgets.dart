import 'package:flutter/material.dart';
import 'app_theme.dart';

/// Largura máxima do conteúdo em telas largas (tablet, web, desktop).
const double kContentMaxWidth = 560;

/// Centraliza o conteúdo e limita a largura em telas grandes.
class AppContentWidth extends StatelessWidget {
  final Widget child;
  const AppContentWidth({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(constraints: const BoxConstraints(maxWidth: kContentMaxWidth), child: child),
    );
  }
}

/// Seta de voltar padrão, usada em todas as telas secundárias.
class AppBackButton extends StatelessWidget {
  const AppBackButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Voltar',
      icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.textPrimary, size: 20),
      onPressed: () => Navigator.maybePop(context),
      style: IconButton.styleFrom(minimumSize: const Size(44, 44)),
    );
  }
}

/// Barra superior das telas secundárias: voltar + título.
PreferredSizeWidget appSecondaryBar(String? title) {
  return AppBar(
    leading: const Padding(padding: EdgeInsets.only(left: 4), child: AppBackButton()),
    leadingWidth: 56,
    title: title == null ? null : Text(title),
  );
}

/// Título grande das abas principais (Registros, Perfil).
class AppPageTitle extends StatelessWidget {
  final String text;
  final Widget? trailing;
  const AppPageTitle(this.text, {super.key, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 48),
      child: Row(
        children: [
          Expanded(child: Semantics(header: true, child: Text(text, style: AppText.heading()))),
          ?trailing,
        ],
      ),
    );
  }
}

/// Campo de texto padrão: rótulo acima + fundo do card + 24px de radius.
/// A borda fica violeta quando o campo está em foco e vermelha com erro.
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData icon;
  final TextEditingController? controller;
  final bool obscureText;
  final Widget? suffixIcon;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final Iterable<String>? autofillHints;
  final ValueChanged<String>? onFieldSubmitted;
  final ValueChanged<String>? onChanged;
  final int maxLines;
  final int? maxLength;
  final String? Function(String?)? validator;
  final String? labelSuffix; // ex: "(opcional)"
  final FocusNode? focusNode;

  const AppTextField({
    super.key,
    required this.label,
    required this.icon,
    this.hint,
    this.controller,
    this.obscureText = false,
    this.suffixIcon,
    this.keyboardType,
    this.textInputAction,
    this.autofillHints,
    this.onFieldSubmitted,
    this.onChanged,
    this.maxLines = 1,
    this.maxLength,
    this.validator,
    this.labelSuffix,
    this.focusNode,
  });

  @override
  Widget build(BuildContext context) {
    OutlineInputBorder border(Color color, [double width = 1.5]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(maxLines > 1 ? AppRadius.cards : AppRadius.inputs),
          borderSide: BorderSide(color: color, width: width),
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text.rich(
          TextSpan(children: [
            TextSpan(text: label),
            if (labelSuffix != null)
              TextSpan(text: ' $labelSuffix', style: TextStyle(color: context.textTertiary, fontWeight: FontWeight.w400)),
          ]),
          style: AppText.label(color: context.textSecondary),
        ),
        const SizedBox(height: 7),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          obscureText: obscureText,
          keyboardType: keyboardType,
          textInputAction: textInputAction,
          autofillHints: autofillHints,
          onFieldSubmitted: onFieldSubmitted,
          onChanged: onChanged,
          maxLines: maxLines,
          maxLength: maxLength,
          validator: validator,
          style: AppText.bodySm(color: context.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            counterText: '',
            hintStyle: AppText.bodySm(color: context.textTertiary),
            prefixIcon: maxLines > 1 ? null : Icon(icon, size: 18, color: context.textTertiary),
            prefixIconConstraints: const BoxConstraints(minWidth: 46, minHeight: 52),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Theme.of(context).cardColor,
            contentPadding: EdgeInsets.symmetric(horizontal: maxLines > 1 ? 16 : 18, vertical: 16),
            border: border(Colors.transparent),
            enabledBorder: border(Colors.transparent),
            focusedBorder: border(AppColors.twilightViolet),
            errorBorder: border(AppColors.statusRed),
            focusedErrorBorder: border(AppColors.statusRed),
            errorStyle: AppText.caption(color: context.isDarkMode ? const Color(0xFFF87171) : const Color(0xFFC62828)),
            errorMaxLines: 2,
          ),
        ),
      ],
    );
  }
}

/// Botão de mostrar/ocultar senha, para o [AppTextField.suffixIcon].
class AppPasswordToggle extends StatelessWidget {
  final bool obscured;
  final VoidCallback onPressed;
  const AppPasswordToggle({super.key, required this.obscured, required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: obscured ? 'Mostrar senha' : 'Ocultar senha',
      icon: Icon(obscured ? Icons.visibility_outlined : Icons.visibility_off_outlined, color: context.textTertiary, size: 19),
      onPressed: onPressed,
    );
  }
}

/// Botão principal — a cor de commit/confirmação do sistema (violeta).
/// [color] permite usar a cor do tipo de ponto no botão da Home.
class AppPrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final Color? color;
  final double height;

  const AppPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.color,
    this.height = 52,
  });

  @override
  Widget build(BuildContext context) {
    final bg = color ?? AppColors.twilightViolet;
    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: height, minWidth: double.infinity),
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: bg,
          foregroundColor: Colors.white,
          disabledBackgroundColor: bg.withValues(alpha: 0.45),
          disabledForegroundColor: Colors.white.withValues(alpha: 0.85),
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.buttons)),
        ),
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 150),
          child: isLoading
              ? const SizedBox(
                  key: ValueKey('loading'),
                  height: 20,
                  width: 20,
                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                )
              : Row(
                  key: const ValueKey('label'),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[Icon(icon, size: 20, color: Colors.white), const SizedBox(width: 10)],
                    Flexible(
                      child: Text(label,
                          textAlign: TextAlign.center,
                          style: AppText.bodySm(color: Colors.white, weight: FontWeight.w600)),
                    ),
                  ],
                ),
        ),
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
    final color = context.textPrimary;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        side: BorderSide(color: Theme.of(context).dividerColor),
        minimumSize: const Size(0, 40),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.buttons)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: 7)],
          Text(label, style: AppText.label(color: color)),
        ],
      ),
    );
  }
}

/// Botão para ações destrutivas (ex: Sair da conta).
class AppDangerButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;

  const AppDangerButton({super.key, required this.label, this.icon, this.onPressed});

  @override
  Widget build(BuildContext context) {
    final red = context.isDarkMode ? const Color(0xFFF87171) : const Color(0xFFC62828);
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52, minWidth: double.infinity),
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: red,
          backgroundColor: AppColors.statusRed.withValues(alpha: 0.08),
          side: BorderSide(color: AppColors.statusRed.withValues(alpha: 0.5)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.buttons)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[Icon(icon, size: 18, color: red), const SizedBox(width: 8)],
            Flexible(child: Text(label, textAlign: TextAlign.center, style: AppText.bodySm(color: red, weight: FontWeight.w600))),
          ],
        ),
      ),
    );
  }
}

/// Título de seção (ex: "Conta", "Suporte").
class AppSectionLabel extends StatelessWidget {
  final String text;
  const AppSectionLabel(this.text, {super.key});

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Semantics(header: true, child: Text(text, style: AppText.label(color: context.textTertiary, weight: FontWeight.w600))),
      );
}

/// Card padrão do app.
class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const AppCard({super.key, required this.child, this.padding = const EdgeInsets.all(16), this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(color: color ?? Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppRadius.cards)),
      child: child,
    );
  }
}

/// Quadradinho arredondado com ícone (listas, cabeçalhos de card).
class AppIconTile extends StatelessWidget {
  final IconData icon;
  final Color? color; // cor do ícone; o fundo é a mesma cor, suave
  final double size;

  const AppIconTile({super.key, required this.icon, this.color, this.size = 32});

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.violetText;
    final bg = color == null ? context.violetSoft : fg.withValues(alpha: context.isDarkMode ? 0.16 : 0.14);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(size * 0.31)),
      child: Icon(icon, size: size * 0.53, color: fg),
    );
  }
}

/// Faixa de aviso dentro da tela (ex: "Ontem ficou sem registro de saída.").
class AppNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;
  final Widget? action;

  const AppNotice({super.key, required this.icon, required this.text, required this.color, this.action});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, action == null ? 12 : 4, action == null ? 14 : 4, action == null ? 12 : 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: context.isDarkMode ? 0.12 : 0.14),
        borderRadius: BorderRadius.circular(AppRadius.cards),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: color),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: AppText.label(color: context.textPrimary, weight: FontWeight.w400))),
          ?action,
        ],
      ),
    );
  }
}

/// Chip pequeno de status (ex: "● Online", "1 pendente").
class AppStatusChip extends StatelessWidget {
  final String label;
  final Color? dotColor;
  final IconData? icon;
  final VoidCallback? onTap;
  final String? tooltip;

  const AppStatusChip({super.key, required this.label, this.dotColor, this.icon, this.onTap, this.tooltip});

  @override
  Widget build(BuildContext context) {
    final chip = Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppRadius.pills),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.pills),
        child: Container(
          constraints: const BoxConstraints(minHeight: 32),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dotColor != null) ...[
                Container(width: 7, height: 7, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
                const SizedBox(width: 7),
              ],
              if (icon != null) ...[Icon(icon, size: 14, color: context.textSecondary), const SizedBox(width: 6)],
              Text(label, style: AppText.caption(color: context.textSecondary, weight: FontWeight.w500)),
            ],
          ),
        ),
      ),
    );
    return tooltip == null ? chip : Tooltip(message: tooltip!, child: chip);
  }
}

/// Estado vazio / de erro dentro de um card ou tela.
class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppEmptyState({super.key, required this.icon, required this.title, this.message, this.actionLabel, this.onAction});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      child: Column(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(color: context.cardRaised, borderRadius: BorderRadius.circular(AppRadius.cards)),
            child: Icon(icon, size: 22, color: context.textTertiary),
          ),
          const SizedBox(height: 10),
          Text(title, textAlign: TextAlign.center, style: AppText.bodySm(weight: FontWeight.w500, color: context.textPrimary)),
          if (message != null) ...[
            const SizedBox(height: 4),
            Text(message!, textAlign: TextAlign.center, style: AppText.label(color: context.textTertiary, weight: FontWeight.w400)),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 6),
            TextButton(
              onPressed: onAction,
              child: Text(actionLabel!, style: AppText.label(color: context.violetText, weight: FontWeight.w600)),
            ),
          ],
        ],
      ),
    );
  }
}

/// Bloco cinza pulsando, usado enquanto os dados carregam.
class AppSkeleton extends StatefulWidget {
  final double width;
  final double height;
  final double radius;
  const AppSkeleton({super.key, this.width = double.infinity, this.height = 14, this.radius = 6});

  @override
  State<AppSkeleton> createState() => _AppSkeletonState();
}

class _AppSkeletonState extends State<AppSkeleton> with SingleTickerProviderStateMixin {
  late final AnimationController _controller =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 900))..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    final base = Theme.of(context).dividerColor;
    return ExcludeSemantics(
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) => Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            color: base.withValues(alpha: reduceMotion ? 0.6 : 0.35 + 0.35 * _controller.value),
            borderRadius: BorderRadius.circular(widget.radius),
          ),
        ),
      ),
    );
  }
}

class AppMenuItemData {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? accent; // cor do ícone; padrão violeta
  const AppMenuItemData({required this.icon, required this.label, required this.onTap, this.accent});
}

/// Card com uma lista de itens de menu (ícone + texto + seta), usado no Perfil.
class AppMenuCard extends StatelessWidget {
  final List<AppMenuItemData> items;
  const AppMenuCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppRadius.cards),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(items.length, (i) {
          final item = items[i];
          final isLast = i == items.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: item.onTap,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minHeight: 56),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    child: Row(
                      children: [
                        AppIconTile(icon: item.icon, color: item.accent),
                        const SizedBox(width: 14),
                        Expanded(child: Text(item.label, style: AppText.bodySm(color: context.textPrimary))),
                        Icon(Icons.chevron_right_rounded, color: context.textTertiary, size: 20),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast) Divider(height: 1, thickness: 1, color: context.hairline, indent: 62),
            ],
          );
        }),
      ),
    );
  }
}

/// Nav inferior em pill flutuante, compartilhada entre Ponto / Registros / Perfil.
/// A aba ativa ganha fundo violeta suave com ícone + rótulo lado a lado.
class AppBottomNav extends StatelessWidget {
  final int activeIndex; // 0 = Ponto, 1 = Registros, 2 = Perfil
  final ValueChanged<int> onTap;

  const AppBottomNav({super.key, required this.activeIndex, required this.onTap});

  static const _items = [
    (icon: Icons.schedule_rounded, label: 'Ponto'),
    (icon: Icons.calendar_month_outlined, label: 'Registros'),
    (icon: Icons.person_outline_rounded, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final dark = context.isDarkMode;
    // A barra tem altura fixa: acompanha o tamanho de fonte do sistema só até 1.2x.
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.2,
      child: SafeArea(
      top: false,
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Container(
            margin: const EdgeInsets.fromLTRB(40, 0, 40, 16),
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(AppRadius.pills),
              border: Border.all(color: dark ? const Color(0xFF262626) : AppColors.lightDivider),
              boxShadow: [
                BoxShadow(
                  color: dark ? Colors.black.withValues(alpha: 0.55) : const Color(0xFF68410D).withValues(alpha: 0.16),
                  blurRadius: 28,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Row(
              children: [
                for (var i = 0; i < _items.length; i++)
                  Expanded(
                    child: _NavItem(
                      icon: _items[i].icon,
                      label: _items[i].label,
                      active: activeIndex == i,
                      onTap: () => onTap(i),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback onTap;
  const _NavItem({required this.icon, required this.label, required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final color = active ? context.violetText : context.textTertiary;
    return Semantics(
      button: true,
      selected: active,
      label: label,
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.pills),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
            height: 52,
            decoration: BoxDecoration(
              color: active ? context.violetSoft : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pills),
            ),
            child: active
                ? Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 19, color: color),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(label,
                            overflow: TextOverflow.ellipsis, style: AppText.label(color: color, weight: FontWeight.w600)),
                      ),
                    ],
                  )
                : Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(icon, size: 19, color: color),
                      const SizedBox(height: 2),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4),
                        child: FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Text(label,
                              maxLines: 1, style: AppText.caption(color: color, weight: FontWeight.w500).copyWith(fontSize: 11)),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}

enum AppFeedbackType { success, error, info }

/// Mensagens flutuantes (sucesso / erro / informação) no padrão do app.
class AppFeedback {
  AppFeedback._();

  static SnackBar build(BuildContext context, String message, {AppFeedbackType type = AppFeedbackType.info}) {
    final (IconData icon, Color color) = switch (type) {
      AppFeedbackType.success => (Icons.check_rounded, AppColors.statusGreen),
      AppFeedbackType.error => (Icons.error_outline_rounded, AppColors.statusRed),
      AppFeedbackType.info => (Icons.info_outline_rounded, context.violetText),
    };
    // Em telas largas (web/tablet) a mensagem fica do tamanho do conteúdo, não da tela toda.
    final screenWidth = MediaQuery.sizeOf(context).width;
    return SnackBar(
      width: screenWidth > kContentMaxWidth + 40 ? kContentMaxWidth : null,
      duration: Duration(milliseconds: type == AppFeedbackType.error ? 4500 : 3000),
      content: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(shape: BoxShape.circle, color: color.withValues(alpha: 0.16)),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: AppText.bodySm(color: context.textPrimary).copyWith(fontSize: 14))),
        ],
      ),
    );
  }

  static void show(BuildContext context, String message, {AppFeedbackType type = AppFeedbackType.info}) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();
    messenger.showSnackBar(build(context, message, type: type));
  }

  static void success(BuildContext context, String message) => show(context, message, type: AppFeedbackType.success);
  static void error(BuildContext context, String message) => show(context, message, type: AppFeedbackType.error);
  static void info(BuildContext context, String message) => show(context, message, type: AppFeedbackType.info);
}

/// Marca do app: ícone de relógio no círculo violeta + "PontoClick".
class AppLogo extends StatelessWidget {
  final double iconSize;
  final TextStyle? textStyle;
  const AppLogo({super.key, this.iconSize = 40, this.textStyle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: EdgeInsets.all(iconSize * 0.45),
          decoration: BoxDecoration(color: AppColors.twilightViolet.withValues(alpha: 0.18), shape: BoxShape.circle),
          child: Icon(Icons.access_time_filled_rounded, size: iconSize, color: AppColors.twilightViolet),
        ),
        SizedBox(height: iconSize * 0.35),
        Semantics(
          label: 'PontoClick',
          excludeSemantics: true,
          child: RichText(
            text: TextSpan(
              style: textStyle ?? AppText.headingLg(weight: FontWeight.w700).copyWith(fontSize: 34),
              children: [
                TextSpan(text: 'Ponto', style: TextStyle(color: context.textPrimary)),
                TextSpan(text: 'Click', style: TextStyle(color: context.accentPeach)),
              ],
            ),
          ),
        ),
      ],
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
