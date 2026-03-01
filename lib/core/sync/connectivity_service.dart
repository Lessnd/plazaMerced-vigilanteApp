import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final connectivityServiceProvider = Provider<ConnectivityService>((ref) {
  return ConnectivityService();
});

class ConnectivityService {
  final Connectivity _connectivity = Connectivity();
  final _controller = StreamController<ConnectivityResult>.broadcast();

  ConnectivityService() {
    _connectivity.onConnectivityChanged.listen((result) {
      // Log cada cambio de conectividad
      print('🌐 [Connectivity] Cambió a: $result');
      _controller.add(result);
    });
  }

  Stream<ConnectivityResult> get onConnectivityChanged => _controller.stream;

  Future<bool> get isConnected async {
    final result = await _connectivity.checkConnectivity();
    final connected = result != ConnectivityResult.none;
    print('🌐 [Connectivity] Verificando conexión: $connected');
    return connected;
  }
}
