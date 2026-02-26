import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers/navigation_provider.dart';
// Importa aquí tu DashboardScreen que creamos antes
import '../../../dashboard/presentation/screens/dashboard_screen.dart'; 
import 'package:vigilante_app/features/parking/presentation/screens/activos_screen.dart';
import 'package:vigilante_app/features/parking/presentation/screens/history_screen.dart';

class MainLayout extends ConsumerWidget {
  const MainLayout({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuchamos el índice actual
    final currentIndex = ref.watch(bottomNavIndexProvider);

    // Lista de pantallas reales (Tus compañeros trabajarán dentro de cada una)
    final List<Widget> screens = [
      const DashboardScreen(), // La pantalla de Entrada/Salida
      const ActivosScreen(), // Pestaña 2
      const HistoryScreen(), // Pestaña 3
    ];

    return Scaffold(
      body: IndexedStack(
        index: currentIndex,
        children: screens,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          // Cambiamos el estado global
          ref.read(bottomNavIndexProvider.notifier).state = index;
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.point_of_sale_outlined),
            selectedIcon: Icon(Icons.point_of_sale),
            label: 'Operación',
          ),
          NavigationDestination(
            icon: Icon(Icons.directions_car_outlined),
            selectedIcon: Icon(Icons.directions_car),
            label: 'Activos',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history),
            label: 'Historial',
          ),
        ],
      ),
    );
  }
}
