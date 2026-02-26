import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'device_service.g.dart';

class DeviceService {
  Future<String> getDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();
    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      // .id extrae un identificador único del hardware/build
      return androidInfo.id; 
    }
    // Si algún día pruebas esto en web o iOS por accidente, no explotará.
    return 'UNKNOWN_DEVICE';
  }
}

// Inyectamos el servicio en Riverpod
@riverpod
DeviceService deviceService(DeviceServiceRef ref) {
  return DeviceService();
}