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
                        const SizedBox(height: 20),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const AppBrand(size: 32),
                            const SizedBox(height: 28),
                            const AppHeroHeader(
                              eyebrow: AppEyebrow(tag: 'Grátis', text: 'Funciona até sem internet'),
                              title: [('Seu ponto, ', HeroTone.plain), ('de onde você estiver.', HeroTone.accent)],
                              lead: 'Registre entrada, intervalo e saída pelo celular e acompanhe suas horas extras.',
                              fontSize: 36,
                            ),
                            const SizedBox(height: 28),
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
                                child: Text('Esqueci minha senha', style: AppText.label(color: context.violetText, weight: FontWeight.w600)),
                              ),
                            ),
                            const SizedBox(height: 6),
                            AppPrimaryButton(label: 'Entrar', icon: Icons.arrow_forward_rounded, onPressed: _handleLogin, isLoading: _isLoading),
                            const SizedBox(height: 28),
                            const _AudienceRow(),
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
                                    style: AppText.label(color: context.violetText, weight: FontWeight.w600).copyWith(fontSize: 14)),
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

/// Grupo de avatares do hero-01: para quem o app foi feito.
class _AudienceRow extends StatelessWidget {
  const _AudienceRow();

  static const _icons = [Icons.local_shipping_outlined, Icons.two_wheeler_rounded, Icons.build_outlined, Icons.dark_mode_outlined];

  @override
  Widget build(BuildContext context) {
    final colors = [AppColors.twilightViolet, context.accentPeach, AppColors.statusGreenStrong, AppColors.statusBlueStrong];
    final bg = Theme.of(context).scaffoldBackgroundColor;
    return Row(
      children: [
        SizedBox(
          width: 38.0 + 24 * (_icons.length - 1),
          height: 38,
          child: Stack(
            children: [
              for (var i = 0; i < _icons.length; i++)
                Positioned(
                  left: 24.0 * i,
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      // Cor sólida (mistura com o fundo) para a sobreposição não ficar transparente.
                      color: Color.alphaBlend(colors[i].withValues(alpha: context.isDarkMode ? 0.30 : 0.16), bg),
                      border: Border.all(color: bg, width: 2.5),
                    ),
                    child: Icon(_icons[i], size: 17, color: colors[i]),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text.rich(
            TextSpan(children: [
              TextSpan(text: 'Feito para quem trabalha na rua. ', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600)),
              const TextSpan(text: 'Motoristas, entregadores, técnicos e turno da noite.'),
            ]),
            style: AppText.label(color: context.textTertiary, weight: FontWeight.w400),
          ),
        ),
      ],
    );
  }
}
