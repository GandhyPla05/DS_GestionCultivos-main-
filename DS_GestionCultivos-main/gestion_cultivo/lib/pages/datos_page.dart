import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/crop_record.dart';
import '../services/local_database.dart';

class DatosPage extends StatefulWidget {
  const DatosPage({super.key});

  @override
  State<DatosPage> createState() => _DatosPageState();
}

class _DatosPageState extends State<DatosPage> {
  final _searchController = TextEditingController();
  Future<List<CropRecord>>? _cropsFuture;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _reload() {
    _cropsFuture = LocalDatabase.instance.getCrops(
      search: _searchController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCropForm(),
        icon: const Icon(Icons.add),
        label: Text(strings.text('addCrop')),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: '${strings.text('search')} ${strings.text('crop')}',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(_reload),
            ),
          ),
          Expanded(
            child: FutureBuilder<List<CropRecord>>(
              future: _cropsFuture,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return _buildError(context, snapshot.error!);
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final crops = snapshot.data!;
                if (crops.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        strings.text('noCrops'),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  );
                }
                return RefreshIndicator(
                  onRefresh: () async {
                    setState(_reload);
                    await _cropsFuture;
                  },
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 96),
                    itemCount: crops.length,
                    itemBuilder: (context, index) =>
                        _buildCropCard(context, crops[index]),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCropCard(BuildContext context, CropRecord crop) {
    final strings = AppLocalizations.of(context);
    final statusLabel = crop.status == 'harvested'
        ? strings.text('harvested')
        : strings.text('active');

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Icon(
          Icons.agriculture,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          crop.crop,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          [
            if (crop.variety.isNotEmpty) crop.variety,
            if (crop.parcel.isNotEmpty) crop.parcel,
          ].join(' • '),
        ),
        trailing: PopupMenuButton<String>(
          tooltip: strings.text('edit'),
          onSelected: (action) {
            if (action == 'edit') _showCropForm(crop: crop);
            if (action == 'delete') _deleteCrop(crop);
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'edit', child: Text(strings.text('edit'))),
            PopupMenuItem(value: 'delete', child: Text(strings.text('delete'))),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _detail(strings.text('status'), statusLabel),
          if (crop.sowingDate != null)
            _detail(strings.text('sowingDate'), _formatDate(crop.sowingDate!)),
          if (crop.harvestDate != null)
            _detail(
              strings.text('harvestDate'),
              _formatDate(crop.harvestDate!),
            ),
          if (crop.irrigation.isNotEmpty)
            _detail(strings.text('irrigation'), crop.irrigation),
          if (crop.fertilization.isNotEmpty)
            _detail(strings.text('fertilization'), crop.fertilization),
          if (crop.pests.isNotEmpty) _detail(strings.text('pests'), crop.pests),
          if (crop.notes.isNotEmpty) _detail(strings.text('notes'), crop.notes),
          const SizedBox(height: 8),
          Text(
            strings.text('modelRequired'),
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: null,
            icon: const Icon(Icons.image_search),
            label: Text(strings.text('analysisPending')),
          ),
        ],
      ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Text('$label: $value'),
    );
  }

  Widget _buildError(BuildContext context, Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          '${AppLocalizations.of(context).text('noResults')}: $error',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }

  Future<void> _showCropForm({CropRecord? crop}) async {
    final strings = AppLocalizations.of(context);
    final formKey = GlobalKey<FormState>();
    final cropController = TextEditingController(text: crop?.crop ?? '');
    final varietyController = TextEditingController(text: crop?.variety ?? '');
    final parcelController = TextEditingController(text: crop?.parcel ?? '');
    final irrigationController = TextEditingController(
      text: crop?.irrigation ?? '',
    );
    final fertilizationController = TextEditingController(
      text: crop?.fertilization ?? '',
    );
    final pestsController = TextEditingController(text: crop?.pests ?? '');
    final notesController = TextEditingController(text: crop?.notes ?? '');
    DateTime? sowingDate = crop?.sowingDate;
    DateTime? harvestDate = crop?.harvestDate;
    String status = crop?.status ?? 'active';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(strings.text(crop == null ? 'addCrop' : 'edit')),
          content: SizedBox(
            width: 520,
            child: SingleChildScrollView(
              child: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: cropController,
                      decoration: InputDecoration(
                        labelText: strings.text('crop'),
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                          ? strings.text('required')
                          : null,
                    ),
                    TextFormField(
                      controller: varietyController,
                      decoration: InputDecoration(
                        labelText: strings.text('variety'),
                      ),
                    ),
                    TextFormField(
                      controller: parcelController,
                      decoration: InputDecoration(
                        labelText: strings.text('parcel'),
                      ),
                    ),
                    _dateField(
                      context,
                      label: strings.text('sowingDate'),
                      value: sowingDate,
                      onSelected: (value) =>
                          setDialogState(() => sowingDate = value),
                    ),
                    TextFormField(
                      controller: irrigationController,
                      decoration: InputDecoration(
                        labelText: strings.text('irrigation'),
                      ),
                    ),
                    TextFormField(
                      controller: fertilizationController,
                      decoration: InputDecoration(
                        labelText: strings.text('fertilization'),
                      ),
                    ),
                    TextFormField(
                      controller: pestsController,
                      decoration: InputDecoration(
                        labelText: strings.text('pests'),
                      ),
                    ),
                    _dateField(
                      context,
                      label: strings.text('harvestDate'),
                      value: harvestDate,
                      onSelected: (value) =>
                          setDialogState(() => harvestDate = value),
                    ),
                    DropdownButtonFormField<String>(
                      initialValue: status,
                      decoration: InputDecoration(
                        labelText: strings.text('status'),
                      ),
                      items: [
                        DropdownMenuItem(
                          value: 'active',
                          child: Text(strings.text('active')),
                        ),
                        DropdownMenuItem(
                          value: 'harvested',
                          child: Text(strings.text('harvested')),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) setDialogState(() => status = value);
                      },
                    ),
                    TextFormField(
                      controller: notesController,
                      maxLines: 3,
                      decoration: InputDecoration(
                        labelText: strings.text('notes'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.text('cancel')),
            ),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final updatedCrop = CropRecord(
                  id:
                      crop?.id ??
                      DateTime.now().microsecondsSinceEpoch.toString(),
                  crop: cropController.text.trim(),
                  variety: varietyController.text.trim(),
                  parcel: parcelController.text.trim(),
                  sowingDate: sowingDate,
                  irrigation: irrigationController.text.trim(),
                  fertilization: fertilizationController.text.trim(),
                  pests: pestsController.text.trim(),
                  harvestDate: harvestDate,
                  status: status,
                  notes: notesController.text.trim(),
                  createdAt: crop?.createdAt ?? DateTime.now(),
                );
                try {
                  await LocalDatabase.instance.saveCrop(updatedCrop);
                  if (!dialogContext.mounted) return;
                  Navigator.pop(dialogContext);
                  setState(_reload);
                  _showMessage(strings.text('cropSaved'));
                } catch (error) {
                  if (dialogContext.mounted) {
                    _showMessage('$error', isError: true);
                  }
                }
              },
              child: Text(strings.text('save')),
            ),
          ],
        ),
      ),
    );

    cropController.dispose();
    varietyController.dispose();
    parcelController.dispose();
    irrigationController.dispose();
    fertilizationController.dispose();
    pestsController.dispose();
    notesController.dispose();
  }

  Widget _dateField(
    BuildContext context, {
    required String label,
    required DateTime? value,
    required ValueChanged<DateTime?> onSelected,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(label),
      subtitle: Text(value == null ? '' : _formatDate(value)),
      trailing: IconButton(
        tooltip: label,
        onPressed: () async {
          final selectedDate = await showDatePicker(
            context: context,
            initialDate: value ?? DateTime.now(),
            firstDate: DateTime(1950),
            lastDate: DateTime(2200),
          );
          if (selectedDate != null) onSelected(selectedDate);
        },
        icon: const Icon(Icons.calendar_month),
      ),
    );
  }

  Future<void> _deleteCrop(CropRecord crop) async {
    final strings = AppLocalizations.of(context);
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(strings.text('confirmDeleteCrop')),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(strings.text('cancel')),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(strings.text('delete')),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;
    try {
      await LocalDatabase.instance.deleteCrop(crop.id);
      if (!mounted) return;
      setState(_reload);
      _showMessage(strings.text('cropDeleted'));
    } catch (error) {
      _showMessage('$error', isError: true);
    }
  }

  String _formatDate(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-'
      '${date.month.toString().padLeft(2, '0')}-'
      '${date.day.toString().padLeft(2, '0')}';

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}
