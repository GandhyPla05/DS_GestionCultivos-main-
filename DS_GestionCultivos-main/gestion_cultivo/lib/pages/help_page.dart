import 'package:flutter/material.dart';

import '../l10n/app_localizations.dart';

class HelpPage extends StatefulWidget {
  const HelpPage({super.key});

  @override
  State<HelpPage> createState() => _HelpPageState();
}

class _HelpPageState extends State<HelpPage> {
  static const _categories = [
    'all',
    'home',
    'data',
    'files',
    'settings',
    'troubleshooting',
  ];

  static const _topics = [
    _HelpTopic(
      categoryKey: 'home',
      questionKey: 'helpDescription',
      question: '¿Cómo me muevo por la aplicación?',
      answer:
          'Abre el menú con el botón de tres líneas en la parte superior. '
          'Desde allí puedes ir a Inicio, Datos, Archivos, Ajustes o Ayuda. '
          'En Inicio, las tarjetas de Datos y Archivos también son accesos rápidos.',
      answerKeys: ['home', 'data', 'files', 'settings', 'help'],
    ),
    _HelpTopic(
      categoryKey: 'home',
      questionKey: 'home',
      question: '¿Cómo vuelvo a la pantalla de inicio?',
      answer:
          'Abre el menú lateral y selecciona Inicio. El título de la barra '
          'superior muestra la sección en la que estás.',
      answerKeys: ['home', 'helpDescription'],
    ),
    _HelpTopic(
      categoryKey: 'data',
      questionKey: 'data',
      question: '¿Qué puedo hacer en Datos?',
      answer:
          'Registra, busca, edita y elimina cultivos. Cada registro puede incluir '
          'variedad, parcela, fechas, riego, fertilización, plagas y notas. '
          'El análisis de imágenes permanece desactivado hasta integrar un '
          'modelo validado.',
      answerKeys: [
        'dataSummary',
        'crop',
        'variety',
        'parcel',
        'sowingDate',
        'irrigation',
        'fertilization',
        'pests',
        'harvestDate',
        'notes',
        'modelRequired',
      ],
    ),
    _HelpTopic(
      categoryKey: 'files',
      questionKey: 'files',
      question: '¿Puedo subir o administrar archivos?',
      answer:
          'Agrega imágenes, PDF y DOCX, y vincúlalos opcionalmente a un cultivo. '
          'Los archivos se guardan en este dispositivo; el texto de PDF y DOCX '
          'se extrae cuando el documento lo permite.',
      answerKeys: [
        'supportedFiles',
        'localStorage',
        'extractedText',
        'noExtractedText',
      ],
    ),
    _HelpTopic(
      categoryKey: 'settings',
      questionKey: 'darkMode',
      question: '¿Cómo activo el modo oscuro?',
      answer:
          'Ve a Ajustes y activa Modo oscuro. La selección del tema se guarda '
          'en este dispositivo y se conserva al volver a abrir la aplicación.',
      answerKeys: ['darkMode', 'localStorage'],
    ),
    _HelpTopic(
      categoryKey: 'settings',
      questionKey: 'settings',
      question: '¿Los otros ajustes ya están funcionando?',
      answer:
          'El idioma cambia los textos de la interfaz y la selección se conserva '
          'en este dispositivo. También puedes cambiar el tema y exportar los '
          'datos como CSV, XLSX, PDF, DOCX o JSON.',
      answerKeys: [
        'language',
        'chooseLanguage',
        'darkMode',
        'exportData',
        'exportFormat',
        'localStorage',
      ],
    ),
    _HelpTopic(
      categoryKey: 'troubleshooting',
      questionKey: 'helpTitle',
      question: '¿Qué hago si Windows muestra un error de enlaces simbólicos?',
      answer:
          'Flutter necesita permiso para crear enlaces simbólicos al compilar '
          'plugins. En Windows, activa el Modo de desarrollador en Configuración '
          '→ Sistema → Para desarrolladores y vuelve a ejecutar la aplicación.',
      answerKeys: ['helpWindows'],
    ),
    _HelpTopic(
      categoryKey: 'troubleshooting',
      questionKey: 'helpDescription',
      question:
          '¿Qué hago si no aparecen cambios después de modificar el código?',
      answer:
          'Guarda los archivos y vuelve a ejecutar la app. Si el problema '
          'continúa, detén la ejecución y arráncala de nuevo desde la carpeta '
          'gestion_cultivo del proyecto.',
      answerKeys: ['helpRestart'],
    ),
  ];

  final TextEditingController _searchController = TextEditingController();
  String _selectedCategory = 'all';
  String _searchQuery = '';
  bool? _wasHelpful;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<_HelpTopic> _filteredTopics(AppLocalizations strings) {
    final query = _searchQuery.trim().toLowerCase();
    return _topics.where((topic) {
      final matchesCategory =
          _selectedCategory == 'all' ||
          topic.categoryKey == _selectedCategory;
      final question = topic.localizedQuestion(strings);
      final answer = topic.localizedAnswer(strings);
      final matchesQuery =
          query.isEmpty ||
          question.toLowerCase().contains(query) ||
          answer.toLowerCase().contains(query) ||
          strings.text(topic.categoryKey).toLowerCase().contains(query);
      return matchesCategory && matchesQuery;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final strings = _strings(context);
    final topics = _filteredTopics(strings);

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildWelcomeCard(context),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              labelText: strings.text('helpSearch'),
              hintText: strings.text('helpSearchHint'),
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: strings.text('close'),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                      icon: const Icon(Icons.clear),
                    ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
          const SizedBox(height: 20),
          Text(
            strings.text('helpExplore'),
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: _categories.map((category) {
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(strings.text(category)),
                    selected: _selectedCategory == category,
                    onSelected: (_) => setState(
                      () => _selectedCategory =
                          category == 'all' ? 'all' : category,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            strings.text('helpQuestions'),
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          if (topics.isEmpty)
            _buildEmptySearch(context)
          else
            ...topics.map((topic) => _buildQuestion(context, topic)),
          const SizedBox(height: 16),
          _buildFeedbackCard(context),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final strings = _strings(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          colors: [colors.primary, colors.primary.withValues(alpha: 0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.support_agent, size: 38, color: Colors.white),
          const SizedBox(height: 12),
          Text(
            strings.text('helpTitle'),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            strings.text('helpDescription'),
            style: const TextStyle(color: Colors.white, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(BuildContext context, _HelpTopic topic) {
    final strings = _strings(context);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        leading: Icon(
          topic.categoryKey == 'troubleshooting'
              ? Icons.build_outlined
              : Icons.help_outline,
          color: Theme.of(context).colorScheme.primary,
        ),
        title: Text(
          topic.localizedQuestion(strings),
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(strings.text(topic.categoryKey)),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        expandedCrossAxisAlignment: CrossAxisAlignment.start,
        children: [Text(topic.localizedAnswer(strings))],
      ),
    );
  }

  Widget _buildEmptySearch(BuildContext context) {
    final strings = _strings(context);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Icon(
              Icons.search_off,
              size: 36,
              color: Theme.of(context).colorScheme.secondary,
            ),
            const SizedBox(height: 8),
            Text(
              strings.text('noResults'),
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              strings.text('helpExplore'),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(BuildContext context) {
    final theme = Theme.of(context);
    final strings = _strings(context);
    return Card(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              strings.text('helpFeedback'),
              style: TextStyle(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            if (_wasHelpful == null)
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: () => _sendFeedback(true),
                    icon: const Icon(Icons.thumb_up_outlined),
                    label: Text(strings.text('helpYes')),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _sendFeedback(false),
                    icon: const Icon(Icons.thumb_down_outlined),
                    label: Text(strings.text('helpNo')),
                  ),
                ],
              )
            else
              Text(
                strings.text(_wasHelpful! ? 'helpThanks' : 'helpImprove'),
                textAlign: TextAlign.center,
              ),
          ],
        ),
      ),
    );
  }

  void _sendFeedback(bool wasHelpful) {
    setState(() => _wasHelpful = wasHelpful);
  }

  AppLocalizations _strings(BuildContext context) =>
      AppLocalizations.maybeOf(context) ??
      const AppLocalizations(Locale('es'));
}

class _HelpTopic {
  const _HelpTopic({
    required this.categoryKey,
    required this.questionKey,
    required this.question,
    required this.answer,
    required this.answerKeys,
  });

  final String categoryKey;
  final String questionKey;
  final String question;
  final String answer;
  final List<String> answerKeys;

  String localizedQuestion(AppLocalizations strings) =>
      strings.locale.languageCode == 'es'
      ? question
      : strings.text(questionKey);

  String localizedAnswer(AppLocalizations strings) =>
      strings.locale.languageCode == 'es'
      ? answer
      : answerKeys.map(strings.text).join(' · ');
}
