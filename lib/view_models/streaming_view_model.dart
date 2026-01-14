import 'package:flutter/foundation.dart';
import 'package:record/record.dart';
import '../services/recognition_service.dart';
import '../services/model_manager_service.dart';

class StreamingViewModel {
  final RecognitionService _recognitionService;
  final ModelManagerService _modelManagerService;

  // State exposed to View
  ValueNotifier<String> get recognizedText =>
      _recognitionService.recognizedText;
  ValueNotifier<RecordState> get recordState => _recognitionService.recordState;

  // Model management state
  ValueNotifier<double> get downloadProgress =>
      _modelManagerService.downloadProgress;
  ValueNotifier<double> get unzipProgress => _modelManagerService.unzipProgress;
  ValueNotifier<String?> get error => _modelManagerService.error;

  final ValueNotifier<bool> isBusy = ValueNotifier(false);
  final ValueNotifier<bool> needsDownloadOrUnzip = ValueNotifier(false);

  final String _modelName =
      "sherpa-onnx-streaming-zipformer-bilingual-zh-en-2023-02-20";

  StreamingViewModel({
    required RecognitionService recognitionService,
    required ModelManagerService modelManagerService,
  })  : _recognitionService = recognitionService,
        _modelManagerService = modelManagerService;

  Future<void> init() async {
    await _checkModelStatus();
  }

  Future<void> _checkModelStatus() async {
    final download = await _modelManagerService.needsDownload(_modelName);
    final unzip = await _modelManagerService.needsUnZip(_modelName);
    needsDownloadOrUnzip.value = download || unzip;

    if (!needsDownloadOrUnzip.value) {
      // Initialize recognition if model is ready
      try {
        await _recognitionService.initialize(_modelName);
      } catch (e) {
        error.value = "Failed to initialize recognition: $e";
      }
    }
  }

  Future<void> downloadAndSetupModel() async {
    isBusy.value = true;
    try {
      if (await _modelManagerService.needsDownload(_modelName)) {
        await _modelManagerService.downloadModel(_modelName);
      }
      if (await _modelManagerService.needsUnZip(_modelName)) {
        await _modelManagerService.unzipModel(_modelName);
      }

      // Re-check status and initialize
      await _checkModelStatus();
    } catch (e) {
      error.value = e.toString();
    } finally {
      isBusy.value = false;
    }
  }

  void toggleRecording() {
    if (recordState.value == RecordState.stop) {
      _recognitionService.startRecording();
    } else {
      _recognitionService.stopRecording();
    }
  }
}
