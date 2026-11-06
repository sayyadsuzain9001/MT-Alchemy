import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'backend/backend.dart';
import 'chat/chat_widget.dart';
import 'commerce/commerce_prototype_store.dart';
import 'data/mock_data.dart';
import 'pages.dart';
import 'shared/auth_prototype_store.dart';
import 'theme.dart';
import 'widgets.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  if (kIsWeb && const bool.fromEnvironment('ENABLE_SEMANTICS')) {
    // Exposes the accessibility tree to browser automation in end-to-end runs.
    SemanticsBinding.instance.ensureSemantics();
  }
  String? startupError;
  try {
    await Backend.initialize();
    await loadCourseCatalogue();
    await CommercePrototypeStore.instance.load();
    await AuthPrototypeStore.instance.restoreSession();
  } catch (e) {
    startupError = '$e';
  }
  runApp(MtAlchemyApp(startupError: startupError));
}

class MtAlchemyApp extends StatelessWidget {
  const MtAlchemyApp({super.key, this.startupError});
  final String? startupError;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MT Alchemy',
      debugShowCheckedModeBanner: false,
      theme: buildTheme(),
      navigatorKey: appNavigatorKey,
      initialRoute: '/',
      onGenerateRoute: buildRoute,
      // Opening a page directly (or refreshing) builds Home → parent →
      // page, so Back always leads to a sensible place.
      onGenerateInitialRoutes: (name) {
        final path = name.split('?').first;
        final parent = parentRouteOf(path);
        return [
          buildRoute(const RouteSettings(name: '/')),
          if (parent != '/' && parent != path)
            buildRoute(RouteSettings(name: parent)),
          if (name != '/') buildRoute(RouteSettings(name: name)),
        ];
      },
      builder: (context, child) => ChatOverlay(
        child: startupError == null
            ? child!
            : Banner(
                message: 'OFFLINE',
                location: BannerLocation.topEnd,
                child: child!,
              ),
      ),
    );
  }
}
