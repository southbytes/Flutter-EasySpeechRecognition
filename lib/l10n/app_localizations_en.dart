// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appTitle => 'Real-time Speech Recognition (MVVM)';

  @override
  String get downloading => 'Downloading:';

  @override
  String get unzipping => 'Unzipping...';

  @override
  String get transcriptionPlaceholder => 'Transcription will appear here...';

  @override
  String get recording => 'Recording...';

  @override
  String get idle => 'Idle';

  @override
  String get downloadModel => 'Download Model';
}
