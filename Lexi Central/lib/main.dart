import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:window_manager/window_manager.dart';
import 'features/customization/data/services/customization_service.dart';
import 'features/notes_links/data/services/notes_storage_service.dart';
import 'features/vault/data/services/vault_auth_service.dart';
import 'core/theme/app_theme.dart';
import 'core/widgets/kirby_background.dart';
import 'core/widgets/main_layout.dart';
import 'navigation/app_router.dart';
import 'features/customization/presentation/screens/loading_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Initialize services
  await _initializeServices();
  
  // Configure Windows desktop
  await _configureWindows();
  
  runApp(const LexiCentralApp());
}

Future<void> _initializeServices() async {
  try {
    // Initialize customization service
    final customizationService = CustomizationService();
    await customizationService.initialize();
    
    // Initialize notes storage service
    final notesStorageService = NotesStorageService();
    await notesStorageService.initialize();
    
    // Initialize vault auth service
    await VaultAuthService.isVaultSetup();
    
    print('✅ All services initialized successfully');
  } catch (e) {
    print('❌ Error initializing services: $e');
  }
}

Future<void> _configureWindows() async {
  try {
    await windowManager.ensureInitialized();
    
    WindowOptions windowOptions = const WindowOptions(
      size: Size(1200, 800),
      center: true,
      backgroundColor: Colors.transparent,
      skipTaskbar: false,
      titleBarStyle: TitleBarStyle.hidden,
      windowButtonVisibility: false,
    );
    
    windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
    
    print('✅ Windows desktop configured');
  } catch (e) {
    print('❌ Error configuring Windows: $e');
  }
}

class LexiCentralApp extends ConsumerStatefulWidget {
  const LexiCentralApp({super.key});

  @override
  ConsumerState<LexiCentralApp> createState() => _LexiCentralAppState();
}

class _LexiCentralAppState extends ConsumerState<LexiCentralApp> {
  bool _isLoading = true;
  
  @override
  void initState() {
    super.initState();
    _initializeApp();
  }
  
  Future<void> _initializeApp() async {
    // Simulate loading time for the loading screen
    await Future.delayed(const Duration(seconds: 3));
    
    if (mounted) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const LoadingScreen();
    }

    return MaterialApp.router(
      title: 'Lexi Central',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.kirbyTheme,
      routerConfig: AppRouter.router,
      builder: (context, child) {
        return KeyboardListener(
          focusNode: FocusNode(),
          onKeyEvent: (event) {
            // Handle global keyboard shortcuts
            if (event is KeyDownEvent) {
              if (event.logicalKey == LogicalKeyboardKey.f11) {
                // Toggle fullscreen
                windowManager.isFullScreen().then((isFullScreen) {
                  windowManager.setFullScreen(!isFullScreen);
                });
              }
            }
          },
          child: Stack(
            children: [
              // Background layer
              const KirbyBackground(),
              
              // Main content
              MainLayout(child: child!),
            ],
          ),
        );
      },
    );
  }
}
