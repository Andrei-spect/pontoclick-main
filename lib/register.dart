import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'auth_service.dart';
import 'main_shell.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.register(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim().isEmpty ? null : _phoneController.text.trim(),
        password: _passwordController.text,
      );
      if (!mounted) return;
      // O registro já retorna um token válido — entra direto, sem pedir login de novo.
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const MainShell()), (route) => false);
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
                    Semantics(header: true, child: Text('Criar conta', style: AppText.heading())),
                    const SizedBox(height: 6),
                    Text('Preencha seus dados para começar a registrar o ponto.',
                        style: AppText.bodySm(color: context.textSecondary).copyWith(height: 1.45)),
                    const SizedBox(height: 24),
                    AppTextField(
                      label: 'Nome completo',
                      hint: 'Como está no seu documento',
                      icon: Icons.person_outline,
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Digite seu nome' : null,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'E-mail',
                      hint: 'exemplo@gmail.com',
                      icon: Icons.email_outlined,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.email],
                      validator: (v) => (v == null || !v.contains('@')) ? 'Digite um e-mail válido' : null,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Celular',
                      labelSuffix: '(opcional)',
                      hint: '(11) 99999-9999',
                      icon: Icons.phone_android_outlined,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Senha',
                      hint: 'Mínimo de 6 caracteres',
                      icon: Icons.lock_outline,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.newPassword],
                      validator: (v) => (v == null || v.length < 6) ? 'A senha deve ter pelo menos 6 caracteres' : null,
                      suffixIcon: AppPasswordToggle(
                        obscured: _obscurePassword,
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'Confirmar senha',
                      hint: 'Repita a senha',
                      icon: Icons.lock_outline,
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      autofillHints: const [AutofillHints.newPassword],
                      onFieldSubmitted: (_) => _handleRegister(),
                      validator: (v) => (v != _passwordController.text) ? 'As senhas não coincidem' : null,
                      suffixIcon: AppPasswordToggle(
                        obscured: _obscureConfirmPassword,
                        onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                      ),
                    ),
                    const SizedBox(height: 24),
                    AppPrimaryButton(label: 'Criar conta', onPressed: _handleRegister, isLoading: _isLoading),
                    const SizedBox(height: 12),
                    Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text('Já tem uma conta?',
                            style: AppText.label(color: context.textSecondary, weight: FontWeight.w400).copyWith(fontSize: 14)),
                        TextButton(
                          onPressed: () => Navigator.maybePop(context),
                          child: Text('Entrar',
                              style: AppText.label(color: context.accentPeach, weight: FontWeight.w600).copyWith(fontSize: 14)),
                        ),
                      ],
                    ),
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
