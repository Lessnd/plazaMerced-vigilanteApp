import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:image/image.dart' as img;
import 'package:path_provider/path_provider.dart';

class PlateRecognizerService {
  static const String _baseUrl =
      'https://api.platerecognizer.com/v1/plate-reader/';
  late final Dio _dio;
  final String _token;

  PlateRecognizerService()
    : _token = dotenv.env['PLATE_RECOGNIZER_TOKEN'] ?? '' {
    if (_token.isEmpty) {
      print('⚠️ [PlateRecognizer] Token no encontrado en .env');
    }
    _dio = Dio(
      BaseOptions(
        baseUrl: _baseUrl,
        headers: {'Authorization': 'Token $_token'},
        validateStatus: (status) => status! < 500, // Acepta 200-499
      ),
    );
  }

  Future<File> _compressImage(File file) async {
    final originalBytes = await file.readAsBytes();
    final image = img.decodeImage(originalBytes);
    if (image == null)
      return file; // Si no se puede decodificar, devuelve original

    // Redimensionar manteniendo aspecto, ancho máximo 800px (ajústalo según necesites)
    final resized = img.copyResize(image, width: 800);
    final compressed = img.encodeJpg(resized, quality: 85); // 85% de calidad

    final tempDir = await getTemporaryDirectory();
    final tempFile = File(
      '${tempDir.path}/compressed_${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await tempFile.writeAsBytes(compressed);
    return tempFile;
  }

  /// Envía una imagen y devuelve la placa con mayor confianza
  Future<String?> recognizePlate(File imageFile, {String? region}) async {
    if (_token.isEmpty) {
      print('❌ [PlateRecognizer] Token no configurado');
      return null;
    }

    try {
      // Comprimir la imagen antes de enviarla
      final compressedFile = await _compressImage(imageFile);

      String fileName = compressedFile.path.split('/').last;
      FormData formData = FormData.fromMap({
        'upload': await MultipartFile.fromFile(
          compressedFile.path,
          filename: fileName,
        ),
      });

      if (region != null) {
        formData.fields.add(MapEntry('regions', region));
      }

      final response = await _dio.post('', data: formData);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = response.data;
        if (data['results'] != null && data['results'].isNotEmpty) {
          // Ordenar por confianza descendente
          List results = List.from(data['results']);
          results.sort(
            (a, b) => (b['score'] as num).compareTo(a['score'] as num),
          );
          final best = results.first;
          final plate = best['plate'] as String;
          final confidence = best['score'] as num;
          print('✅ [PlateRecognizer] Placa: $plate (confianza: $confidence)');
          return plate;
        } else {
          print('⚠️ [PlateRecognizer] No se detectaron placas');
          return null;
        }
      } else {
        print(
          '❌ [PlateRecognizer] Error HTTP ${response.statusCode}: ${response.data}',
        );
        return null;
      }
    } on DioException catch (e) {
      print('❌ [PlateRecognizer] Error de red: $e');
      if (e.response != null) {
        print('Detalles: ${e.response?.data}');
      }
      return null;
    } catch (e) {
      print('❌ [PlateRecognizer] Error inesperado: $e');
      return null;
    }
  }
}
