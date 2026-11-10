import 'package:flutter/material.dart';
import 'app_theme.dart';
import 'widgets.dart';
import 'auth_service.dart';
import 'location_service.dart';

/// Perfil > Locais de trabalho: lista, adiciona, edita e remove os locais
/// usados para identificar onde o usuário bate o ponto.
class WorkLocationsScreen extends StatefulWidget {
  const WorkLocationsScreen({super.key});

  @override
  State<WorkLocationsScreen> createState() => _WorkLocationsScreenState();
}

class _WorkLocationsScreenState extends State<WorkLocationsScreen> {
  final _locationService = LocationService();
  bool _loading = true;
  String? _error;
  LocationResult? _here; // posição atual, para mostrar a distância até cada local

  @override
  void initState() {
    super.initState();
    _load();
    _locate();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await WorkLocations.refresh();
    } on ApiException catch (e) {
      if (e.statusCode != 401) _error = e.message;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _locate() async {
    final result = await _locationService.getCurrentLocation();
    if (mounted) setState(() => _here = result);
  }

  Future<void> _openEditor([KnownLocation? location]) async {
    final message = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (_) => _LocationEditorScreen(location: location, initialPosition: _here)),
    );
    if (message != null && mounted) AppFeedback.success(context, message);
  }

  String _distanceLabel(KnownLocation loc) {
    final here = _here;
    if (here == null || !here.isOk) return 'Raio de ${loc.radiusMeters.round()} m';
    final d = loc.distanceTo(here.latitude!, here.longitude!);
    final distance = d < 1000 ? '${d.round()} m' : '${(d / 1000).toStringAsFixed(1).replaceAll('.', ',')} km';
    return 'Raio de ${loc.radiusMeters.round()} m · a $distance de você';
  }

  bool _isHere(KnownLocation loc) {
    final here = _here;
    return here != null && here.isOk && loc.distanceTo(here.latitude!, here.longitude!) <= loc.radiusMeters;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appSecondaryBar('Locais de trabalho'),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                onRefresh: _load,
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(AppSpace.page, 8, AppSpace.page, 16),
                  children: [
                    AppContentWidth(
                      child: ValueListenableBuilder<List<KnownLocation>>(
                        valueListenable: WorkLocations.items,
                        builder: (context, locations, _) => Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Ao bater o ponto, o app compara sua localização com estes locais e registra o nome do local junto com o ponto.',
                              style: AppText.label(color: context.textSecondary, weight: FontWeight.w400)
                                  .copyWith(fontSize: 14, height: 1.45),
                            ),
                            const SizedBox(height: 18),
                            if (_loading && locations.isEmpty)
                              AppCard(
                                child: Column(
                                  children: List.generate(
                                    2,
                                    (_) => const Padding(
                                      padding: EdgeInsets.symmetric(vertical: 10),
                                      child: Row(children: [
                                        AppSkeleton(width: 36, height: 36, radius: 12),
                                        SizedBox(width: 12),
                                        Expanded(child: AppSkeleton(height: 14)),
                                      ]),
                                    ),
                                  ),
                                ),
                              )
                            else if (locations.isEmpty)
                              AppCard(
                                child: AppEmptyState(
                                  icon: Icons.add_location_alt_outlined,
                                  title: _error == null ? 'Nenhum local cadastrado' : 'Não foi possível carregar os locais',
                                  message: _error ??
                                      'Vá até o seu local de trabalho e toque em "Adicionar local" para salvar a posição.',
                                  actionLabel: _error == null ? null : 'Tentar de novo',
                                  onAction: _error == null ? null : _load,
                                ),
                              )
                            else
                              Material(
                                color: Theme.of(context).cardColor,
                                borderRadius: BorderRadius.circular(AppRadius.cards),
                                clipBehavior: Clip.antiAlias,
                                child: Column(
                                  children: [
                                    for (var i = 0; i < locations.length; i++) ...[
                                      _buildLocationRow(context, locations[i]),
                                      if (i < locations.length - 1)
                                        Divider(height: 1, thickness: 1, color: context.hairline, indent: 64),
                                    ],
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpace.page, 8, AppSpace.page, 16),
              child: AppContentWidth(
                child: AppPrimaryButton(
                  label: 'Adicionar local',
                  icon: Icons.add_location_alt_outlined,
                  onPressed: () => _openEditor(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLocationRow(BuildContext context, KnownLocation loc) {
    final here = _isHere(loc);
    return InkWell(
      onTap: () => _openEditor(loc),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
          child: Row(
            children: [
              AppIconTile(icon: Icons.location_on_outlined, color: context.accentPeach, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(child: Text(loc.name, style: AppText.bodySm(weight: FontWeight.w500))),
                        if (here) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.statusGreen.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(AppRadius.pills),
                            ),
                            child: Text('Você está aqui',
                                style: AppText.caption(color: AppColors.statusGreen, weight: FontWeight.w600).copyWith(fontSize: 11)),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(_distanceLabel(loc), style: AppText.caption(color: context.textTertiary)),
                  ],
                ),
              ),
              IconButton(
                tooltip: 'Editar ${loc.name}',
                icon: Icon(Icons.edit_outlined, size: 18, color: context.textTertiary),
                onPressed: () => _openEditor(loc),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Adicionar (location == null) ou editar um local.
/// Fecha devolvendo a mensagem de sucesso para a lista mostrar.
class _LocationEditorScreen extends StatefulWidget {
  final KnownLocation? location;
  final LocationResult? initialPosition;
  const _LocationEditorScreen({this.location, this.initialPosition});

  @override
  State<_LocationEditorScreen> createState() => _LocationEditorScreenState();
}

class _LocationEditorScreenState extends State<_LocationEditorScreen> {
  static const _radiusOptions = [100, 150, 300, 500];

  final _formKey = GlobalKey<FormState>();
  late final _nameController = TextEditingController(text: widget.location?.name ?? '');
  final _locationService = LocationService();
  late int _radius = widget.location?.radiusMeters.round() ?? 150;
  LocationResult? _captured; // posição nova capturada nesta tela
  bool _locating = false;
  bool _saving = false;

  bool get _isNew => widget.location == null;

  @override
  void initState() {
    super.initState();
    if (!_radiusOptions.contains(_radius)) _radius = 150;
    // Novo local: já usa a posição que a lista tinha acabado de pegar, se houver.
    final initial = widget.initialPosition;
    if (_isNew && initial != null && initial.isOk) _captured = initial;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _capture() async {
    setState(() => _locating = true);
    final result = await _locationService.getCurrentLocation();
    if (!mounted) return;
    setState(() => _locating = false);
    if (result.isOk) {
      setState(() => _captured = result);
    } else {
      AppFeedback.error(context, switch (result.status) {
        LocationStatus.serviceDisabled => 'Ative a localização do aparelho e tente de novo.',
        LocationStatus.permissionDenied ||
        LocationStatus.permissionDeniedForever =>
          'Permita o acesso à localização nas configurações do app.',
        _ => 'Não foi possível obter a localização. Tente de novo em um local aberto.',
      });
    }
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    if (_isNew && _captured == null) {
      AppFeedback.info(context, 'Toque em "Usar minha localização atual" para salvar a posição do local.');
      return;
    }
    setState(() => _saving = true);
    try {
      final name = _nameController.text.trim();
      if (_isNew) {
        await WorkLocations.create(
          name: name,
          latitude: _captured!.latitude!,
          longitude: _captured!.longitude!,
          radiusMeters: _radius,
        );
      } else {
        await WorkLocations.update(
          widget.location!.id!,
          name: name,
          radiusMeters: _radius,
          latitude: _captured?.latitude,
          longitude: _captured?.longitude,
        );
      }
      if (!mounted) return;
      Navigator.pop(context, _isNew ? 'Local "$name" adicionado.' : 'Local "$name" atualizado.');
    } on ApiException catch (e) {
      if (!mounted || e.statusCode == 401) return;
      AppFeedback.error(context, e.message);
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final loc = widget.location!;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Remover "${loc.name}"?'),
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: const Text('Os pontos já registrados continuam com o nome deste local.'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: Text('Cancelar', style: AppText.bodySm(color: dialogContext.textSecondary, weight: FontWeight.w600)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text('Remover', style: AppText.bodySm(color: AppColors.statusRed, weight: FontWeight.w600)),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _saving = true);
    try {
      await WorkLocations.remove(loc.id!);
      if (!mounted) return;
      Navigator.pop(context, 'Local "${loc.name}" removido.');
    } on ApiException catch (e) {
      if (!mounted || e.statusCode == 401) return;
      AppFeedback.error(context, e.message);
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appSecondaryBar(_isNew ? 'Adicionar local' : 'Editar local'),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(AppSpace.xxl, 8, AppSpace.xxl, AppSpace.xxl),
          child: AppContentWidth(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppTextField(
                    label: 'Nome do local',
                    hint: 'Ex.: Escritório Central, Loja Centro',
                    icon: Icons.label_outline_rounded,
                    controller: _nameController,
                    maxLength: 100,
                    textInputAction: TextInputAction.done,
                    validator: (v) => (v == null || v.trim().length < 2) ? 'Dê um nome ao local' : null,
                  ),
                  const SizedBox(height: 20),
                  Text('Posição', style: AppText.label(color: context.textSecondary)),
                  const SizedBox(height: 7),
                  _buildPositionCard(context),
                  const SizedBox(height: 20),
                  Text('Raio', style: AppText.label(color: context.textSecondary)),
                  const SizedBox(height: 4),
                  Text('Distância máxima da posição salva para considerar que você está no local.',
                      style: AppText.caption(color: context.textTertiary)),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final r in _radiusOptions)
                        ChoiceChip(
                          label: Text('$r m'),
                          selected: _radius == r,
                          onSelected: (_) => setState(() => _radius = r),
                          labelStyle: AppText.label(
                              color: _radius == r ? Colors.white : context.textPrimary, weight: FontWeight.w600),
                          selectedColor: AppColors.twilightViolet,
                          backgroundColor: Theme.of(context).cardColor,
                          showCheckmark: false,
                          side: BorderSide.none,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppRadius.pills)),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                        ),
                    ],
                  ),
                  const SizedBox(height: 28),
                  AppPrimaryButton(label: _isNew ? 'Salvar local' : 'Salvar alterações', onPressed: _save, isLoading: _saving),
                  if (!_isNew) ...[
                    const SizedBox(height: 12),
                    AppDangerButton(label: 'Remover local', icon: Icons.delete_outline_rounded, onPressed: _saving ? null : _delete),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPositionCard(BuildContext context) {
    final captured = _captured;
    final String title;
    final String subtitle;
    Color? warning;

    if (captured != null) {
      final accuracy = captured.accuracyMeters?.round();
      title = _isNew ? 'Localização atual capturada' : 'Nova posição capturada';
      if (accuracy != null && accuracy > 100) {
        subtitle = 'Precisão baixa ($accuracy m). Se puder, tente de novo perto de uma janela ou ao ar livre.';
        warning = AppColors.statusOrange;
      } else {
        subtitle = accuracy == null ? 'Posição pronta para salvar.' : 'Precisão de $accuracy m.';
      }
    } else if (_isNew) {
      title = 'Posição ainda não definida';
      subtitle = 'Esteja no local de trabalho e use sua localização atual.';
    } else {
      title = 'Mantendo a posição salva';
      subtitle = 'Se o local mudou de endereço, atualize para a sua localização atual.';
    }

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppIconTile(
                icon: captured != null ? Icons.my_location_rounded : Icons.location_searching_rounded,
                color: warning ?? (captured != null ? AppColors.statusGreen : null),
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.bodySm(weight: FontWeight.w500)),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.caption(color: warning ?? context.textTertiary)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: AppOutlineButton(
              label: _locating
                  ? 'Buscando localização...'
                  : (captured != null ? 'Capturar de novo' : 'Usar minha localização atual'),
              icon: Icons.my_location_rounded,
              onPressed: _locating ? null : _capture,
            ),
          ),
        ],
      ),
    );
  }
}
