// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Chinese (`zh`).
class AppLocalizationsZh extends AppLocalizations {
  AppLocalizationsZh([String locale = 'zh']) : super(locale);

  @override
  String get appTitle => '实时语音识别 (MVVM)';

  @override
  String get downloading => '下载中:';

  @override
  String get unzipping => '解压中...';

  @override
  String get transcriptionPlaceholder => '转录内容将显示在这里...';

  @override
  String get recording => '录音中...';

  @override
  String get idle => '空闲';

  @override
  String get downloadModel => '下载模型';
}
