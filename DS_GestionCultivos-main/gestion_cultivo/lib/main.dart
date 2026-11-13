import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'l10n/app_localizations.dart';
import 'pages/datos_page.dart';
import 'pages/archivos_page.dart';
import 'pages/ajustes_page.dart';
import 'pages/help_page.dart';
import 'services/local_database.dart';

// Notificador global para el tema
final ValueNotifier<bool> isDarkModeNotifier = ValueNotifier<bool>(false);
final ValueNotifier<Locale> appLocaleNotifier = ValueNotifier<Locale>(
  const Locale('es'),
);

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _loadThemePreference();
  await _loadLocalePreference();
  await LocalDatabase.instance.initialize();
  runApp(const MyApp());
}

Future<void> _loadThemePreference() async {
  final prefs = await SharedPreferences.getInstance();
  isDarkModeNotifier.value = prefs.getBool('isDarkMode') ?? false;
}

Future<void> _loadLocalePreference() async {
  final prefs = await SharedPreferences.getInstance();
  final languageCode = prefs.getString('appLanguage') ?? 'es';
  appLocaleNotifier.value = AppLocalizations.supportedLocales.firstWhere(
    (locale) => locale.languageCode == languageCode,
    orElse: () => const Locale('es'),
  );
}

Future<void> saveAppLocale(Locale locale) async {
  if (!AppLocalizations.supportedLocales.any(
    (supportedLocale) => supportedLocale.languageCode == locale.languageCode,
  )) {
    throw ArgumentError.value(locale, 'locale', 'Unsupported app language');
  }
  final prefs = await SharedPreferences.getInstance();
  await prefs.setString('appLanguage', locale.languageCode);
  appLocaleNotifier.value = locale;
}

Future<void> saveThemePreference(bool isDarkMode) async {
  final prefs = await SharedPreferences.getInstance();
  await prefs.setBool('isDarkMode', isDarkMode);
}

Future<void> toggleDarkMode() async {
  isDarkModeNotifier.value = !isDarkModeNotifier.value;
  await saveThemePreference(isDarkModeNotifier.value);
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    // Escuchar cambios en el tema
    isDarkModeNotifier.addListener(_onThemeChanged);
    appLocaleNotifier.addListener(_onThemeChanged);
  }

  @override
  void dispose() {
    isDarkModeNotifier.removeListener(_onThemeChanged);
    appLocaleNotifier.removeListener(_onThemeChanged);
    super.dispose();
  }

  void _onThemeChanged() {
    setState(() {
      // Rebuild cuando cambie el tema
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      onGenerateTitle: (context) =>
          AppLocalizations.of(context).text('appTitle'),
      debugShowCheckedModeBanner: false,
      locale: appLocaleNotifier.value,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: const [
        AppLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 67, 204, 96),
          brightness: Brightness.light,
        ),
        useMaterial3: true,
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 67, 204, 96),
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      themeMode: isDarkModeNotifier.value ? ThemeMode.dark : ThemeMode.light,
      home: const MyHomePage(),
    );
  }
}

// Homepage
class HomePage extends StatelessWidget {
  final Function(int) onNavigate;

  const HomePage({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header de bienvenida
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  const Color.fromARGB(255, 67, 204, 96),
                  Color.fromARGB(180, 67, 204, 96), // 0.7 opacity = ~180 alpha
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.agriculture, size: 48, color: Colors.white),
                SizedBox(height: 15),
                Text(
                  strings.text('welcome'),
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  strings.text('appSubtitle'),
                  style: TextStyle(fontSize: 16, color: Colors.white),
                ),
              ],
            ),
          ),

          const SizedBox(height: 30),

          // Sección de accesos rápidos
          Text(
            strings.text('quickAccess'),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          // Cards de acceso rápido
          Row(
            children: [
              Expanded(
                child: _buildQuickAccessCard(
                  context: context,
                  icon: Icons.analytics,
                  title: strings.text('data'),
                  subtitle: strings.text('dataSummary'),
                  color: Colors.green,
                  onTap: () =>
                      onNavigate(1), // Navegar a página de Datos (índice 1)
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildQuickAccessCard(
                  context: context,
                  icon: Icons.folder,
                  title: strings.text('files'),
                  subtitle: strings.text('filesSummary'),
                  color: Colors.blue,
                  onTap: () =>
                      onNavigate(2), // Navegar a página de Archivos (índice 2)
                ),
              ),
            ],
          ),

          const SizedBox(height: 30),

          // Sección de información
          Text(
            strings.text('systemInfo'),
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.info_outline,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      strings.text('systemInfo'),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Text(
                  strings.text('systemDescription'),
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAccessCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        hoverColor: color.withValues(alpha: 0.2),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(15),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Column(
            children: [
              Icon(icon, size: 40, color: color),
              const SizedBox(height: 10),
              Text(
                title,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              const SizedBox(height: 5),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key});

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  int _currentPageIndex = 0;

  Widget _getCurrentPage() {
    switch (_currentPageIndex) {
      case 0:
        return HomePage(onNavigate: _onQuickAccessTap);
      case 1:
        return const DatosPage();
      case 2:
        return const ArchivosPage();
      case 3:
        return const AjustesPage();
      case 4:
        return const HelpPage();
      default:
        return HomePage(onNavigate: _onQuickAccessTap);
    }
  }

  void _onPageSelected(int index) {
    setState(() {
      _currentPageIndex = index;
    });
    // Cierra el drawer automáticamente (solo para navegación desde drawer)
    Navigator.of(context).pop();
  }

  void _onQuickAccessTap(int index) {
    setState(() {
      _currentPageIndex = index;
    });
    // No cierra drawer porque no está abierto (para accesos rápidos)
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalizations.of(context);
    final pageTitles = [
      strings.text('home'),
      strings.text('data'),
      strings.text('files'),
      strings.text('settings'),
      strings.text('help'),
    ];
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(
          '${strings.text('appTitle')} - ${pageTitles[_currentPageIndex]}',
        ),
        leading: Builder(
          builder: (context) => IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openDrawer(),
          ),
        ),
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Theme.of(context).colorScheme.primary,
                    Theme.of(
                      context,
                    ).colorScheme.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              margin: EdgeInsets.zero,
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.agriculture, size: 64, color: Colors.white),
                    SizedBox(height: 15),
                    Text(
                      strings.text('appTitle'),
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.home),
              title: Text(strings.text('home')),
              selected: _currentPageIndex == 0,
              onTap: () => _onPageSelected(0),
            ),
            ListTile(
              leading: const Icon(Icons.analytics),
              title: Text(strings.text('data')),
              selected: _currentPageIndex == 1,
              onTap: () => _onPageSelected(1),
            ),
            ListTile(
              leading: const Icon(Icons.folder),
              title: Text(strings.text('files')),
              selected: _currentPageIndex == 2,
              onTap: () => _onPageSelected(2),
            ),
            // Espacio flexible para empujar los elementos de abajo hacia el final
            const Expanded(child: SizedBox()),
            // Divisor visual para separar las opciones principales de las secundarias
            const Divider(thickness: 1),
            ListTile(
              leading: const Icon(Icons.settings),
              title: Text(strings.text('settings')),
              selected: _currentPageIndex == 3,
              onTap: () => _onPageSelected(3),
            ),
            ListTile(
              leading: const Icon(Icons.help),
              title: Text(strings.text('help')),
              selected: _currentPageIndex == 4,
              onTap: () => _onPageSelected(4),
            ),
          ],
        ),
      ),
      body: _getCurrentPage(),
    );
  }
}
