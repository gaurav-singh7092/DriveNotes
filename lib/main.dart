import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:note_sync/core/theme/theme_provider.dart';
import 'package:note_sync/presentation/routes/app_router.dart';
import 'package:http/http.dart' as http;
import 'dart:io' if (dart.library.html) 'package:note_sync/utils/web_stub.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:note_sync/utils/config_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ConfigService().initialize();

  if (!kIsWeb) {
    http.get(Uri.parse('https://accounts.google.com')).then((response) {
      debugPrint('Connection test result: ${response.statusCode}');
    }).catchError((error) {
      debugPrint('Connection error: $error');
    });

    debugPrint('Running on platform: ${Platform.operatingSystem}');
    if (Platform.isIOS) {
      debugPrint('iOS version: ${Platform.operatingSystemVersion}');
    }
  } else {
    debugPrint('Running on web platform');
  }

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(goRouterProvider);
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp.router(
      title: 'DriveNotes',
      theme: lightThemeData,
      darkTheme: darkThemeData,
      themeMode: themeMode,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}
