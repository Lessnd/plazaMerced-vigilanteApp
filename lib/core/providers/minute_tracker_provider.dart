import 'package:flutter_riverpod/flutter_riverpod.dart';

// El latido del sistema. Obliga a reconstruir la UI cada 60 segundos.
final minuteTickerProvider = StreamProvider.autoDispose<void>((ref) {
  return Stream.periodic(const Duration(minutes: 1));
});