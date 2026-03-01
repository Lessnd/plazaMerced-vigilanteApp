import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vigilante_app/features/main/presentation/screens/main_layout.dart';
import 'core/theme/app_theme.dart';
import 'core/sync/connectivity_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await dotenv.load();
  } catch (e) {
    print('⚠️ No se pudo cargar .env: $e');
    // Puedes definir valores por defecto aquí si es necesario
  }
  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final connectivityStream = ref
        .watch(connectivityServiceProvider)
        .onConnectivityChanged;

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Vigilante App',
      theme: AppTheme.lightTheme,
      home: StreamBuilder<ConnectivityResult>(
        stream: connectivityStream,
        builder: (context, snapshot) {
          final isOffline = snapshot.data == ConnectivityResult.none;
          return Stack(
            children: [
              const MainLayout(),
              if (isOffline)
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  child: SafeArea(
                    child: Container(
                      margin: const EdgeInsets.all(8),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.warning,
                        borderRadius: BorderRadius.circular(30),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.wifi_off,
                            color: Theme.of(context).colorScheme.onWarning,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Sin conexión',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onWarning,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
