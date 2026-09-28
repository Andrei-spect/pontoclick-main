import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton()),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Criar Conta', style: AppText.heading()),
              const SizedBox(height: 6),
              Text('Preencha os dados abaixo para se cadastrar', style: AppText.body(color: context.textSecondary)),
              const SizedBox(height: 28),

              AppTextField(label: 'Nome Completo', hint: 'João Silva', icon: Icons.person_outline),
              const SizedBox(height: 18),
              AppTextField(
                  label: 'E-mail', hint: 'exemplo@gmail.com', icon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
              const SizedBox(height: 18),
              AppTextField(
                  label: 'Número de Celular', hint: '(xx) xxxxx-xxxx', icon: Icons.phone_android_outlined,
                  keyboardType: TextInputType.phone),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Senha',
                icon: Icons.lock_outline,
                obscureText: _obscurePassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: context.textSecondary, size: 19),
                  onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                ),
              ),
              const SizedBox(height: 18),
              AppTextField(
                label: 'Confirmar Senha',
                icon: Icons.lock_outline,
                obscureText: _obscureConfirmPassword,
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: context.textSecondary, size: 19),
                  onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                ),
              ),
              const SizedBox(height: 32),

              AppPrimaryButton(
                label: 'Cadastrar',
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Conta criada com sucesso!')));
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}