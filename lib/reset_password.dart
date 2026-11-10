import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'auth_service.dart';
import 'login.dart';
import 'time_record.dart' show two;

class ResetPasswordScreen extends StatefulWidget {
  /// E-mail para onde o código foi enviado.
  final String email;

  const ResetPasswordScreen({super.key, required this.email});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  /// Mesmo intervalo que a API exige entre dois pedidos de código.
  static const _resendCooldown = 60;

  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;
  bool _isResending = false;

  Timer? _cooldownTimer;
  int _secondsLeft = _resendCooldown;

  @override
  void initState() {
    super.initState();
    _startCooldown(); // o código acabou de ser enviado na tela anterior
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _codeController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _startCooldown() {
    _cooldownTimer?.cancel();
    setState(() => _secondsLeft = _resendCooldown);
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return timer.cancel();
      setState(() => _secondsLeft--);
      if (_secondsLeft <= 0) timer.cancel();
    });
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

  Future<void> _resendCode() async {
    if (_isResending || _secondsLeft > 0) return;
    setState(() => _isResending = true);
    try {
      await _authService.requestPasswordReset(widget.email);
      if (!mounted) return;
      _codeController.clear();
      _startCooldown();
      AppFeedback.success(context, 'Enviamos um novo código. O anterior deixou de valer.');
    } on ApiException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    } finally {
      if (mounted) setState(() => _isResending = false);
    }
  }

  Future<void> _handleSubmit() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await _authService.resetPassword(
        email: widget.email,
        code: _codeController.text,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      AppFeedback.success(context, 'Senha redefinida! Entre com a nova senha.');
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => LoginScreen(initialEmail: widget.email)),
        (route) => false,
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
                        const TextSpan(text: 'Digite o código enviado para '),
                        TextSpan(text: widget.email, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500)),
                        const TextSpan(text: ' e crie uma nova senha.'),
                      ]),
                      style: AppText.bodySm(color: context.textSecondary).copyWith(height: 1.45),
                    ),
                    const SizedBox(height: 24),
                    Text('Código de verificação', style: AppText.label(color: context.textSecondary)),
                    const SizedBox(height: 8),
                    _CodeField(
                      controller: _codeController,
                      validator: (v) => (v == null || v.length != 6) ? 'Digite os 6 dígitos do código' : null,
                    ),
                    const SizedBox(height: 4),
                    Wrap(
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Não recebeu?', style: AppText.label(color: context.textTertiary, weight: FontWeight.w400)),
                        TextButton(
                          onPressed: _secondsLeft > 0 || _isResending ? null : _resendCode,
                          child: Text(
                            _isResending
                                ? 'Enviando...'
                                : _secondsLeft > 0
                                    ? 'Reenviar código em 0:${two(_secondsLeft)}'
                                    : 'Reenviar código',
                            style: AppText.label(
                              color: _secondsLeft > 0 || _isResending ? context.textTertiary : context.accentPeach,
                              weight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
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
/// texto (colar o código inteiro funciona).
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
    widget.controller.addListener(_onControllerChanged);
  }

  void _onControllerChanged() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onControllerChanged);
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
            Semantics(
              label: 'Código de verificação, ${text.length} de $_length dígitos',
              child: Stack(
                children: [
                  Row(
                    children: List.generate(_length, (i) {
                      final active = _focusNode.hasFocus && (i == text.length || (i == _length - 1 && text.length == _length));
                      final Color border =
                          field.hasError ? AppColors.statusRed : (active ? AppColors.twilightViolet : Colors.transparent);
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
                        onChanged: field.didChange,
                      ),
                    ),
                  ),
                ],
              ),
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
