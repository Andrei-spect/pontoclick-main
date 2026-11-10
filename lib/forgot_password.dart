import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'auth_service.dart';
import 'reset_password.dart';

class ForgotPasswordScreen extends StatefulWidget {
  /// E-mail já digitado no Login (opcional), para não precisar digitar de novo.
  final String? initialEmail;
  const ForgotPasswordScreen({super.key, this.initialEmail});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _emailController = TextEditingController(text: widget.initialEmail ?? '');
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim();

    setState(() => _isLoading = true);
    try {
      await _authService.requestPasswordReset(email);
      if (!mounted) return;
      AppFeedback.success(context, 'Se houver uma conta com esse e-mail, enviamos um código de 6 dígitos.');
      Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen(email: email)));
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const AppIconTile(icon: Icons.key_rounded, size: 56),
                  const SizedBox(height: 22),
                  Semantics(header: true, child: Text('Recuperar senha', style: AppText.heading())),
                  const SizedBox(height: 6),
                  Text(
                    'Informe o e-mail da sua conta. Enviaremos um código de 6 dígitos para você criar uma nova senha.',
                    style: AppText.bodySm(color: context.textSecondary).copyWith(height: 1.45),
                  ),
                  const SizedBox(height: 24),
                  AppTextField(
                    label: 'E-mail',
                    hint: 'exemplo@gmail.com',
                    icon: Icons.email_outlined,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    onFieldSubmitted: (_) => _submit(),
                    validator: (v) => (v == null || !v.contains('@')) ? 'Digite um e-mail válido' : null,
                  ),
                  const SizedBox(height: 24),
                  AppPrimaryButton(label: 'Enviar código', onPressed: _submit, isLoading: _isLoading),
                  const SizedBox(height: 18),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline_rounded, size: 16, color: context.textTertiary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'O código vale por 15 minutos. Se não chegar, confira a caixa de spam ou peça um novo.',
                          style: AppText.label(color: context.textTertiary, weight: FontWeight.w400).copyWith(height: 1.45),
                        ),
                      ),
                    ],
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
