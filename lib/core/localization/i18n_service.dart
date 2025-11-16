/// I18n Service - FASE 5.4: Accesibilidad
///
/// Provides internationalization and localization support:
/// 1. Multi-language support (Spanish, English, Quechua)
/// 2. Translation management
/// 3. Locale switching
/// 4. RTL support for future languages

import 'package:flutter/material.dart';

/// Internationalization service for multi-language support
class I18nService {
  static final I18nService _instance = I18nService._internal();

  final Map<String, Map<String, String>> _translations = {
    'es': _spanishTranslations(),
    'en': _englishTranslations(),
    'qu': _quechuaTranslations(), // Quechua for indigenous communities
  };

  Locale _currentLocale = const Locale('es'); // Default to Spanish
  final List<Locale> supportedLocales = const [
    Locale('es'), // Spanish
    Locale('en'), // English
    Locale('qu'), // Quechua
  ];

  I18nService._internal();

  factory I18nService() {
    return _instance;
  }

  /// Get current locale
  Locale get currentLocale => _currentLocale;

  /// Get current language code
  String get languageCode => _currentLocale.languageCode;

  /// Set locale
  Future<void> setLocale(Locale locale) async {
    if (supportedLocales.contains(locale)) {
      _currentLocale = locale;
      // TODO: Persist locale preference to SharedPreferences
    } else {
      print('⚠️  Locale not supported: $locale');
    }
  }

  /// Get translated string
  String translate(String key) {
    final translations = _translations[languageCode] ?? _translations['en']!;
    return translations[key] ?? key;
  }

  /// Get translated string with parameters
  String translateWithParams(String key, Map<String, String> params) {
    var translation = translate(key);

    params.forEach((paramKey, paramValue) {
      translation = translation.replaceAll('{$paramKey}', paramValue);
    });

    return translation;
  }

  /// Get all translations for current language
  Map<String, String> getAllTranslations() {
    return _translations[languageCode] ?? _translations['en']!;
  }

  /// Check if language supports RTL
  bool isRTL() {
    // Add RTL languages here as needed
    return false; // Spanish, English, Quechua are LTR
  }

  /// Print available translations
  void printAvailableLanguages() {
    print('\n🌐 Available Languages');
    print('═════════════════════════════════════');
    for (final locale in supportedLocales) {
      print('  ${locale.languageCode}: ${_getLanguageName(locale)}');
    }
    print('═════════════════════════════════════\n');
  }

  String _getLanguageName(Locale locale) {
    const names = {
      'es': 'Español',
      'en': 'English',
      'qu': 'Quechua',
    };
    return names[locale.languageCode] ?? locale.languageCode;
  }
}

// ═══════════════════════════════════════════════════════════
// TRANSLATION DICTIONARIES
// ═══════════════════════════════════════════════════════════

/// Spanish translations
Map<String, String> _spanishTranslations() {
  return {
    // Navigation
    'nav.home': 'Inicio',
    'nav.documents': 'Documentos',
    'nav.assignments': 'Asignaciones',
    'nav.settings': 'Configuración',
    'nav.logout': 'Cerrar sesión',

    // Authentication
    'auth.login': 'Iniciar sesión',
    'auth.username': 'Usuario',
    'auth.password': 'Contraseña',
    'auth.email': 'Correo electrónico',
    'auth.loginFailed': 'Error al iniciar sesión',
    'auth.invalidCredentials': 'Usuario o contraseña inválidos',
    'auth.sessionExpired': 'Tu sesión ha expirado',
    'auth.logout': 'Sesión cerrada correctamente',

    // Documents
    'doc.title': 'Documentos',
    'doc.upload': 'Subir documento',
    'doc.delete': 'Eliminar',
    'doc.view': 'Ver',
    'doc.edit': 'Editar',
    'doc.status': 'Estado',
    'doc.uploadDate': 'Fecha de carga',
    'doc.fileSize': 'Tamaño de archivo',
    'doc.noDocuments': 'No hay documentos',
    'doc.uploadSuccess': 'Documento subido exitosamente',
    'doc.uploadFailed': 'Error al subir documento',
    'doc.deleteConfirm': '¿Estás seguro de que deseas eliminar este documento?',
    'doc.deleteSuccess': 'Documento eliminado correctamente',

    // Assignments
    'assign.title': 'Asignaciones',
    'assign.pending': 'Pendiente',
    'assign.inProgress': 'En progreso',
    'assign.completed': 'Completado',
    'assign.rejected': 'Rechazado',
    'assign.noAssignments': 'No hay asignaciones',
    'assign.acceptAssignment': 'Aceptar asignación',
    'assign.completeAssignment': 'Completar asignación',
    'assign.rejectAssignment': 'Rechazar asignación',
    'assign.assignmentDetails': 'Detalles de asignación',

    // Persons/Census
    'person.firstName': 'Nombre',
    'person.lastName': 'Apellido',
    'person.dateOfBirth': 'Fecha de nacimiento',
    'person.nationality': 'Nacionalidad',
    'person.noCensusData': 'No hay datos de censo',
    'person.searchPersons': 'Buscar personas',

    // Settings
    'settings.language': 'Idioma',
    'settings.theme': 'Tema',
    'settings.notifications': 'Notificaciones',
    'settings.about': 'Acerca de',
    'settings.version': 'Versión',
    'settings.privacyPolicy': 'Política de privacidad',
    'settings.termsOfService': 'Términos de servicio',

    // Errors
    'error.title': 'Error',
    'error.networkError': 'Error de conexión de red',
    'error.serverError': 'Error del servidor',
    'error.unknownError': 'Error desconocido',
    'error.tryAgain': 'Intentar de nuevo',
    'error.close': 'Cerrar',

    // Buttons
    'btn.ok': 'Aceptar',
    'btn.cancel': 'Cancelar',
    'btn.save': 'Guardar',
    'btn.delete': 'Eliminar',
    'btn.edit': 'Editar',
    'btn.back': 'Atrás',
    'btn.next': 'Siguiente',
    'btn.submit': 'Enviar',

    // Accessibility
    'a11y.selectLanguage': 'Seleccionar idioma',
    'a11y.increaseTextSize': 'Aumentar tamaño de texto',
    'a11y.decreaseTextSize': 'Disminuir tamaño de texto',
    'a11y.enableHighContrast': 'Activar alto contraste',
    'a11y.screenReaderEnabled': 'Lector de pantalla habilitado',

    // Messages
    'msg.loadingData': 'Cargando datos...',
    'msg.savingChanges': 'Guardando cambios...',
    'msg.deleting': 'Eliminando...',
    'msg.success': 'Operación exitosa',
    'msg.warning': 'Advertencia',
    'msg.info': 'Información',
  };
}

/// English translations
Map<String, String> _englishTranslations() {
  return {
    // Navigation
    'nav.home': 'Home',
    'nav.documents': 'Documents',
    'nav.assignments': 'Assignments',
    'nav.settings': 'Settings',
    'nav.logout': 'Logout',

    // Authentication
    'auth.login': 'Sign In',
    'auth.username': 'Username',
    'auth.password': 'Password',
    'auth.email': 'Email',
    'auth.loginFailed': 'Login failed',
    'auth.invalidCredentials': 'Invalid username or password',
    'auth.sessionExpired': 'Your session has expired',
    'auth.logout': 'Successfully logged out',

    // Documents
    'doc.title': 'Documents',
    'doc.upload': 'Upload Document',
    'doc.delete': 'Delete',
    'doc.view': 'View',
    'doc.edit': 'Edit',
    'doc.status': 'Status',
    'doc.uploadDate': 'Upload Date',
    'doc.fileSize': 'File Size',
    'doc.noDocuments': 'No documents',
    'doc.uploadSuccess': 'Document uploaded successfully',
    'doc.uploadFailed': 'Failed to upload document',
    'doc.deleteConfirm': 'Are you sure you want to delete this document?',
    'doc.deleteSuccess': 'Document deleted successfully',

    // Assignments
    'assign.title': 'Assignments',
    'assign.pending': 'Pending',
    'assign.inProgress': 'In Progress',
    'assign.completed': 'Completed',
    'assign.rejected': 'Rejected',
    'assign.noAssignments': 'No assignments',
    'assign.acceptAssignment': 'Accept Assignment',
    'assign.completeAssignment': 'Complete Assignment',
    'assign.rejectAssignment': 'Reject Assignment',
    'assign.assignmentDetails': 'Assignment Details',

    // Persons/Census
    'person.firstName': 'First Name',
    'person.lastName': 'Last Name',
    'person.dateOfBirth': 'Date of Birth',
    'person.nationality': 'Nationality',
    'person.noCensusData': 'No census data',
    'person.searchPersons': 'Search People',

    // Settings
    'settings.language': 'Language',
    'settings.theme': 'Theme',
    'settings.notifications': 'Notifications',
    'settings.about': 'About',
    'settings.version': 'Version',
    'settings.privacyPolicy': 'Privacy Policy',
    'settings.termsOfService': 'Terms of Service',

    // Errors
    'error.title': 'Error',
    'error.networkError': 'Network connection error',
    'error.serverError': 'Server error',
    'error.unknownError': 'Unknown error',
    'error.tryAgain': 'Try Again',
    'error.close': 'Close',

    // Buttons
    'btn.ok': 'OK',
    'btn.cancel': 'Cancel',
    'btn.save': 'Save',
    'btn.delete': 'Delete',
    'btn.edit': 'Edit',
    'btn.back': 'Back',
    'btn.next': 'Next',
    'btn.submit': 'Submit',

    // Accessibility
    'a11y.selectLanguage': 'Select Language',
    'a11y.increaseTextSize': 'Increase Text Size',
    'a11y.decreaseTextSize': 'Decrease Text Size',
    'a11y.enableHighContrast': 'Enable High Contrast',
    'a11y.screenReaderEnabled': 'Screen Reader Enabled',

    // Messages
    'msg.loadingData': 'Loading data...',
    'msg.savingChanges': 'Saving changes...',
    'msg.deleting': 'Deleting...',
    'msg.success': 'Operation successful',
    'msg.warning': 'Warning',
    'msg.info': 'Information',
  };
}

/// Quechua translations (for indigenous communities)
Map<String, String> _quechuaTranslations() {
  return {
    // Navigation
    'nav.home': 'Uchuy',
    'nav.documents': 'Llaqui',
    'nav.assignments': 'Allinta',
    'nav.settings': 'Llaqtap rurusqa',
    'nav.logout': 'Lluqsiy',

    // Authentication
    'auth.login': 'Kawsay',
    'auth.username': 'Sutiyoc',
    'auth.password': 'Yaparisqa',
    'auth.email': 'Correo',
    'auth.loginFailed': 'Kawsay mana allinchu',
    'auth.invalidCredentials': 'Mana allinchu sutiyoc o yaparisqa',
    'auth.sessionExpired': 'Kawsay tiyay hina kachka',
    'auth.logout': 'Lluqsisqaku allinllachu',

    // Documents
    'doc.title': 'Llaqui',
    'doc.upload': 'Llaqui suyuy',
    'doc.delete': 'Chinkichiy',
    'doc.view': 'Rikuy',
    'doc.edit': 'Akllay',
    'doc.status': 'Kunallachu',
    'doc.uploadDate': 'Suyuy punchaw',
    'doc.fileSize': 'Llaqui llakin',
    'doc.noDocuments': 'Mana llaquichu',
    'doc.uploadSuccess': 'Llaqui suya allinchu',
    'doc.uploadFailed': 'Llaqui suya mana allinchu',
    'doc.deleteConfirm': '¿Llaqui chinkichisunki?',
    'doc.deleteSuccess': 'Llaqui chinkisqaku allinchu',

    // Buttons
    'btn.ok': 'Allinchu',
    'btn.cancel': 'Llaquiy',
    'btn.save': 'Qawachiy',
    'btn.delete': 'Chinkichiy',
    'btn.back': 'Napay',
    'btn.submit': 'Apachiy',

    // Messages
    'msg.loadingData': 'Llaqui maskay...',
    'msg.savingChanges': 'Qawachiy...',
    'msg.success': 'Allinchu',
  };
}

/// Extension to use translations in widgets
extension TranslationExtension on BuildContext {
  String t(String key) => I18nService().translate(key);

  String tWithParams(String key, Map<String, String> params) =>
      I18nService().translateWithParams(key, params);
}
