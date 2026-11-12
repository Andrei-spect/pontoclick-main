import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'auth_service.dart';
import 'main_shell.dart';
import 'register.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  /// E-mail já preenchido (ex: depois de redefinir a senha).
  final String? initialEmail;
  const LoginScreen({super.key, this.initialEmail});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final _emailController = TextEditingController(text: widget.initialEmail ?? '');
  final _passwordController = TextEditingController();
  final _passwordFocus = FocusNode();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _fillLastEmail();
  }

  /// Preenche com o último e-mail que entrou neste aparelho e já leva o cursor para a senha.
  Future<void> _fillLastEmail() async {
    final email = widget.initialEmail ?? await AuthService.getLastEmail();
    if (!mounted || email == null || email.isEmpty) return;
    if (_emailController.text.isEmpty) _emailController.text = email;
    _passwordFocus.requestFocus();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_isLoading || !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.login(email: _emailController.text.trim(), password: _passwordController.text);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const MainShell()));
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
      body: SafeArea(
        child: AppContentWidth(
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: AppSpace.xxl),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Form(
                  key: _formKey,
                  child: AutofillGroup(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const SizedBox(height: 24),
                        Column(
                          children: [
                            const AppLogo(),
                            const SizedBox(height: 6),
                            Text('Seu controle de ponto simples e seguro',
                                style: AppText.bodySm(color: context.textSecondary), textAlign: TextAlign.center),
                            const SizedBox(height: 32),
                            AppTextField(
                              label: 'E-mail',
                              hint: 'exemplo@gmail.com',
                              icon: Icons.email_outlined,
                              controller: _emailController,
                              keyboardType: TextInputType.emailAddress,
                              textInputAction: TextInputAction.next,
                              autofillHints: const [AutofillHints.email, AutofillHints.username],
                              validator: (v) => (v == null || !v.contains('@')) ? 'Digite um e-mail válido' : null,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              label: 'Senha',
                              hint: 'Sua senha',
                              focusNode: _passwordFocus,
                              icon: Icons.lock_outline,
                              controller: _passwordController,
                              obscureText: _obscurePassword,
                              textInputAction: TextInputAction.done,
                              autofillHints: const [AutofillHints.password],
                              onFieldSubmitted: (_) => _handleLogin(),
                              validator: (v) => (v == null || v.isEmpty) ? 'Digite sua senha' : null,
                              suffixIcon: AppPasswordToggle(
                                obscured: _obscurePassword,
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                            ),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton(
                                onPressed: () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => ForgotPasswordScreen(initialEmail: _emailController.text.trim()))),
                                child: Text('Esqueci minha senha', style: AppText.label(color: context.accentPeach)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            AppPrimaryButton(label: 'Entrar', onPressed: _handleLogin, isLoading: _isLoading),
                          ],
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 24, bottom: 12),
                          child: Wrap(
                            alignment: WrapAlignment.center,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text('Não tem uma conta?', style: AppText.label(color: context.textSecondary, weight: FontWeight.w400).copyWith(fontSize: 14)),
                              TextButton(
                                onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                                child: Text('Criar conta',
                                    style: AppText.label(color: context.accentPeach, weight: FontWeight.w600).copyWith(fontSize: 14)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
