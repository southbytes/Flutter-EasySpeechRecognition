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

    // Listen to busy state to show/hide dialog or indicators
    _viewModel.isBusy.addListener(_onBusyChanged);

    // Listen to errors
    _viewModel.error.addListener(_onError);
  }

  @override
  void dispose() {
    _viewModel.isBusy.removeListener(_onBusyChanged);
    _viewModel.error.removeListener(_onError);
    _controller.dispose();
    super.dispose();
  }

  void _onBusyChanged() {
    if (_viewModel.isBusy.value) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
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
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            children: [
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: SingleChildScrollView(
                    child: ValueListenableBuilder<String>(
                      valueListenable: _viewModel.recognizedText,
                      builder: (context, text, child) {
                        return Text(
                          text.isEmpty
                              ? 'Transcription will appear here...'
                              : text,
                          style: Theme.of(context).textTheme.bodyLarge,
                        );
                      },
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              ValueListenableBuilder<RecordState>(
                valueListenable: _viewModel.recordState,
                builder: (context, state, _) {
                  final isRecording = state != RecordState.stop;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 50.0),
                    child: Text(
                      isRecording ? "Recording..." : "Idle",
                      style: TextStyle(
                        fontSize: 20,
                        // fontWeight: FontWeight.bold,
                        color: isRecording ? Colors.red : Colors.grey,
                      ),
                    ),
                  );
                },
              ),
              // Show download button if needed
              ValueListenableBuilder<bool>(
                valueListenable: _viewModel.needsDownloadOrUnzip,
                builder: (context, needsDownload, child) {
                  if (needsDownload) {
                    return Padding(
                      padding: const EdgeInsets.only(top: 10),
                      child: ElevatedButton(
                        onPressed: () {
                          _viewModel.downloadAndSetupModel();
                        },
                        child: const Text("Download Model"),
                      ),
                    );
                  }
                  return const SizedBox.shrink();
                },
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: ValueListenableBuilder<bool>(
        valueListenable: _viewModel.needsDownloadOrUnzip,
        builder: (context, needsDownload, _) {
          if (needsDownload) return const SizedBox.shrink();

          return ValueListenableBuilder<RecordState>(
            valueListenable: _viewModel.recordState,
            builder: (context, state, child) {
              final isRecording = state != RecordState.stop;
              return FloatingActionButton(
                onPressed: () {
                  _viewModel.toggleRecording();
                },
                backgroundColor: isRecording ? Colors.red : null,
                child: Icon(isRecording ? Icons.stop : Icons.mic),
              );
            },
          );
        },
      ),
    );
  }
}
