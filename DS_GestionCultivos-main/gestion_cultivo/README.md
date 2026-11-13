# Gestión de Cultivos

Aplicación Flutter offline para registrar cultivos, guardar archivos asociados,
extraer texto de PDF y DOCX, y exportar los datos. Los registros y archivos se
guardan localmente en Android y Windows; en la Web se guardan en el almacenamiento
del navegador (IndexedDB). El análisis de imágenes no está activo: se habilitará
cuando exista un modelo de diagnóstico validado.

## Requisitos

- Flutter 3.35 o posterior y Dart 3.9 o posterior.
- Android: Android Studio con JDK 17 o 21. El JDK 25 incluido en algunas
  instalaciones de Android Studio no es compatible con la versión actual de
  Gradle/Kotlin del proyecto.
- Windows: habilita el Modo de desarrollador para que Flutter pueda crear
  enlaces simbólicos al compilar plugins.
- Web: Chrome, Edge u otro navegador moderno. La base local usa SQLite
  compilado a WebAssembly.

## Ejecutar

Desde esta carpeta:

```powershell
flutter pub get
flutter run -d windows
```

Para Android, inicia un emulador o conecta un dispositivo con depuración USB y
ejecuta:

```powershell
flutter run -d android
```

Para la Web, prepara los archivos de SQLite WebAssembly una vez y ejecuta la
aplicación en un puerto fijo para conservar los datos entre ejecuciones:

```powershell
dart run sqflite_common_ffi_web:setup
flutter run -d chrome --web-port 8080
```

Los datos web son privados de ese navegador y origen (incluido el puerto). Si se
borran los datos del sitio en el navegador, también se borran los registros y
archivos almacenados allí.

En Windows, las compilaciones de distribución deben incluir `sqlite3.dll` junto
al ejecutable de la aplicación.

## Funciones

- **Datos:** crear, buscar, editar y eliminar registros de cultivos.
- **Archivos:** guardar imágenes, PDF y DOCX en el dispositivo; vincularlos a
  cultivos; abrirlos, buscarlos y eliminarlos. Se intenta extraer texto de PDF y
  DOCX compatibles. Los PDF escaneados pueden no contener texto extraíble.
- **Ajustes:** conservar el tema y el idioma seleccionado; exportar en CSV,
  XLSX, PDF, DOCX o JSON.
- **Análisis:** permanece desactivado hasta integrar un modelo validado; no se
  muestran diagnósticos ni predicciones simuladas.
