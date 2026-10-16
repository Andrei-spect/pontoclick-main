import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController(text: 'João Silva');
  final _emailController = TextEditingController(text: 'joao.silva@gmail.com');
  final _roleController = TextEditingController(text: 'Desenvolvedor');
  final _companyController = TextEditingController(text: 'TechCorp');
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _roleController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    await Future.delayed(const Duration(seconds: 1)); // TODO: PUT /users/me na API real
    if (!mounted) return;
    setState(() => _isSaving = false);
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Perfil atualizado com sucesso!')));
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(leading: const AppBackButton(), title: Text('Editar Perfil', style: AppText.body(weight: FontWeight.w600))),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Stack(
                    children: [
                      Container(
                        width: 84,
                        height: 84,
                        decoration: BoxDecoration(color: AppColors.twilightViolet.withOpacity(0.2), shape: BoxShape.circle),
                        alignment: Alignment.center,
                        child: Text('JS', style: AppText.headingSm(weight: FontWeight.w600)),
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: const BoxDecoration(color: AppColors.twilightViolet, shape: BoxShape.circle),
                          child: const Icon(Icons.camera_alt_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 28),
                AppTextField(
                    label: 'Nome Completo',
                    icon: Icons.person_outline,
                    controller: _nameController,
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Digite seu nome' : null),
                const SizedBox(height: 18),
                AppTextField(
                    label: 'E-mail',
                    icon: Icons.email_outlined,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => (v == null || !v.contains('@')) ? 'Digite um e-mail válido' : null),
                const SizedBox(height: 18),
                AppTextField(label: 'Cargo', icon: Icons.work_outline_rounded, controller: _roleController),
                const SizedBox(height: 18),
                AppTextField(label: 'Empresa', icon: Icons.apartment_rounded, controller: _companyController),
                const SizedBox(height: 32),
                AppPrimaryButton(label: 'Salvar Alterações', onPressed: _handleSave, isLoading: _isSaving),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
