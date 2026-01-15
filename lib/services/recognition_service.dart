import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:sherpa_onnx/sherpa_onnx.dart' as sherpa_onnx;

class RecognitionService {
  sherpa_onnx.OnlineRecognizer? _recognizer;
  sherpa_onnx.OnlineStream? _stream;
  final AudioRecorder _audioRecorder = AudioRecorder();
  StreamSubscription<RecordState>? _recordSub;

  final ValueNotifier<String> recognizedText = ValueNotifier('');
  final ValueNotifier<RecordState> recordState =
      ValueNotifier(RecordState.stop);

  bool _isInitialized = false;
  String _lastText = '';
  int _sentenceIndex = 0;
  final int _sampleRate = 16000;

  Future<void> initialize(String modelName) async {
    if (_isInitialized) return;

    sherpa_onnx.initBindings();
    _recognizer = await _createOnlineRecognizer(modelName);
    _stream = _recognizer?.createStream();

    _recordSub = _audioRecorder.onStateChanged().listen((state) {
      recordState.value = state;
    });

    _isInitialized = true;
  }

  Future<sherpa_onnx.OnlineRecognizer> _createOnlineRecognizer(
      String modelName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final modulePath = join(directory.path, modelName);
    final modelDir = modulePath;

    // Using the logic specific to the default model for now, can be expanded
    final config = sherpa_onnx.OnlineRecognizerConfig(
      model: sherpa_onnx.OnlineModelConfig(
        transducer: sherpa_onnx.OnlineTransducerModelConfig(
          encoder: '$modelDir/encoder-epoch-99-avg-1.int8.onnx',
          decoder: '$modelDir/decoder-epoch-99-avg-1.onnx',
          joiner: '$modelDir/joiner-epoch-99-avg-1.onnx',
        ),
        tokens: '$modelDir/tokens.txt',
        modelType: 'zipformer',
      ),
      ruleFsts: '',
    );

    return sherpa_onnx.OnlineRecognizer(config);
  }

  Future<void> startRecording() async {
    if (!_isInitialized) {
      throw Exception("RecognitionService not initialized");
    }

    if (await _audioRecorder.hasPermission()) {
      const encoder = AudioEncoder.pcm16bits;
      // Check encoder support if needed (simplified here)

      final stream = await _audioRecorder.startStream(const RecordConfig(
        encoder: encoder,
        sampleRate: 16000,
        numChannels: 1,
      ));

      stream.listen(
        (data) {
          final samplesFloat32 =
              _convertBytesToFloat32(Uint8List.fromList(data));
          _stream!
              .acceptWaveform(samples: samplesFloat32, sampleRate: _sampleRate);

          while (_recognizer!.isReady(_stream!)) {
            _recognizer!.decode(_stream!);
          }

          final text = _recognizer!.getResult(_stream!).text;
          _updateText(text);

          if (_recognizer!.isEndpoint(_stream!)) {
            _recognizer!.reset(_stream!);
            if (text.isNotEmpty) {
              _updateText(text + ",");
              _lastText = recognizedText.value;
              // Do not increment sentence index to continue on same line
              // _sentenceIndex++;
            }
          }
        },
        onDone: () {
          debugPrint('Stream stopped');
        },
      );
    }
  }

  void _updateText(String currentText) {
    String textToDisplay = _lastText;
    if (currentText.isNotEmpty) {
      if (_lastText.isEmpty) {
        textToDisplay = '$_sentenceIndex: $currentText';
      } else {
        // If the last text ends with a comma, we assume it's a continuation
        // of the same "sentence" (or just stream of thought).
        if (_lastText.trimRight().endsWith(',')) {
          textToDisplay = '$_lastText $currentText';
        } else {
          textToDisplay = '$_lastText\n$_sentenceIndex: $currentText';
        }
      }
    }
    recognizedText.value = textToDisplay;
  }

  Future<void> stopRecording() async {
    await _audioRecorder.stop();
    _stream?.free();
    _stream = _recognizer?.createStream(); // Ready for next
  }

  Float32List _convertBytesToFloat32(Uint8List bytes,
      [endian = Endian.little]) {
    final values = Float32List(bytes.length ~/ 2);
    final data = ByteData.view(bytes.buffer);
    for (var i = 0; i < bytes.length; i += 2) {
      int short = data.getInt16(i, endian);
      values[i ~/ 2] = short / 32678.0;
    }
    return values;
  }

  void dispose() {
    _recordSub?.cancel();
    _audioRecorder.dispose();
    _stream?.free();
    _recognizer?.free();
    recognizedText.dispose();
    recordState.dispose();
  }
}
