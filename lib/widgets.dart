import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'brand_mark.dart';

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

/// Botão quadrado com borda (voltar, menu), no padrão do header do hero-01.
class AppSquareIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  const AppSquareIconButton({super.key, required this.icon, required this.tooltip, this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Semantics(
        button: true,
        label: tooltip,
        excludeSemantics: true,
        child: Material(
          color: Theme.of(context).cardColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.inner),
            side: BorderSide(color: context.border),
          ),
          child: InkWell(
            onTap: onPressed,
            customBorder: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.inner)),
            child: SizedBox(width: 40, height: 40, child: Icon(icon, size: 19, color: context.textPrimary)),
          ),
        ),
      ),
    );
  }
}

/// Seta de voltar padrão, usada em todas as telas secundárias.
class AppBackButton extends StatelessWidget {
  final String tooltip;
  const AppBackButton({super.key, this.tooltip = 'Voltar'});

  @override
  Widget build(BuildContext context) => AppSquareIconButton(
        icon: Icons.chevron_left_rounded,
        tooltip: tooltip,
        onPressed: () => Navigator.maybePop(context),
      );
}

/// Barra superior das telas secundárias: voltar + caminho em pílula ("Perfil / Editar perfil").
/// [parent] é a tela de onde se veio.
PreferredSizeWidget appSecondaryBar(String? title, {String parent = 'Perfil'}) {
  return AppBar(
    toolbarHeight: 64,
    automaticallyImplyLeading: false,
    titleSpacing: AppSpace.page,
    title: Builder(
      builder: (context) => Row(
        children: [
          AppBackButton(tooltip: 'Voltar para $parent'),
          const SizedBox(width: 12),
          Flexible(child: AppCrumb(parent: parent, title: title)),
        ],
      ),
    ),
  );
}

/// Caminho em pílula: "Perfil / Editar perfil".
class AppCrumb extends StatelessWidget {
  final String parent;
  final String? title;
  const AppCrumb({super.key, required this.parent, this.title});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: context.cardRaised,
        borderRadius: BorderRadius.circular(AppRadius.pills),
        border: Border.all(color: context.border),
      ),
      child: Text.rich(
        TextSpan(children: [
          TextSpan(text: parent),
          if (title != null) ...[
            const TextSpan(text: '  /  '),
            TextSpan(text: title, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
          ],
        ]),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: AppText.caption(color: context.textTertiary).copyWith(fontSize: 12.5),
      ),
    );
  }
}

/// Campo de texto padrão: rótulo acima + fundo do card + 24px de radius.
/// A borda fica violeta quando o campo está em foco e vermelha com erro.
class AppTextField extends StatelessWidget {
  final String label;
  final String? hint;
  final IconData? icon; // não é desenhado no padrão atual (campo sem ícone); mantido por compatibilidade
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
    this.icon,
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
    // Campo no padrão shadcn: rótulo acima, borda visível, sem ícone interno; violeta no foco.
    OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppRadius.inputs),
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
          style: AppText.label(color: context.textPrimary),
        ),
        const SizedBox(height: 8),
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
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Theme.of(context).cardColor,
            isDense: true,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            border: border(context.border),
            enabledBorder: border(context.border),
            focusedBorder: border(AppColors.twilightViolet, 1.6),
            errorBorder: border(AppColors.statusRed),
            focusedErrorBorder: border(AppColors.statusRed, 1.6),
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
    this.height = 50,
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

  final IconData? trailingIcon;
  final double height;

  const AppOutlineButton({super.key, required this.label, this.icon, this.onPressed, this.trailingIcon, this.height = 40});

  @override
  Widget build(BuildContext context) {
    final color = context.textPrimary;
    return OutlinedButton(
      onPressed: onPressed,
      style: OutlinedButton.styleFrom(
        foregroundColor: color,
        backgroundColor: Theme.of(context).cardColor,
        side: BorderSide(color: context.border),
        minimumSize: Size(0, height),
        padding: const EdgeInsets.symmetric(horizontal: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.buttons)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[Icon(icon, size: 16, color: color), const SizedBox(width: 7)],
          Flexible(child: Text(label, overflow: TextOverflow.ellipsis, style: AppText.label(color: color, weight: FontWeight.w600))),
          if (trailingIcon != null) ...[const SizedBox(width: 6), Icon(trailingIcon, size: 16, color: color)],
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
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(AppRadius.cards),
        border: Border.all(color: context.border),
      ),
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
      shape: StadiumBorder(side: BorderSide(color: context.border)),
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
  final String? badge; // resumo à direita (ex: "8h · sáb 4h")
  const AppMenuItemData({required this.icon, required this.label, required this.onTap, this.accent, this.badge});
}

/// Card com uma lista de itens de menu (ícone + texto + seta), usado no Perfil.
class AppMenuCard extends StatelessWidget {
  final List<AppMenuItemData> items;
  const AppMenuCard({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppRadius.cards),
        side: BorderSide(color: context.border),
      ),
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
                        if (item.badge != null) ...[AppBadge(item.badge!), const SizedBox(width: 6)],
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

/// Menu das abas em pílula (header do hero-01): a aba ativa fica em violeta.
class AppPillNav extends StatelessWidget {
  final int activeIndex; // 0 = Ponto, 1 = Registros, 2 = Perfil
  final ValueChanged<int> onTap;

  const AppPillNav({super.key, required this.activeIndex, required this.onTap});

  static const labels = ['Ponto', 'Registros', 'Perfil'];

  @override
  Widget build(BuildContext context) {
    return MediaQuery.withClampedTextScaling(
      maxScaleFactor: 1.3,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: context.cardRaised,
          borderRadius: BorderRadius.circular(AppRadius.pills),
          border: Border.all(color: context.border),
        ),
        child: Row(
          children: [
            for (var i = 0; i < labels.length; i++)
              Expanded(
                child: Semantics(
                  button: true,
                  selected: activeIndex == i,
                  label: labels[i],
                  excludeSemantics: true,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => onTap(i),
                      borderRadius: BorderRadius.circular(AppRadius.pills),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeOut,
                        height: 38,
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: activeIndex == i ? AppColors.twilightViolet : Colors.transparent,
                          borderRadius: BorderRadius.circular(AppRadius.pills),
                          boxShadow: activeIndex == i
                              ? [BoxShadow(color: AppColors.twilightViolet.withValues(alpha: 0.35), blurRadius: 10, offset: const Offset(0, 3))]
                              : null,
                        ),
                        child: Text(
                          labels[i],
                          style: AppText.label(
                            color: activeIndex == i ? Colors.white : context.textTertiary,
                            weight: activeIndex == i ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// Selo acima do título (o "Novo · 1.0.6" do hero-01): uma etiqueta colorida
/// ou um ponto de status, seguido de um texto curto.
class AppEyebrow extends StatelessWidget {
  final String text;
  final String? tag;
  final IconData? tagIcon;
  final Color? dotColor;
  final bool danger;
  final VoidCallback? onTap;

  const AppEyebrow({super.key, required this.text, this.tag, this.tagIcon, this.dotColor, this.danger = false, this.onTap});

  @override
  Widget build(BuildContext context) {
    final hasTag = tag != null || tagIcon != null;
    final tagColor = danger ? AppColors.statusRedStrong : AppColors.twilightViolet;
    final content = Padding(
      padding: EdgeInsets.fromLTRB(hasTag ? 4 : 12, 4, 12, 4),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (hasTag) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
              decoration: BoxDecoration(color: tagColor, borderRadius: BorderRadius.circular(AppRadius.pills)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (tagIcon != null) Icon(tagIcon, size: 12, color: Colors.white),
                  if (tagIcon != null && tag != null) const SizedBox(width: 4),
                  if (tag != null)
                    Text(tag!, style: AppText.caption(color: Colors.white, weight: FontWeight.w600).copyWith(fontSize: 11.5)),
                ],
              ),
            ),
            const SizedBox(width: 8),
          ],
          if (dotColor != null) ...[
            Container(width: 8, height: 8, decoration: BoxDecoration(shape: BoxShape.circle, color: dotColor)),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(text,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppText.caption(color: context.textSecondary).copyWith(fontSize: 12.5)),
          ),
          if (onTap != null) ...[
            const SizedBox(width: 4),
            Icon(Icons.chevron_right_rounded, size: 16, color: context.textTertiary),
          ],
        ],
      ),
    );
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Theme.of(context).cardColor,
        shape: StadiumBorder(side: BorderSide(color: context.border)),
        clipBehavior: Clip.antiAlias,
        child: onTap == null ? content : InkWell(onTap: onTap, child: content),
      ),
    );
  }
}

/// Tom de cada trecho do [AppHeroTitle].
enum HeroTone { plain, accent, number, danger }

/// Título grande e forte das telas (o headline do hero-01). Cada trecho pode
/// ganhar destaque: violeta (accent), pêssego com números de largura fixa
/// (number) ou vermelho (danger).
class AppHeroTitle extends StatelessWidget {
  final List<(String, HeroTone)> parts;
  final double fontSize;
  final TextAlign textAlign;

  const AppHeroTitle(this.parts, {super.key, this.fontSize = 32, this.textAlign = TextAlign.start});

  @override
  Widget build(BuildContext context) {
    final base = AppText.headingLg(color: context.textPrimary, weight: FontWeight.w800)
        .copyWith(fontSize: fontSize, height: 1.06, letterSpacing: -fontSize * 0.04);
    return Semantics(
      header: true,
      child: Text.rich(
        TextSpan(
          children: [
            for (final (text, tone) in parts)
              TextSpan(
                text: text,
                style: switch (tone) {
                  HeroTone.plain => null,
                  HeroTone.accent => TextStyle(color: context.violetText),
                  HeroTone.number => TextStyle(color: context.accentPeach, fontFeatures: const [FontFeature.tabularFigures()]),
                  HeroTone.danger => TextStyle(color: context.dangerText),
                },
              ),
          ],
        ),
        textAlign: textAlign,
        style: base,
      ),
    );
  }
}

/// Texto de apoio logo abaixo do título.
class AppLead extends StatelessWidget {
  final String text;
  final TextAlign textAlign;
  const AppLead(this.text, {super.key, this.textAlign = TextAlign.start});

  @override
  Widget build(BuildContext context) => Text(
        text,
        textAlign: textAlign,
        style: AppText.bodySm(color: context.textSecondary).copyWith(fontSize: 14.5, height: 1.5),
      );
}

/// Abertura padrão das telas: selo + título grande + texto de apoio.
class AppHeroHeader extends StatelessWidget {
  final Widget? eyebrow;
  final List<(String, HeroTone)> title;
  final String? lead;
  final double fontSize;

  const AppHeroHeader({super.key, this.eyebrow, required this.title, this.lead, this.fontSize = 32});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (eyebrow != null) ...[eyebrow!, const SizedBox(height: 14)],
        AppHeroTitle(title, fontSize: fontSize),
        if (lead != null) ...[const SizedBox(height: 10), AppLead(lead!)],
      ],
    );
  }
}

/// Etiqueta pequena arredondada (ex: "extra +0h 48m", "1 local").
class AppBadge extends StatelessWidget {
  final String text;
  final Color? color;
  const AppBadge(this.text, {super.key, this.color});

  @override
  Widget build(BuildContext context) {
    final fg = color ?? context.violetText;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color == null ? context.violetSoft : fg.withValues(alpha: context.isDarkMode ? 0.16 : 0.12),
        borderRadius: BorderRadius.circular(AppRadius.pills),
      ),
      child: Text(text,
          maxLines: 1,
          style: AppText.numeric(AppText.caption(color: fg, weight: FontWeight.w600).copyWith(fontSize: 11.5))),
    );
  }
}

/// Marca pequena do header: relógio no círculo violeta + "PontoClick".
class AppBrand extends StatelessWidget {
  final double size;
  const AppBrand({super.key, this.size = 28});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'PontoClick',
      excludeSemantics: true,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BrandMark(size: size),
          SizedBox(width: size * 0.32),
          Text.rich(
            TextSpan(children: [
              TextSpan(text: 'Ponto', style: TextStyle(color: context.textPrimary)),
              TextSpan(text: 'Click', style: TextStyle(color: context.accentPeach)),
            ]),
            style: AppText.bodySm(weight: FontWeight.w700).copyWith(fontSize: size * 0.6, letterSpacing: -0.3),
          ),
        ],
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

/// Transição com fade — mais leve que o slide padrão do MaterialPageRoute.
Route fadeRoute(Widget screen) {
  return PageRouteBuilder(
    pageBuilder: (context, animation, secondaryAnimation) => screen,
    transitionsBuilder: (context, animation, secondaryAnimation, child) => FadeTransition(opacity: animation, child: child),
    transitionDuration: const Duration(milliseconds: 200),
  );
}
