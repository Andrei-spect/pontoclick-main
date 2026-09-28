import 'package:flutter/material.dart';
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
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha redefinida com sucesso!')));
    Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: AppColors.twilightViolet.withOpacity(0.16), shape: BoxShape.circle),
                  child: const Icon(Icons.lock_reset_rounded, size: 34, color: AppColors.twilightViolet),
                ),
                const SizedBox(height: 20),
                Text('Redefinir Senha', style: AppText.heading()),
                const SizedBox(height: 6),
                Text(
                  widget.method == 0
                      ? 'Crie uma nova senha para sua conta ${widget.contact}'
                      : 'Digite o código enviado para ${widget.contact} e crie uma nova senha',
                  style: AppText.body(color: context.textSecondary),
                ),
                const SizedBox(height: 26),

                if (widget.method == 1) ...[
                  AppTextField(
                    label: 'Código de Verificação',
                    hint: '000000',
                    icon: Icons.pin_outlined,
                    controller: _codeController,
                    keyboardType: TextInputType.number,
                    maxLength: 6,
                    validator: (v) => (v == null || v.length < 4) ? 'Código inválido' : null,
                  ),
                  const SizedBox(height: 18),
                ],

                AppTextField(
                  label: 'Nova Senha',
                  icon: Icons.lock_outline,
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  validator: _validatePassword,
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: context.textSecondary, size: 19),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Confirmar Nova Senha',
                  icon: Icons.lock_outline,
                  controller: _confirmPasswordController,
                  obscureText: _obscureConfirmPassword,
                  validator: _validateConfirm,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                        color: context.textSecondary, size: 19),
                    onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  ),
                ),
                const SizedBox(height: 32),
                AppPrimaryButton(label: 'Redefinir Senha', onPressed: _handleSubmit, isLoading: _isLoading),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}