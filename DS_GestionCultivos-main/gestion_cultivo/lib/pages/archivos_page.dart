import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../models/crop_record.dart';
import '../services/document_service.dart';
import '../services/local_database.dart';

class ArchivosPage extends StatefulWidget {
  const ArchivosPage({super.key});

  @override
  State<ArchivosPage> createState() => _ArchivosPageState();
}

class _ArchivosPageState extends State<ArchivosPage> {
  final _documentService = const DocumentService();
  List<CropAttachment> _attachments = [];
  List<CropRecord> _crops = [];
  String? _selectedCropId;
  String _searchQuery = '';
  String? _error;
  bool _isLoading = true;
  bool _isImporting = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  List<CropAttachment> get _filteredAttachments {
    final query = _searchQuery.trim().toLowerCase();
    if (query.isEmpty) return _attachments;
    return _attachments
        .where(
          (file) =>
              file.name.toLowerCase().contains(query) ||
              file.extension.toLowerCase().contains(query) ||
              file.extractedText.toLowerCase().contains(query),
        )
        .toList();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait([
        LocalDatabase.instance.getAttachments(),
        LocalDatabase.instance.getCrops(),
      ]);
      if (!mounted) return;
      setState(() {
        _attachments = results[0] as List<CropAttachment>;
        _crops = results[1] as List<CropRecord>;
        if (_selectedCropId != null &&
            !_crops.any((crop) => crop.id == _selectedCropId)) {
          _selectedCropId = null;
        }
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _error = error.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final files = _filteredAttachments;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              DropdownButtonFormField<String>(
                initialValue: _selectedCropId ?? '',
                decoration: InputDecoration(
                  labelText: strings.text('linkCrop'),
                  border: const OutlineInputBorder(),
                ),
                items: [
                  DropdownMenuItem(
                    value: '',
                    child: Text(strings.text('noCrop')),
                  ),
                  ..._crops.map(
                    (crop) => DropdownMenuItem(
                      value: crop.id,
                      child: Text('${crop.crop} · ${crop.parcel}'),
                    ),
                  ),
                ],
                onChanged: (value) => setState(
                  () => _selectedCropId = value == null || value.isEmpty
                      ? null
                      : value,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _isImporting ? null : _pickFiles,
                  icon: _isImporting
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.upload_file),
                  label: Text(strings.text('uploadFiles')),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                strings.text('supportedFiles'),
                style: Theme.of(context).textTheme.bodySmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              TextField(
                decoration: InputDecoration(
                  labelText: strings.text('search'),
                  prefixIcon: const Icon(Icons.search),
                  border: const OutlineInputBorder(),
                ),
                onChanged: (value) => setState(() => _searchQuery = value),
              ),
            ],
          ),
        ),
        Expanded(child: _buildFileList(context, files)),
      ],
    );
  }

  Widget _buildFileList(BuildContext context, List<CropAttachment> files) {
    final strings = AppLocalizations.of(context);
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(_error!, textAlign: TextAlign.center),
        ),
      );
    }
    if (files.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            _searchQuery.isEmpty
                ? strings.text('noFiles')
                : strings.text('noResults'),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
        itemCount: files.length,
        itemBuilder: (context, index) => _buildFileCard(context, files[index]),
      ),
    );
  }

  Widget _buildFileCard(BuildContext context, CropAttachment file) {
    final strings = AppLocalizations.of(context);
    final linkedCrop = _crops.where((crop) => crop.id == file.cropId);
    final cropName = linkedCrop.isEmpty
        ? strings.text('noCrop')
        : linkedCrop.first.crop;

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: ExpansionTile(
        leading: Icon(
          _fileIcon(file.extension),
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(file.name, maxLines: 2, overflow: TextOverflow.ellipsis),
        subtitle: Text('$cropName · ${_formatSize(file.size)}'),
        trailing: PopupMenuButton<String>(
          tooltip: strings.text('delete'),
          onSelected: (action) {
            if (action == 'open') _openFile(file);
            if (action == 'delete') _deleteFile(file);
          },
          itemBuilder: (context) => [
            PopupMenuItem(value: 'open', child: Text(strings.text('openFile'))),
            PopupMenuItem(value: 'delete', child: Text(strings.text('delete'))),
          ],
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${file.extension.toUpperCase()} · ${_formatDate(file.addedAt)}',
          ),
          const SizedBox(height: 8),
          if (file.extractedText.isNotEmpty) ...[
            Text(
              strings.text('extractedText'),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            SelectableText(file.extractedText),
          ] else
            Text(
              file.extension == 'pdf' || file.extension == 'docx'
                  ? strings.text('noExtractedText')
                  : strings.text('modelRequired'),
            ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: () => _openFile(file),
                icon: const Icon(Icons.open_in_new),
                label: Text(strings.text('openFile')),
              ),
              OutlinedButton.icon(
                onPressed: () => _deleteFile(file),
                icon: const Icon(Icons.delete_outline),
                label: Text(strings.text('delete')),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _pickFiles() async {
    setState(() => _isImporting = true);
    try {
      final imported = await _documentService.pickAndStoreFiles(
        cropId: _selectedCropId,
      );
      await _load();
      if (mounted && imported.isNotEmpty) {
        _showMessage(
          '${AppLocalizations.of(context).text('uploadComplete')}: '
          '${imported.length}',
        );
      }
    } catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isImporting = false);
    }
  }

  Future<void> _openFile(CropAttachment file) async {
    try {
      await _documentService.open(file);
    } catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    }
  }

  Future<void> _deleteFile(CropAttachment file) async {
    final strings = AppLocalizations.of(context);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        content: Text(strings.text('confirmDeleteFile')),
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
    if (confirmed != true) return;
    try {
      await _documentService.delete(file);
      await _load();
      if (mounted) _showMessage(strings.text('fileDeleted'));
    } catch (error) {
      if (mounted) _showMessage(error.toString(), isError: true);
    }
  }

  IconData _fileIcon(String extension) {
    if (const {'jpg', 'jpeg', 'png', 'webp'}.contains(extension)) {
      return Icons.image_outlined;
    }
    if (extension == 'pdf') return Icons.picture_as_pdf_outlined;
    return Icons.description_outlined;
  }

  String _formatSize(int size) {
    if (size < 1024) return '$size B';
    if (size < 1024 * 1024) return '${(size / 1024).toStringAsFixed(1)} KB';
    return '${(size / (1024 * 1024)).toStringAsFixed(1)} MB';
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
