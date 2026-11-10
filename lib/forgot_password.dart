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

  void _submit() {
    final contato = _selectedOption == 0 ? _emailController.text.trim() : _phoneController.text.trim();
    AppFeedback.success(
      context,
      _selectedOption == 0 ? 'Link de recuperação enviado para o e-mail!' : 'Código de verificação enviado para o celular!',
    );
    Navigator.push(context, MaterialPageRoute(builder: (_) => ResetPasswordScreen(method: _selectedOption, contact: contato)));
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = _selectedOption == 0;
    return Scaffold(
      appBar: appSecondaryBar(null),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.xxl, 4, AppSpace.xxl, AppSpace.xxl),
          child: AppContentWidth(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const AppIconTile(icon: Icons.key_rounded, size: 56),
                const SizedBox(height: 22),
                Semantics(header: true, child: Text('Recuperar senha', style: AppText.heading())),
                const SizedBox(height: 6),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 180),
                  child: Text(
                    isEmail
                        ? 'Informe o e-mail cadastrado. Enviaremos as instruções para criar uma nova senha.'
                        : 'Informe o celular cadastrado. Enviaremos um código de 6 dígitos por WhatsApp.',
                    key: ValueKey(_selectedOption),
                    style: AppText.bodySm(color: context.textSecondary).copyWith(height: 1.45),
                  ),
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(color: Theme.of(context).cardColor, borderRadius: BorderRadius.circular(AppRadius.pills)),
                  child: Row(
                    children: [
                      Expanded(child: _buildSegment(context, 'E-mail', Icons.email_outlined, 0)),
                      Expanded(child: _buildSegment(context, 'Celular', Icons.phone_android_outlined, 1)),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                if (isEmail)
                  AppTextField(
                    key: const ValueKey('email'),
                    label: 'E-mail',
                    hint: 'exemplo@gmail.com',
                    icon: Icons.email_outlined,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.email],
                    onFieldSubmitted: (_) => _submit(),
                  )
                else
                  AppTextField(
                    key: const ValueKey('phone'),
                    label: 'Número de celular',
                    hint: '(11) 99999-9999',
                    icon: Icons.phone_android_outlined,
                    controller: _phoneController,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.done,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    onFieldSubmitted: (_) => _submit(),
                  ),
                const SizedBox(height: 24),
                AppPrimaryButton(label: isEmail ? 'Enviar link' : 'Enviar código', onPressed: _submit),
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
    );
  }

  Widget _buildSegment(BuildContext context, String label, IconData icon, int index) {
    final selected = _selectedOption == index;
    final color = selected ? Colors.white : context.textTertiary;
    return Semantics(
      button: true,
      selected: selected,
      label: 'Receber por $label',
      excludeSemantics: true,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedOption = index),
          borderRadius: BorderRadius.circular(AppRadius.pills),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            height: 44,
            decoration: BoxDecoration(
              color: selected ? AppColors.twilightViolet : Colors.transparent,
              borderRadius: BorderRadius.circular(AppRadius.pills),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Text(label, style: AppText.label(color: color, weight: FontWeight.w600).copyWith(fontSize: 14)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
