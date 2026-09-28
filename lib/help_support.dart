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
    _FaqItem('Como registro meu ponto?', 'Na tela inicial, toque no botão "Bater Ponto". O horário atual será salvo automaticamente.'),
    _FaqItem('Esqueci de registrar um ponto, o que fazer?', 'Vá em Registros e toque no ícone de lápis ao lado do ponto para corrigir o horário.'),
    _FaqItem('Como altero meus dados cadastrais?', 'Vá em Perfil > Editar Perfil e atualize as informações desejadas.'),
    _FaqItem('O app funciona sem internet?', 'Sim, os registros ficam salvos no dispositivo e sincronizam automaticamente quando a conexão voltar.'),
  ];

  @override
  void dispose() {
    _messageController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Escreva uma mensagem antes de enviar')));
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Mensagem enviada! Nossa equipe responderá em breve.')));
    _messageController.clear();
    FocusScope.of(context).unfocus();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: Text('Ajuda e Suporte', style: AppText.body(weight: FontWeight.w600))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          children: [
            Row(
              children: [
                Expanded(child: _buildContactOption(context, Icons.chat_bubble_outline_rounded, 'WhatsApp')),
                const SizedBox(width: 12),
                Expanded(child: _buildContactOption(context, Icons.email_outlined, 'E-mail')),
                const SizedBox(width: 12),
                Expanded(child: _buildContactOption(context, Icons.phone_outlined, 'Telefone')),
              ],
            ),
            const SizedBox(height: 24),
            const AppSectionLabel('PERGUNTAS FREQUENTES'),
            const SizedBox(height: 8),
            _buildFaqCard(context),
            const SizedBox(height: 24),
            const AppSectionLabel('FALE CONOSCO'),
            const SizedBox(height: 8),
            _buildContactForm(context),
          ],
        ),
      ),
    );
  }

  Widget _buildContactOption(BuildContext context, IconData icon, String label) {
    return GestureDetector(
      onTap: () => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Contato via $label em construção'))),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(14)),
        child: Column(
          children: [
            Icon(icon, color: AppColors.twilightViolet, size: 22),
            const SizedBox(height: 8),
            Text(label, style: AppText.caption(weight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  Widget _buildFaqCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppRadius.cards)),
      child: Column(
        children: List.generate(_faqs.length, (i) {
          final faq = _faqs[i];
          final isExpanded = _expandedIndex == i;
          final isLast = i == _faqs.length - 1;
          return Column(
            children: [
              InkWell(
                onTap: () => setState(() => _expandedIndex = isExpanded ? null : i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(child: Text(faq.question, style: AppText.body(weight: FontWeight.w500).copyWith(fontSize: 14))),
                          Icon(isExpanded ? Icons.remove_rounded : Icons.add_rounded, color: AppColors.twilightViolet, size: 18),
                        ],
                      ),
                      if (isExpanded) ...[
                        const SizedBox(height: 8),
                        Text(faq.answer, style: AppText.body(color: context.textSecondary).copyWith(fontSize: 13, height: 1.4)),
                      ],
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

  Widget _buildContactForm(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppRadius.cards)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Não encontrou o que precisava? Envie sua dúvida:', style: AppText.body(color: context.textSecondary).copyWith(fontSize: 13)),
          const SizedBox(height: 12),
          TextField(
            controller: _messageController,
            maxLines: 4,
            style: AppText.body(color: Theme.of(context).colorScheme.onSurface),
            decoration: InputDecoration(
              hintText: 'Descreva sua dúvida ou problema...',
              hintStyle: AppText.body(color: context.textTertiary),
              filled: true,
              fillColor: Theme.of(context).scaffoldBackgroundColor,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.inputs), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.inputs), borderSide: BorderSide(color: Theme.of(context).dividerColor)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppRadius.inputs), borderSide: const BorderSide(color: AppColors.twilightViolet, width: 1.5)),
            ),
          ),
          const SizedBox(height: 14),
          AppPrimaryButton(label: 'Enviar Mensagem', onPressed: _sendMessage),
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