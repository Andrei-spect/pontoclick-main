import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets.dart';

class HelpSupportScreen extends StatefulWidget {
  const HelpSupportScreen({super.key});

  @override
  State<HelpSupportScreen> createState() => _HelpSupportScreenState();
}

class _HelpSupportScreenState extends State<HelpSupportScreen> {
  final _messageController = TextEditingController();
  int? _expandedIndex = 0;

  final List<_FaqItem> _faqs = const [
    _FaqItem('Como registro meu ponto?', 'Na tela inicial, toque no botão "Bater ponto". O horário atual será salvo automaticamente.'),
    _FaqItem('Esqueci de registrar um ponto, o que fazer?', 'Vá em Registros e toque no ícone de lápis ao lado do ponto para corrigir o horário.'),
    _FaqItem('Como altero meus dados cadastrais?', 'Vá em Perfil > Editar perfil e atualize as informações desejadas.'),
    _FaqItem('O app funciona sem internet?', 'Sim, os registros ficam salvos no dispositivo e sincronizam automaticamente quando a conexão voltar.'),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      AppFeedback.info(context, 'Escreva uma mensagem antes de enviar.');
      return;
    }
    AppFeedback.success(context, 'Mensagem enviada! Nossa equipe responderá em breve.');
    _messageController.clear();
    FocusScope.of(context).unfocus();
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
                  Row(
                    children: [
                      Expanded(child: _buildContactOption(context, Icons.chat_outlined, 'WhatsApp')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildContactOption(context, Icons.email_outlined, 'E-mail')),
                      const SizedBox(width: 10),
                      Expanded(child: _buildContactOption(context, Icons.phone_outlined, 'Telefone')),
                    ],
                  ),
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

  Widget _buildContactOption(BuildContext context, IconData icon, String label) {
    return Material(
      color: Theme.of(context).cardColor,
      borderRadius: BorderRadius.circular(AppRadius.cards),
      child: InkWell(
        borderRadius: BorderRadius.circular(AppRadius.cards),
        onTap: () => AppFeedback.info(context, 'Contato via $label em construção'),
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 84),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                AppIconTile(icon: icon, size: 36),
                const SizedBox(height: 8),
                Text(label, textAlign: TextAlign.center, style: AppText.label(color: context.textPrimary)),
              ],
            ),
          ),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Não encontrou o que precisava? Descreva sua dúvida.',
              style: AppText.label(color: context.textSecondary, weight: FontWeight.w400).copyWith(fontSize: 14)),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 4,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
            style: AppText.bodySm(color: context.textPrimary),
            decoration: InputDecoration(
              hintText: 'Ex.: o ponto de ontem não apareceu nos registros',
              hintStyle: AppText.bodySm(color: context.textTertiary),
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
            ),
          ),
          const SizedBox(height: 14),
          AppPrimaryButton(label: 'Enviar mensagem', onPressed: _sendMessage, height: 48),
        ],
      ),
    );
  }
}

class _FaqItem {
  final String question;
  final String answer;
  const _FaqItem(this.question, this.answer);
}
