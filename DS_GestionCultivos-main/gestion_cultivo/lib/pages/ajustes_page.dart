import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';
import '../main.dart';
import '../services/export_service.dart';

class AjustesPage extends StatefulWidget {
  const AjustesPage({super.key});

  @override
  State<AjustesPage> createState() => _AjustesPageState();
}

class _AjustesPageState extends State<AjustesPage> {
  ExportFormat? _selectedExportFormat;
  bool _isExporting = false;

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final language = AppLocalizations.languages.firstWhere(
      (option) =>
          option.locale.languageCode == appLocaleNotifier.value.languageCode,
    );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _section(strings.text('appearance')),
        Card(
          child: Column(
            children: [
              ValueListenableBuilder<bool>(
                valueListenable: isDarkModeNotifier,
                builder: (context, isDarkMode, child) => SwitchListTile(
                  secondary: Icon(
                    isDarkMode ? Icons.dark_mode : Icons.light_mode,
                  ),
                  title: Text(strings.text('darkMode')),
                  value: isDarkMode,
                  onChanged: _toggleDarkMode,
                ),
              ),
              const Divider(height: 1),
              ListTile(
                leading: const Icon(Icons.language),
                title: Text(strings.text('language')),
                subtitle: Text(language.name),
                trailing: const Icon(Icons.chevron_right),
                onTap: _showLanguageDialog,
              ),
            ],
          ),
        ),
        _section(strings.text('exportData')),
        Card(
          child: ListTile(
            leading: const Icon(Icons.file_download_outlined),
            title: Text(strings.text('exportData')),
            subtitle: Text(strings.text('exportFormat')),
            trailing: _isExporting
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.chevron_right),
            onTap: _isExporting ? null : _showExportDialog,
          ),
        ),
        _section(strings.text('helpTitle')),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Text(strings.text('localStorage')),
          ),
        ),
        Card(
          child: ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text(strings.text('appTitle')),
            subtitle: Text(strings.text('version')),
          ),
        ),
      ],
    );
  }

  Widget _section(String title) => Padding(
    padding: const EdgeInsets.fromLTRB(4, 18, 4, 8),
    child: Text(
      title,
      style: TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).colorScheme.primary,
      ),
    ),
  );

  Future<void> _toggleDarkMode(bool value) async {
    try {
      if (value != isDarkModeNotifier.value) await toggleDarkMode();
    } catch (error) {
      if (mounted) _showMessage('$error', isError: true);
    }
  }

  Future<void> _showLanguageDialog() async {
    final strings = AppLocalizations.of(context);
    final languages = AppLocalizations.languages.toList()
      ..sort(
        (first, second) => first.englishName.compareTo(second.englishName),
      );
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(strings.text('chooseLanguage')),
        content: SizedBox(
          width: 360,
          child: ListView.builder(
            shrinkWrap: true,
            itemCount: languages.length,
            itemBuilder: (context, index) {
              final language = languages[index];
              final selected =
                  language.locale.languageCode ==
                  appLocaleNotifier.value.languageCode;
              return ListTile(
                title: Text(language.name),
                trailing: selected
                    ? Icon(
                        Icons.check,
                        color: Theme.of(context).colorScheme.primary,
                      )
                    : null,
                selected: selected,
                onTap: () async {
                  try {
                    await saveAppLocale(language.locale);
                    if (dialogContext.mounted) Navigator.pop(dialogContext);
                  } catch (error) {
                    if (dialogContext.mounted) {
                      _showMessage('$error', isError: true);
                    }
                  }
                },
              );
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text(strings.text('close')),
          ),
        ],
      ),
    );
  }

  Future<void> _showExportDialog() async {
    final strings = AppLocalizations.of(context);
    _selectedExportFormat = ExportFormat.csv;
    final formatNames = <ExportFormat, String>{
      ExportFormat.csv: 'CSV',
      ExportFormat.xlsx: 'Excel (.xlsx)',
      ExportFormat.pdf: 'PDF',
      ExportFormat.docx: 'Word (.docx)',
      ExportFormat.json: 'JSON',
    };
    final format = await showDialog<ExportFormat>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(strings.text('exportData')),
          content: DropdownButtonFormField<ExportFormat>(
            initialValue: _selectedExportFormat,
            decoration: InputDecoration(
              labelText: strings.text('exportFormat'),
            ),
            items: formatNames.entries
                .map(
                  (entry) => DropdownMenuItem(
                    value: entry.key,
                    child: Text(entry.value),
                  ),
                )
                .toList(),
            onChanged: (value) =>
                setDialogState(() => _selectedExportFormat = value),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: Text(strings.text('cancel')),
            ),
            FilledButton(
              onPressed: _selectedExportFormat == null
                  ? null
                  : () => Navigator.pop(dialogContext, _selectedExportFormat),
              child: Text(strings.text('exportData')),
            ),
          ],
        ),
      ),
    );
    if (format == null) return;
    await _export(format);
  }

  Future<void> _export(ExportFormat format) async {
    final strings = AppLocalizations.of(context);
    setState(() => _isExporting = true);
    try {
      final path = await const ExportService().exportAll(format);
      if (!mounted) return;
      if (path == null) {
        _showMessage(strings.text('exportCancelled'));
      } else {
        _showMessage('${strings.text('exportComplete')}: $path');
      }
    } catch (error) {
      if (mounted) _showMessage('$error', isError: true);
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  void _showMessage(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Theme.of(context).colorScheme.error : null,
      ),
    );
  }
}
