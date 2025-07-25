import 'package:college_app/chatBot/consts.dart';
import 'package:college_app/splash_screen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_gemini/flutter_gemini.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';

// Separate initialization function for better organization
Future<void> _initializeServices() async {
  try {
    // Run initializations in parallel where possible
    await Future.wait([
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge),
      Firebase.initializeApp(),
      GetStorage.init(),
    ]);

    // Initialize Gemini API
    Gemini.init(apiKey: GEMIINI_API_KEY);
  } catch (e) {
    debugPrint("Error during initialization: $e");
  }
}
void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await _initializeServices();

  FlutterNativeSplash.remove();

  Get.put(ThemeController(), permanent: true);

  runApp(const College());
}

class College extends StatelessWidget {
  const College({super.key});

  static final ThemeData _lightTheme = ThemeData(
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF6750A4),
      secondary: Color(0xFF625B71),
      tertiary: Color(0xFF7D5260),
      surface: Color(0xFFFFFBFE),
    ),
    useMaterial3: true,
    fontFamily: 'Poppins',
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        elevation: 4,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
    cardTheme: CardTheme(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );

  static final ThemeData _darkTheme = ThemeData.dark(useMaterial3: true);

  @override
  Widget build(BuildContext context) {
    final themeController = Get.find<ThemeController>();

    return Obx(() {
      return GetMaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Skisha Hub',
        theme: _lightTheme,
        darkTheme: _darkTheme,
        themeMode: themeController.themeMode,
        home: const SplashScreen(),
      );
    });
  }
}

class ThemeController extends GetxController {
  final RxBool isDarkTheme = false.obs;
  final GetStorage _storage = GetStorage();

  ThemeController() {
    isDarkTheme.value = _storage.read<bool>('isDarkTheme') ?? false;
  }

  ThemeMode get themeMode => isDarkTheme.value ? ThemeMode.dark : ThemeMode.light;

  void toggleTheme() {
    isDarkTheme.value = !isDarkTheme.value;
    _storage.write('isDarkTheme', isDarkTheme.value);
    _updateSystemUI();
  }

  void _updateSystemUI() {
    SystemChrome.setSystemUIOverlayStyle(
      SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: isDarkTheme.value ? Brightness.light : Brightness.dark,
        statusBarBrightness: isDarkTheme.value ? Brightness.dark : Brightness.light,
      ),
    );
  }
}