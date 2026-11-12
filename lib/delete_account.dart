import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'auth_service.dart';
import 'login.dart';
import 'user_service.dart';

/// Perfil > Excluir conta. Apaga a conta e todos os dados no servidor, sem volta.
/// (Obrigatório na App Store e na Google Play para apps com cadastro.)
class DeleteAccountScreen extends StatefulWidget {
  const DeleteAccountScreen({super.key});

  @override
  State<DeleteAccountScreen> createState() => _DeleteAccountScreenState();
}

class _DeleteAccountScreenState extends State<DeleteAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _userService = UserService();
  bool _obscure = true;
  bool _confirmed = false;
  bool _deleting = false;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _delete() async {
    if (_deleting || !_formKey.currentState!.validate()) return;
    if (!_confirmed) {
      AppFeedback.info(context, 'Marque a confirmação para continuar.');
      return;
    }
    setState(() => _deleting = true);
    try {
      await _userService.deleteAccount(password: _passwordController.text);
      if (!mounted) return;
      AppFeedback.success(context, 'Sua conta e todos os seus dados foram excluídos.');
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    } on ApiException catch (e) {
      if (!mounted || e.statusCode == 401) return;
      AppFeedback.error(context, e.message);
      setState(() => _deleting = false);
    }
  }

  Widget _item(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(top: 8),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Container(width: 6, height: 6, decoration: const BoxDecoration(shape: BoxShape.circle, color: AppColors.statusRed)),
            ),
            const SizedBox(width: 10),
            Expanded(child: Text(text, style: AppText.label(color: context.textSecondary, weight: FontWeight.w400).copyWith(fontSize: 14))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appSecondaryBar('Excluir conta'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.xxl, 8, AppSpace.xxl, AppSpace.xxl),
          child: AppContentWidth(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppIconTile(icon: Icons.delete_forever_outlined, color: AppColors.statusRed, size: 56),
                  const SizedBox(height: 18),
                  Semantics(header: true, child: Text('Excluir sua conta', style: AppText.heading())),
                  const SizedBox(height: 6),
                  Text('A exclusão é definitiva e não pode ser desfeita. Serão apagados:',
                      style: AppText.bodySm(color: context.textSecondary).copyWith(height: 1.45)),
                  const SizedBox(height: 4),
                  _item(context, 'seu perfil e sua foto;'),
                  _item(context, 'todos os seus registros de ponto, inclusive os ainda não sincronizados;'),
                  _item(context, 'seus locais de trabalho, lembretes e mensagens ao suporte.'),
                  const SizedBox(height: 18),
                  const AppNotice(
                    icon: Icons.picture_as_pdf_outlined,
                    text: 'Precisa dos seus registros? Exporte o PDF em Registros antes de excluir.',
                    color: AppColors.statusOrange,
                  ),
                  const SizedBox(height: 22),
                  AppTextField(
                    label: 'Digite sua senha para confirmar',
                    hint: 'Sua senha',
                    icon: Icons.lock_outline,
                    controller: _passwordController,
                    obscureText: _obscure,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.password],
                    validator: (v) => (v == null || v.isEmpty) ? 'Digite sua senha' : null,
                    suffixIcon: AppPasswordToggle(obscured: _obscure, onPressed: () => setState(() => _obscure = !_obscure)),
                  ),
                  const SizedBox(height: 12),
                  MergeSemantics(
                    child: InkWell(
                      borderRadius: BorderRadius.circular(AppRadius.inner),
                      onTap: () => setState(() => _confirmed = !_confirmed),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 6),
                        child: Row(
                          children: [
                            Checkbox(
                              value: _confirmed,
                              onChanged: (v) => setState(() => _confirmed = v ?? false),
                              activeColor: AppColors.statusRedStrong,
                            ),
                            Expanded(
                              child: Text('Entendo que todos os meus dados serão apagados para sempre.',
                                  style: AppText.label(color: context.textPrimary, weight: FontWeight.w400).copyWith(fontSize: 14)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ConstrainedBox(
                    constraints: const BoxConstraints(minHeight: 52, minWidth: double.infinity),
                    child: ElevatedButton(
                      onPressed: _deleting ? null : _delete,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.statusRedStrong,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor: AppColors.statusRedStrong.withValues(alpha: 0.45),
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.buttons)),
                      ),
                      child: _deleting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                          : Text('Excluir minha conta', style: AppText.bodySm(color: Colors.white, weight: FontWeight.w600)),
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
