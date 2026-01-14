import 'dart:io';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:archive/archive.dart';
import 'package:archive/archive_io.dart';

class ModelManagerService {
  final ValueNotifier<double> downloadProgress = ValueNotifier(0.0);
  final ValueNotifier<double> unzipProgress = ValueNotifier(0.0);
  final ValueNotifier<String?> error = ValueNotifier(null);

  Future<bool> isModelReady(String modelName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final modulePath = join(directory.path, modelName);
    bool moduleExists = await Directory(modulePath).exists();
    return moduleExists;
  }

  Future<bool> needsDownload(String modelName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final modulePath = join(directory.path, modelName);
    bool moduleExists = await Directory(modulePath).exists();
    final moduleZipFilePath = join(directory.path, '$modelName.tar.bz2');
    bool moduleZipExists = await File(moduleZipFilePath).exists();
    return !moduleExists && !moduleZipExists;
  }

  Future<bool> needsUnZip(String modelName) async {
    final Directory directory = await getApplicationDocumentsDirectory();
    final modulePath = join(directory.path, modelName);
    bool moduleExists = await Directory(modulePath).exists();
    final moduleZipFilePath = join(directory.path, '$modelName.tar.bz2');
    bool moduleZipExists = await File(moduleZipFilePath).exists();
    return moduleZipExists && !moduleExists;
  }

  Future<void> downloadModel(String modelName) async {
    downloadProgress.value = 0.0;
    error.value = null;

    final downLoadUrl =
        'https://github.com/k2-fsa/sherpa-onnx/releases/download/asr-models/$modelName.tar.bz2';
    final Directory directory = await getApplicationDocumentsDirectory();
    final moduleZipFilePath = join(directory.path, '$modelName.tar.bz2');

    try {
      final client = http.Client();
      final request = http.Request('GET', Uri.parse(downLoadUrl));
      final response = await client.send(request);

      int totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      final file = File(moduleZipFilePath);
      final sink = file.openWrite();

      await response.stream.forEach((List<int> chunk) {
        sink.add(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          downloadProgress.value = receivedBytes / totalBytes;
        }
      });

      await sink.flush();
      await sink.close();

      downloadProgress.value = 1.0;
    } catch (e) {
      error.value = e.toString();
      final partialFile = File(moduleZipFilePath);
      if (await partialFile.exists()) {
        await partialFile.delete();
      }
      rethrow;
    }
  }

  Future<void> unzipModel(String modelName) async {
    unzipProgress.value = 0.0;
    error.value = null;

    final Directory directory = await getApplicationDocumentsDirectory();
    final moduleZipFilePath = join(directory.path, '$modelName.tar.bz2');

    try {
      await _unzipDownloadedFile(moduleZipFilePath, directory.path);
      unzipProgress.value = 1.0;
    } catch (e) {
      error.value = e.toString();
      unzipProgress.value = 0.0;
      rethrow;
    }
  }

  Future<void> _unzipDownloadedFile(
      String zipFilePath, String destinationPath) async {
    unzipProgress.value = 0.1;

    final result = await compute(
        _decompressInIsolate, UnzipParams(zipFilePath, destinationPath));

    unzipProgress.value = 0.4;

    final files = result[1] as List<ArchiveFile>;
    final totalFiles = files.length;
    int processedFiles = 0;

    for (final file in files) {
      await compute(_extractFileInIsolate,
          {'file': file, 'destinationPath': destinationPath});

      processedFiles++;
      double progress = 0.4 + (0.6 * processedFiles / totalFiles);
      if (processedFiles % 10 == 0) {
        // Yield to event loop occasionally
        await Future.delayed(Duration.zero);
      }
      unzipProgress.value = progress;
    }
  }
}

class UnzipParams {
  final String zipFilePath;
  final String destinationPath;

  UnzipParams(this.zipFilePath, this.destinationPath);
}

Future<List<dynamic>> _decompressInIsolate(UnzipParams params) async {
  final bytes = File(params.zipFilePath).readAsBytesSync();
  final archive = BZip2Decoder().decodeBytes(bytes);
  final tarArchive = TarDecoder().decodeBytes(archive);
  return [archive, tarArchive.files];
}

Future<void> _extractFileInIsolate(Map<String, dynamic> params) async {
  final file = params['file'] as ArchiveFile;
  final destinationPath = params['destinationPath'] as String;
  final filename = file.name;

  if (file.isFile) {
    final data = file.content as List<int>;
    File(join(destinationPath, filename))
      ..createSync(recursive: true)
      ..writeAsBytesSync(data);
  } else {
    Directory(join(destinationPath, filename)).create(recursive: true);
  }
}
