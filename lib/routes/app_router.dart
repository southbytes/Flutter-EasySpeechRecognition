import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../views/streaming_page.dart';
import '../view_models/streaming_view_model.dart';

class AppRouter {
  static final router = GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) {
          final viewModel =
              Provider.of<StreamingViewModel>(context, listen: false);
          return StreamingPage(viewModel: viewModel);
        },
      ),
    ],
  );
}
