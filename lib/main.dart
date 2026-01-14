import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:easy_speech_recognition/services/model_manager_service.dart';
import 'package:easy_speech_recognition/services/recognition_service.dart';
import 'package:easy_speech_recognition/view_models/streaming_view_model.dart';
import 'package:easy_speech_recognition/routes/app_router.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<ModelManagerService>(
          create: (_) => ModelManagerService(),
        ),
        Provider<RecognitionService>(
          create: (_) => RecognitionService(),
          dispose: (_, service) => service.dispose(),
        ),
        ProxyProvider2<RecognitionService, ModelManagerService,
            StreamingViewModel>(
          update: (_, recognitionService, modelManagerService, __) =>
              StreamingViewModel(
            recognitionService: recognitionService,
            modelManagerService: modelManagerService,
          ),
        ),
      ],
      child: MaterialApp.router(
        title: 'Easy Speech Recognition MVVM',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        routerConfig: AppRouter.router,
      ),
    );
  }
}
