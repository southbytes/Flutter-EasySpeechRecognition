import 'package:flutter/material.dart';

import 'package:record/record.dart';
import '../view_models/streaming_view_model.dart';

class StreamingPage extends StatefulWidget {
  final StreamingViewModel viewModel;

  const StreamingPage({super.key, required this.viewModel});

  @override
  State<StreamingPage> createState() => _StreamingPageState();
}

class _StreamingPageState extends State<StreamingPage> {
  StreamingViewModel get _viewModel => widget.viewModel;
  final TextEditingController _controller = TextEditingController();

  @override
  void initState() {
    super.initState();

    // Initialize ViewModel
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _viewModel.init();
    });

    // Listen to text changes to update controller
    _viewModel.recognizedText.addListener(_onTextChanged);

    // Listen to busy state to show/hide dialog or indicators
    _viewModel.isBusy.addListener(_onBusyChanged);

    // Listen to errors
    _viewModel.error.addListener(_onError);
  }

  @override
  void dispose() {
    _viewModel.recognizedText.removeListener(_onTextChanged);
    _viewModel.isBusy.removeListener(_onBusyChanged);
    _viewModel.error.removeListener(_onError);
    _controller.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    String text = _viewModel.recognizedText.value;
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  void _onBusyChanged() {
    if (_viewModel.isBusy.value) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          // We can reuse the existing DownloadProgressDialog but we need to wire it
          // to the ViewModel's progress notifiers.
          // Since DownloadProgressDialog in the original code might be coupled to Provider<DownloadModel>,
          // we might need to refactor it or create a wrapper.
          // For now, let's assume we can use a custom one or the existing one if we provide the data.
          // However, keeping it simple:
          return ValueListenableBuilder<double>(
              valueListenable: _viewModel.downloadProgress,
              builder: (context, downloadProg, _) {
                return ValueListenableBuilder<double>(
                    valueListenable: _viewModel.unzipProgress,
                    builder: (context, unzipProg, _) {
                      return AlertDialog(
                        content: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (downloadProg < 1.0)
                              Text(
                                  "Downloading: ${(downloadProg * 100).toStringAsFixed(1)}%"),
                            if (downloadProg < 1.0)
                              LinearProgressIndicator(value: downloadProg),
                            if (downloadProg >= 1.0 && unzipProg < 1.0)
                              Text(
                                  "Unzipping... ${(unzipProg * 100).toStringAsFixed(1)}%"),
                            if (downloadProg >= 1.0 && unzipProg < 1.0)
                              LinearProgressIndicator(value: unzipProg),
                          ],
                        ),
                      );
                    });
              });
        },
      );
    } else {
      // Close dialog if open
      if (Navigator.canPop(context)) {
        // This is a bit risky if other dialogs are open, but for this specific flow it's standard
        Navigator.of(context).pop();
      }
    }
  }

  void _onError() {
    if (_viewModel.error.value != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_viewModel.error.value!)),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Real-time Speech Recognition (MVVM)'),
      ),
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 50),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: TextField(
              maxLines: 20,
              controller: _controller,
              readOnly: true,
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                hintText: 'Recognized text will appear here',
              ),
            ),
          ),
          const SizedBox(height: 50),
          ValueListenableBuilder<bool>(
            valueListenable: _viewModel.needsDownloadOrUnzip,
            builder: (context, needsDownload, child) {
              if (needsDownload) {
                return ElevatedButton(
                  onPressed: () {
                    _viewModel.downloadAndSetupModel();
                  },
                  child: const Text("Download Model"),
                );
              }

              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: <Widget>[
                  _buildRecordStopControl(),
                  const SizedBox(width: 20),
                  _buildText(),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildRecordStopControl() {
    return ValueListenableBuilder<RecordState>(
      valueListenable: _viewModel.recordState,
      builder: (context, state, child) {
        late Icon icon;
        late Color color;

        if (state != RecordState.stop) {
          icon = const Icon(Icons.stop, color: Colors.red, size: 30);
          color = Colors.red.withValues(alpha: 0.1);
        } else {
          final theme = Theme.of(context);
          icon = Icon(Icons.mic, color: theme.primaryColor, size: 30);
          color = theme.primaryColor.withValues(alpha: 0.1);
        }

        return ClipOval(
          child: Material(
            color: color,
            child: InkWell(
              child: SizedBox(width: 56, height: 56, child: icon),
              onTap: () {
                _viewModel.toggleRecording();
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildText() {
    return ValueListenableBuilder<RecordState>(
      valueListenable: _viewModel.recordState,
      builder: (context, state, child) {
        if (state == RecordState.stop) {
          return const Text("Start");
        } else {
          return const Text("Stop");
        }
      },
    );
  }
}
