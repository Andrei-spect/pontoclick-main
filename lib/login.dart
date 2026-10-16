import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'auth_service.dart';
import 'home.dart';
import 'register.dart';
import 'forgot_password.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.login(email: _emailController.text.trim(), password: _passwordController.text);
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message), backgroundColor: AppColors.statusRed));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration:
                        BoxDecoration(color: AppColors.twilightViolet.withOpacity(0.16), shape: BoxShape.circle),
                    child: const Icon(Icons.access_time_filled_rounded, size: 44, color: AppColors.twilightViolet),
                  ),
                  const SizedBox(height: 18),
                  RichText(
                    text: TextSpan(
                      style: AppText.headingLg(),
                      children: [
                        TextSpan(text: 'Ponto', style: TextStyle(color: Theme.of(context).colorScheme.onSurface)),
                        TextSpan(text: 'Click', style: TextStyle(color: context.accentPeach)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text('Seu controle de ponto simples e seguro',
                      style: AppText.body(color: context.textSecondary), textAlign: TextAlign.center),
                  const SizedBox(height: 36),

                  AppTextField(
                    label: 'E-mail',
                    hint: 'exemplo@gmail.com',
                    icon: Icons.email_outlined,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? 'Digite um e-mail válido' : null,
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    label: 'Senha',
                    icon: Icons.lock_outline,
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    validator: (v) => (v == null || v.isEmpty) ? 'Digite sua senha' : null,
                    suffixIcon: IconButton(
                      icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                          color: context.textSecondary, size: 19),
                      onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  const SizedBox(height: 26),

                  AppPrimaryButton(label: 'Entrar', onPressed: _handleLogin, isLoading: _isLoading),
                  const SizedBox(height: 16),

                  TextButton(
                    onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen())),
                    child: Text('Esqueci minha senha',
                        style: AppText.caption(color: context.accentPeach, weight: FontWeight.w500).copyWith(fontSize: 13)),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('Não tem uma conta? ', style: AppText.caption(color: context.textSecondary).copyWith(fontSize: 13)),
                      GestureDetector(
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: Text('Quero me registrar',
                            style: AppText.caption(color: context.accentPeach, weight: FontWeight.w700).copyWith(fontSize: 13)),
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
