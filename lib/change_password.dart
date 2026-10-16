import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _isSaving = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1)); // TODO: PUT /users/change-password na API real
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Senha alterada com sucesso!')));
    Navigator.pop(context);
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
                  child: const Icon(Icons.lock_person_rounded, size: 34, color: AppColors.twilightViolet),
                ),
                const SizedBox(height: 20),
                Text('Altere sua senha', style: AppText.headingSm()),
                const SizedBox(height: 6),
                Text('Sua nova senha deve ser diferente da atual', style: AppText.body(color: context.textSecondary)),
                const SizedBox(height: 26),

                AppTextField(
                  label: 'Senha Atual',
                  icon: Icons.lock_outline,
                  controller: _currentController,
                  obscureText: _obscureCurrent,
                  validator: (v) => (v == null || v.isEmpty) ? 'Digite sua senha atual' : null,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureCurrent ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: context.textSecondary, size: 19),
                    onPressed: () => setState(() => _obscureCurrent = !_obscureCurrent),
                  ),
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Nova Senha',
                  icon: Icons.lock_outline,
                  controller: _newController,
                  obscureText: _obscureNew,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Digite a nova senha';
                    if (v.length < 6) return 'A senha deve ter pelo menos 6 caracteres';
                    if (v == _currentController.text) return 'A nova senha deve ser diferente da atual';
                    return null;
                  },
                  suffixIcon: IconButton(
                    icon: Icon(_obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: context.textSecondary, size: 19),
                    onPressed: () => setState(() => _obscureNew = !_obscureNew),
                  ),
                ),
                const SizedBox(height: 18),
                AppTextField(
                  label: 'Confirmar Nova Senha',
                  icon: Icons.lock_outline,
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  validator: (v) => (v != _newController.text) ? 'As senhas não coincidem' : null,
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined, color: context.textSecondary, size: 19),
                    onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                ),
                const SizedBox(height: 32),
                AppPrimaryButton(label: 'Alterar Senha', onPressed: _handleSubmit, isLoading: _isSaving),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
