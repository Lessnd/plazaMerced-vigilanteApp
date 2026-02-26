import 'package:flutter_riverpod/flutter_riverpod.dart';

// 0: Operación (Dashboard), 1: Activos, 2: Historial
final bottomNavIndexProvider = StateProvider<int>((ref) => 0);