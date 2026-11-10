import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'about.dart';
import 'auth_service.dart';
import 'user_service.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  /// E-mail que recebe as mensagens do suporte (mesmo do SUPPORT_EMAIL da API).
  static const supportEmail = 'andrei.barbosa009@gmail.com';

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  static const _minLength = 10;
  static const _maxLength = 2000;

  final _formKey = GlobalKey<FormState>();
  final _messageController = TextEditingController();
  final _userService = UserService();
  int? _expandedIndex = 0;
  bool _isSending = false;

  final List<_FaqItem> _faqs = const [
    _FaqItem('Como registro meu ponto?', 'Na tela inicial, toque no botão "Bater ponto". O horário atual será salvo automaticamente.'),
    _FaqItem('Esqueci de registrar um ponto, o que fazer?', 'Vá em Registros e toque no ícone de lápis ao lado do ponto para corrigir o horário.'),
    _FaqItem('Trabalho à noite. O ponto depois da meia-noite vai para qual dia?',
        'Para o dia em que você bateu a entrada, desde que o turno tenha até 16 horas. Ex: entrada às 22h e saída às 6h ficam no mesmo dia.'),
    _FaqItem('Como altero meus dados cadastrais?', 'Vá em Perfil > Editar perfil e atualize as informações desejadas.'),
    _FaqItem('O app funciona sem internet?',
        'Sim, os registros ficam salvos no dispositivo e sincronizam automaticamente quando a conexão voltar (em até 72 horas).'),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  String get _platform => kIsWeb ? 'web' : defaultTargetPlatform.name;

  Future<void> _openEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: HelpSupportScreen.supportEmail,
      query: 'subject=${Uri.encodeComponent('Suporte PontoClick')}',
    );
    final ok = await canLaunchUrl(uri) && await launchUrl(uri);
    if (!ok && mounted) {
      AppFeedback.info(context, 'Nenhum app de e-mail encontrado. Escreva para ${HelpSupportScreen.supportEmail}.');
    }
  }

  Future<void> _sendMessage() async {
    if (_isSending || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();

    setState(() => _isSending = true);
    try {
      await _userService.sendSupportMessage(
        message: _messageController.text.trim(),
        appVersion: AboutScreen.appVersion,
        platform: _platform,
      );
      if (!mounted) return;
      _messageController.clear();
      AppFeedback.success(context, 'Mensagem enviada! Responderemos no seu e-mail.');
    } on ApiException catch (e) {
      if (!mounted || e.statusCode == 401) return;
      AppFeedback.error(context, e.message);
    } finally {
      if (mounted) setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appSecondaryBar('Ajuda e suporte'),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AppSpace.page, 8, AppSpace.page, 28),
          children: [
            AppContentWidth(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppSectionLabel('Fale com a gente'),
                  const SizedBox(height: 8),
                  AppMenuCard(items: [
                    AppMenuItemData(
                      icon: Icons.email_outlined,
                      label: HelpSupportScreen.supportEmail,
                      onTap: _openEmail,
                    ),
                  ]),
                  const SizedBox(height: 22),
                  const AppSectionLabel('Perguntas frequentes'),
                  const SizedBox(height: 8),
                  _buildFaqCard(context),
                  const SizedBox(height: 22),
                  const AppSectionLabel('Enviar mensagem'),
                  const SizedBox(height: 8),
                  _buildContactForm(context),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqCard(BuildContext context) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppRadius.cards),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: List.generate(_faqs.length, (i) {
          final faq = _faqs[i];
          final isExpanded = _expandedIndex == i;
          final isLast = i == _faqs.length - 1;
          return Column(
            children: [
              Semantics(
                expanded: isExpanded,
                child: InkWell(
                  onTap: () => setState(() => _expandedIndex = isExpanded ? null : i),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 14, 12, 14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(child: Text(faq.question, style: AppText.bodySm(weight: FontWeight.w500))),
                            const SizedBox(width: 12),
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isExpanded ? context.violetSoft : context.cardRaised,
                              ),
                              child: AnimatedRotation(
                                turns: isExpanded ? 0.5 : 0,
                                duration: const Duration(milliseconds: 200),
                                child: Icon(Icons.expand_more_rounded,
                                    size: 18, color: isExpanded ? context.violetText : context.textSecondary),
                              ),
                            ),
                          ],
                        ),
                        AnimatedSize(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOut,
                          alignment: Alignment.topCenter,
                          child: isExpanded
                              ? Padding(
                                  padding: const EdgeInsets.only(top: 8, right: 40),
                                  child: Text(faq.answer,
                                      style: AppText.label(color: context.textSecondary, weight: FontWeight.w400)
                                          .copyWith(fontSize: 14, height: 1.5)),
                                )
                              : const SizedBox(width: double.infinity),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              if (!isLast) Divider(height: 1, thickness: 1, color: context.hairline),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildContactForm(BuildContext context) {
    return AppCard(
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Não encontrou o que precisava? Descreva sua dúvida e responderemos no seu e-mail.',
                style: AppText.label(color: context.textSecondary, weight: FontWeight.w400).copyWith(fontSize: 14)),
            const SizedBox(height: 12),
            TextFormField(
              controller: _messageController,
              maxLines: 5,
              minLines: 3,
              maxLength: _maxLength,
              enabled: !_isSending,
              textCapitalization: TextCapitalization.sentences,
              style: AppText.bodySm(color: context.textPrimary),
              validator: (v) {
                final text = (v ?? '').trim();
                if (text.isEmpty) return 'Escreva sua mensagem antes de enviar';
                if (text.length < _minLength) return 'Escreva pelo menos $_minLength caracteres';
                return null;
              },
              decoration: InputDecoration(
                hintText: 'Ex.: o ponto de ontem não apareceu nos registros',
                hintStyle: AppText.bodySm(color: context.textTertiary),
                counterStyle: AppText.caption(color: context.textTertiary),
                filled: true,
                fillColor: context.cardRaised,
                contentPadding: const EdgeInsets.all(14),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.cards), borderSide: const BorderSide(color: Colors.transparent)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.cards),
                    borderSide: BorderSide(color: context.isDarkMode ? Colors.transparent : Theme.of(context).dividerColor)),
                focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.cards),
                    borderSide: const BorderSide(color: AppColors.twilightViolet, width: 1.5)),
                errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.cards), borderSide: const BorderSide(color: AppColors.statusRed)),
                focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(AppRadius.cards),
                    borderSide: const BorderSide(color: AppColors.statusRed, width: 1.5)),
              ),
            ),
            const SizedBox(height: 10),
            AppPrimaryButton(label: 'Enviar mensagem', onPressed: _sendMessage, isLoading: _isSending, height: 48),
          ],
        ),
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}
