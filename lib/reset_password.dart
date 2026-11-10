import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'login.dart';

class ResetPasswordScreen extends StatefulWidget {
  final int method;
  final String contact;

  const ResetPasswordScreen({super.key, required this.method, required this.contact});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? v) {
    if (v == null || v.isEmpty) return 'Digite a nova senha';
    if (v.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
    return null;
  }

  String? _validateConfirm(String? v) {
    if (v == null || v.isEmpty) return 'Confirme a nova senha';
    if (v != _passwordController.text) return 'As senhas não coincidem';
    return null;
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    await Future.delayed(const Duration(seconds: 1)); // TODO: chamar POST /auth/reset-password
    if (!mounted) return;
    setState(() => _isLoading = false);
    AppFeedback.success(context, 'Senha redefinida com sucesso!');
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    final contact = widget.contact.isEmpty ? (widget.method == 0 ? 'seu e-mail' : 'seu celular') : widget.contact;
    return Scaffold(
      appBar: appSecondaryBar(null),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.xxl, 4, AppSpace.xxl, AppSpace.xxl),
          child: AppContentWidth(
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Semantics(header: true, child: Text('Redefinir senha', style: AppText.heading())),
                    const SizedBox(height: 6),
                    Text.rich(
                      TextSpan(children: [
                        TextSpan(text: widget.method == 0 ? 'Crie uma nova senha para a conta ' : 'Digite o código enviado para '),
                        TextSpan(text: contact, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500)),
                        TextSpan(text: widget.method == 0 ? '.' : ' e crie uma nova senha.'),
                      ]),
                      style: AppText.bodySm(color: context.textSecondary).copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 24),
                    if (widget.method == 1) ...[
                      Text('Código de verificação', style: AppText.label(color: context.textSecondary)),
                      const SizedBox(height: 8),
                      _CodeField(
                        controller: _codeController,
                        validator: (v) => (v == null || v.length < 4) ? 'Código inválido' : null,
                      ),
                      const SizedBox(height: 22),
                    ],
                    AppTextField(
                      label: 'Nova senha',
                      hint: 'Mínimo de 6 caracteres',
                      icon: Icons.lock_outline,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: _validatePassword,
                      suffixIcon: AppPasswordToggle(
                        obscured: _obscurePassword,
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Confirmar nova senha',
                      hint: 'Repita a nova senha',
                      icon: Icons.lock_outline,
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => _handleSubmit(),
                      validator: _validateConfirm,
                      suffixIcon: AppPasswordToggle(
                        obscured: _obscureConfirmPassword,
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(label: 'Redefinir senha', onPressed: _handleSubmit, isLoading: _isLoading),
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

/// Código de 6 dígitos em caixas separadas. Por baixo é um único campo de
/// texto (colar o código inteiro funciona), com a mesma validação de antes.
class _CodeField extends StatefulWidget {
  final TextEditingController controller;
  final String? Function(String?) validator;
  const _CodeField({required this.controller, required this.validator});

  @override
  State<_CodeField> createState() => _CodeFieldState();
}

class _CodeFieldState extends State<_CodeField> {
  static const _length = 6;
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: (_) => widget.validator(widget.controller.text),
      builder: (field) {
        final text = widget.controller.text;
        final errorColor = context.isDarkMode ? const Color(0xFFF87171) : const Color(0xFFC62828);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                Row(
                  children: List.generate(_length, (i) {
                    final active = _focusNode.hasFocus && (i == text.length || (i == _length - 1 && text.length == _length));
                    final Color border = field.hasError
                        ? AppColors.statusRed
                        : (active ? AppColors.twilightViolet : Colors.transparent);
                    return Expanded(
                      child: Container(
                        height: 56,
                        margin: EdgeInsets.only(right: i == _length - 1 ? 0 : 8),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: Theme.of(context).cardColor,
                          borderRadius: BorderRadius.circular(AppRadius.cards),
                          border: Border.all(color: border, width: 1.5),
                        ),
                        child: Text(i < text.length ? text[i] : '',
                            style: AppText.numeric(AppText.headingSm(weight: FontWeight.w600))),
                      ),
                    );
                  }),
                ),
                Positioned.fill(
                  child: Opacity(
                    opacity: 0,
                    child: TextField(
                      controller: widget.controller,
                      focusNode: _focusNode,
                      keyboardType: TextInputType.number,
                      autofillHints: const [AutofillHints.oneTimeCode],
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(_length)],
                      showCursor: false,
                      enableInteractiveSelection: false,
                      decoration: const InputDecoration(border: InputBorder.none, counterText: ''),
                      onChanged: (v) {
                        field.didChange(v);
                        setState(() {});
                      },
                    ),
                  ),
                ),
              ],
            ),
            if (field.hasError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 4),
                child: Text(field.errorText!, style: AppText.caption(color: errorColor)),
              ),
            ],
          ],
        );
      },
    );
  }
}
