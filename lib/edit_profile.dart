import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'app_theme.dart';
import 'app_avatar.dart';
import 'widgets.dart';
import 'auth_service.dart';
import 'user_profile.dart';
import 'user_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  final _userService = UserService();
  final _picker = ImagePicker();
  late final TextEditingController _nameController;
  late final TextEditingController _emailController;
  late final TextEditingController _phoneController;
  late final TextEditingController _roleController;
  late final TextEditingController _companyController;
  bool _isSaving = false;
  bool _isUploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    // Começa com os dados reais do usuário logado.
    final user = UserSession.current.value;
    _nameController = TextEditingController(text: user?.name ?? '');
    _emailController = TextEditingController(text: user?.email ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
    _roleController = TextEditingController(text: user?.role ?? '');
    _companyController = TextEditingController(text: user?.company ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _roleController.dispose();
    _companyController.dispose();
    super.dispose();
  }

  /// Câmera só existe em celular; no navegador e no Windows só há galeria/arquivos.
  bool get _canUseCamera =>
      !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);

  void _showMessage(String text, {bool isError = false}) {
    if (!mounted) return;
    AppFeedback.show(context, text, type: isError ? AppFeedbackType.error : AppFeedbackType.success);
  }

  Future<void> _showPhotoOptions() async {
    if (_isUploadingPhoto) return;
    final hasPhoto = UserSession.current.value?.photoUrl != null;

    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_canUseCamera) _photoOption(sheetContext, Icons.photo_camera_outlined, 'Tirar foto', 'camera'),
            _photoOption(sheetContext, Icons.photo_library_outlined, 'Escolher da galeria', 'gallery'),
            if (hasPhoto) _photoOption(sheetContext, Icons.delete_outline_rounded, 'Remover foto', 'remove', destructive: true),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;
    switch (action) {
      case 'camera':
        await _pickAndUpload(ImageSource.camera);
      case 'gallery':
        await _pickAndUpload(ImageSource.gallery);
      case 'remove':
        await _removePhoto();
    }
  }

  Widget _photoOption(BuildContext sheetContext, IconData icon, String label, String value, {bool destructive = false}) {
    final color = destructive ? AppColors.statusRed : sheetContext.textPrimary;
    return ListTile(
      minTileHeight: 56,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20),
      leading: AppIconTile(icon: icon, color: destructive ? AppColors.statusRed : null),
      title: Text(label, style: AppText.bodySm(color: color)),
      onTap: () => Navigator.pop(sheetContext, value),
    );
  }

  Future<void> _pickAndUpload(ImageSource source) async {
    try {
      // A imagem já é reduzida aqui (até 800 px), então o envio é rápido e leve.
      final picked = await _picker.pickImage(source: source, maxWidth: 800, maxHeight: 800, imageQuality: 85);
      if (picked == null) return; // o usuário cancelou

      setState(() => _isUploadingPhoto = true);
      final bytes = await picked.readAsBytes();
      await _userService.uploadPhoto(bytes: bytes, filename: picked.name);
      _showMessage('Foto atualizada!');
    } on ApiException catch (e) {
      _showMessage(e.message, isError: true);
    } catch (_) {
      _showMessage('Não foi possível acessar a imagem. Confira as permissões do app.', isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _removePhoto() async {
    setState(() => _isUploadingPhoto = true);
    try {
      await _userService.removePhoto();
      _showMessage('Foto removida.');
    } on ApiException catch (e) {
      _showMessage(e.message, isError: true);
    } finally {
      if (mounted) setState(() => _isUploadingPhoto = false);
    }
  }

  Future<void> _handleSave() async {
    if (_isSaving || !_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    try {
      await _userService.updateMe(
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        role: _roleController.text.trim(),
        company: _companyController.text.trim(),
      );
      if (!mounted) return;
      AppFeedback.success(context, 'Perfil atualizado com sucesso!');
      Navigator.pop(context);
    } on ApiException catch (e) {
      if (!mounted) return;
      AppFeedback.error(context, e.message);
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Widget _buildAvatar(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Alterar foto de perfil',
      excludeSemantics: true,
      child: GestureDetector(
        onTap: _showPhotoOptions,
        child: SizedBox(
          width: 100,
          height: 100,
          child: Stack(
            children: [
              ValueListenableBuilder<UserProfile?>(
                valueListenable: UserSession.current,
                builder: (context, user, _) => ListenableBuilder(
                  listenable: _nameController,
                  builder: (context, _) => AppAvatar(
                    initials: UserProfile.initialsFor(_nameController.text),
                    imageUrl: user?.photoFullUrl,
                    size: 96,
                  ),
                ),
              ),
              if (_isUploadingPhoto)
                Positioned(
                  left: 0,
                  top: 0,
                  child: Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.black.withValues(alpha: 0.45)),
                    child: const Center(
                      child: SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white)),
                    ),
                  ),
                ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.twilightViolet,
                    shape: BoxShape.circle,
                    border: Border.all(color: Theme.of(context).scaffoldBackgroundColor, width: 3),
                  ),
                  child: const Icon(Icons.photo_camera_rounded, size: 15, color: Colors.white),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasPhoto = UserSession.current.value?.photoUrl != null;
    return Scaffold(
      appBar: appSecondaryBar('Editar perfil'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.xxl, 8, AppSpace.xxl, AppSpace.xxl),
          child: AppContentWidth(
            child: Form(
              key: _formKey,
              child: AutofillGroup(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(child: _buildAvatar(context)),
                    const SizedBox(height: 8),
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          TextButton(
                            onPressed: _isUploadingPhoto ? null : _showPhotoOptions,
                            child: Text('Alterar foto', style: AppText.label(color: context.accentPeach, weight: FontWeight.w600)),
                          ),
                          if (hasPhoto)
                            TextButton(
                              onPressed: _isUploadingPhoto ? null : _removePhoto,
                              child: Text('Remover', style: AppText.label(color: context.textTertiary)),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    AppTextField(
                      label: 'Nome completo',
                      icon: Icons.person_outline,
                      controller: _nameController,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.name],
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Digite seu nome' : null,
                    ),
                    const SizedBox(height: 14),
                    AppTextField(
                      label: 'E-mail',
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
                      hint: '(11) 99999-9999',
                      icon: Icons.phone_android_outlined,
                      controller: _phoneController,
                      keyboardType: TextInputType.phone,
                      textInputAction: TextInputAction.next,
                      autofillHints: const [AutofillHints.telephoneNumber],
                    ),
                    const SizedBox(height: 14),
                    LayoutBuilder(builder: (context, constraints) {
                      // Lado a lado quando há espaço; um embaixo do outro em telas estreitas ou fonte grande.
                      final role = AppTextField(
                        label: 'Cargo',
                        icon: Icons.work_outline_rounded,
                        controller: _roleController,
                        textInputAction: TextInputAction.next,
                        autofillHints: const [AutofillHints.jobTitle],
                      );
                      final company = AppTextField(
                        label: 'Empresa',
                        icon: Icons.apartment_rounded,
                        controller: _companyController,
                        textInputAction: TextInputAction.done,
                        autofillHints: const [AutofillHints.organizationName],
                        onFieldSubmitted: (_) => _handleSave(),
                      );
                      final sideBySide = constraints.maxWidth >= 340 && MediaQuery.textScalerOf(context).scale(1) <= 1.15;
                      if (!sideBySide) return Column(children: [role, const SizedBox(height: 14), company]);
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [Expanded(child: role), const SizedBox(width: 12), Expanded(child: company)],
                      );
                    }),
                    const SizedBox(height: 28),
                    AppPrimaryButton(label: 'Salvar alterações', onPressed: _handleSave, isLoading: _isSaving),
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
