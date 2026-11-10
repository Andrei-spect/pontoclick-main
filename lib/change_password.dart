import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'auth_service.dart';
import 'user_service.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      await _userService.changePassword(
        currentPassword: _currentController.text,
        newPassword: _newController.text,
      );
      if (!mounted) return;
      AppFeedback.success(context, 'Senha alterada com sucesso!');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  /// Item da lista de requisitos, marcado conforme o usuário digita.
  Widget _requirement(BuildContext context, String text, bool ok) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: ok ? AppColors.statusGreen.withValues(alpha: 0.16) : Colors.transparent,
              border: ok ? null : Border.all(color: Theme.of(context).dividerColor, width: 1.5),
            ),
            child: ok ? const Icon(Icons.check_rounded, size: 12, color: AppColors.statusGreen) : null,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: AppText.label(color: ok ? context.textSecondary : context.textTertiary, weight: FontWeight.w400)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appSecondaryBar('Alterar senha'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.xxl, 8, AppSpace.xxl, AppSpace.xxl),
          child: AppContentWidth(
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AppCard(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const AppIconTile(icon: Icons.verified_user_outlined, size: 40),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Text(
                              'Sua nova senha deve ser diferente da atual. Você continua conectado neste aparelho depois da troca.',
                              style: AppText.label(color: context.textSecondary, weight: FontWeight.w400).copyWith(fontSize: 14, height: 1.45),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    AppTextField(
                      label: 'Senha atual',
                      hint: 'Digite a senha atual',
                      icon: Icons.lock_outline,
                      controller: _currentController,
                      obscureText: _obscureCurrent,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.password],
                      validator: (v) => (v == null || v.isEmpty) ? 'Digite sua senha atual' : null,
                      suffixIcon: AppPasswordToggle(
                        obscured: _obscureCurrent,
                        onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Divider(height: 1, color: context.hairline),
                    const SizedBox(height: 18),
                    AppTextField(
                      label: 'Nova senha',
                      hint: 'Crie a nova senha',
                      icon: Icons.lock_outline,
                      controller: _newController,
                      obscureText: _obscureNew,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Digite a nova senha';
                        if (v.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
                        if (v == _currentController.text) return 'A nova senha deve ser diferente da atual';
                        return null;
                      },
                      suffixIcon: AppPasswordToggle(
                        obscured: _obscureNew,
                        onPressed: () => setState(() => _obscureNew = !_obscureNew),
                      ),
                    ),
                    ListenableBuilder(
                      listenable: Listenable.merge([_newController, _currentController]),
                      builder: (context, _) {
                        final value = _newController.text;
                        return Padding(
                          padding: const EdgeInsets.only(left: 12, top: 4),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _requirement(context, 'Pelo menos 6 caracteres', value.length >= 6),
                              _requirement(
                                  context, 'Diferente da senha atual', value.isNotEmpty && value != _currentController.text),
                            ],
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Confirmar nova senha',
                      hint: 'Repita a nova senha',
                      icon: Icons.lock_outline,
                      controller: _confirmController,
                      obscureText: _obscureConfirm,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => _handleSubmit(),
                      validator: (v) => (v != _newController.text) ? 'As senhas não coincidem' : null,
                      suffixIcon: AppPasswordToggle(
                        obscured: _obscureConfirm,
                        onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                      ),
                    ),
                    const SizedBox(height: 28),
                    AppPrimaryButton(label: 'Alterar senha', onPressed: _handleSubmit, isLoading: _isSaving),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
