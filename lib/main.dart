import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:sizer/sizer.dart';

import './widgets/custom_error_widget.dart';
import 'package:hostel/core/app_export.dart';
import 'package:hostel/services/firebase_service.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import './widgets/offline_indicator_overlay.dart';
import './presentation/widgets/top_notification_banner_overlay.dart';
import './services/system_notification_service.dart';
import './services/push_notification_service.dart';
import './services/sound_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await FirebaseService().initialize();
  } catch (e) {
    debugPrint('Firebase init error: $e');
  }

  try {
    await SystemNotificationService().initialize();
  } catch (e) {
    debugPrint('SystemNotificationService init error: $e');
  }

  try {
    await PushNotificationService().initialize();
  } catch (e) {
    debugPrint('PushNotificationService init error: $e');
  }

  try {
    await SoundService().init();
  } catch (e) {
    debugPrint('SoundService init error: $e');
  }

  // 🚨 CRITICAL: Custom error handling - DO NOT REMOVE
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return CustomErrorWidget(errorDetails: details);
  };

  // 🚨 CRITICAL: Device orientation lock - DO NOT REMOVE
  Future.wait([
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]),
  ]).then((value) {
    GoRouter.optionURLReflectsImperativeAPIs = true;
    runApp(const ProviderScope(child: MyApp()));
  });
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return Sizer(
      builder: (context, orientation, screenType) {
        return MaterialApp.router(
          title: 'Sec Hostel',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: ThemeMode.light,
          // 🚨 CRITICAL: NEVER REMOVE OR MODIFY
          builder: (context, child) {
            return MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: TextScaler.linear(1.0)),
              child: Stack(
                children: [
                  ?child,
                  const OfflineIndicatorOverlay(),
                  const TopNotificationBannerOverlay(),
                ],
              ),
            );
          },
          // 🚨 END CRITICAL SECTION
          debugShowCheckedModeBanner: false,
          routerConfig: appRouter,
        );
      },
    );
  }
}
