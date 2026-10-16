import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'reset_password.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  int _selectedOption = 0; // 0 = E-mail, 1 = Celular
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

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
              Text('Recuperar Senha', style: AppText.heading()),
              const SizedBox(height: 6),
              Text(
                _selectedOption == 0
                    ? 'Digite seu e-mail cadastrado para receber o link de redefinição'
                    : 'Digite seu celular cadastrado para receber o código por WhatsApp',
                style: AppText.body(color: context.textSecondary),
              ),
              const SizedBox(height: 24),

              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppRadius.pills)),
                child: Row(
                  children: [
                    Expanded(child: _buildSegment(context, 'E-mail', 0)),
                    Expanded(child: _buildSegment(context, 'Celular', 1)),
                  ],
                ),
              ),
              const SizedBox(height: 28),

              if (_selectedOption == 0)
                AppTextField(
                    label: 'E-mail',
                    hint: 'exemplo@gmail.com',
                    icon: Icons.email_outlined,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress)
              else
                AppTextField(
                    label: 'Número de Celular',
                    hint: '(11) 99999-9999',
                    icon: Icons.phone_android_outlined,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone),

              const SizedBox(height: 32),
              AppPrimaryButton(
                label: _selectedOption == 0 ? 'Enviar Link' : 'Enviar Código',
                onPressed: () {
                  final contato = _selectedOption == 0 ? _emailController.text.trim() : _phoneController.text.trim();
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(_selectedOption == 0
                          ? 'Link de recuperação enviado para o e-mail!'
                          : 'Código de verificação enviado para o celular!')));
                  Navigator.push(context,
                      MaterialPageRoute(builder: (_) => ResetPasswordScreen(method: _selectedOption, contact: contato)));
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSegment(BuildContext context, String label, int index) {
    final selected = _selectedOption == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedOption = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.twilightViolet : Colors.transparent,
          borderRadius: BorderRadius.circular(AppRadius.pills),
        ),
        child: Center(
          child: Text(label,
              style: AppText.caption(
                  color: selected ? Colors.white : context.textTertiary, weight: FontWeight.w600)),
        ),
      ),
    );
  }
}
