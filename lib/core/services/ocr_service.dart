import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:permission_handler/permission_handler.dart';
import 'plate_recognizer_service.dart';
import 'package:vigilante_app/shared/widgets/app_toast.dart';

class OcrService {
  /// Reconoce texto en una imagen usando Google ML Kit y extrae una posible placa
  static Future<String?> recognizeTextFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    try {
      final RecognizedText recognizedText = await textRecognizer.processImage(
        inputImage,
      );
      String fullText = recognizedText.text;
      print('📸 [OCR] Texto reconocido: "$fullText"');

      // Limpiar y extraer placa
      String? plate = _extractPlate(fullText);
      return plate;
    } catch (e) {
      print('❌ [OCR] Error en reconocimiento: $e');
      return null;
    } finally {
      textRecognizer.close();
    }
  }

  /// Intenta extraer una placa del texto reconocido (formato mexicano común)
  static String? _extractPlate(String text) {
    // Convertir a mayúsculas y eliminar espacios extras
    String cleaned = text.toUpperCase().replaceAll(RegExp(r'\s+'), ' ');

    // Patrones comunes de placas mexicanas:
    // - 3 letras + 3 números (ej. ABC123)
    // - 3 letras + 4 números (ej. ABC1234)
    // - 4 letras + 3 números (ej. ABCD123)
    // - 4 letras + 4 números (ej. ABCD1234)
    RegExp plateRegex = RegExp(r'[A-Z0-9]{6,8}');
    Iterable<Match> matches = plateRegex.allMatches(cleaned);

    for (Match match in matches) {
      String candidate = match.group(0)!;
      // Validar que tenga al menos 3 letras y 3 números
      int letters = candidate.replaceAll(RegExp(r'[^A-Z]'), '').length;
      int digits = candidate.replaceAll(RegExp(r'[^0-9]'), '').length;

      if (letters >= 3 && digits >= 3) {
        print('✅ [OCR] Placa candidata encontrada: $candidate');
        return candidate;
      }
    }

    // Si no encuentra un patrón claro, devuelve el texto limpio sin espacios
    String fallback = cleaned.replaceAll(' ', '');
    print('⚠️ [OCR] No se encontró patrón de placa, devolviendo: $fallback');
    return fallback;
  }

  /// Flujo completo: solicita permiso, abre cámara, toma foto y reconoce placa
  static Future<String?> captureAndRecognize(
    BuildContext context, {
    bool useCloud = true,
    String? region,
  }) async {
    // Verificar permiso de cámara
    PermissionStatus status = await Permission.camera.request();
    if (!status.isGranted) {
      if (context.mounted) {
        AppToastService.show(
          context,
          'Se necesita permiso de cámara para escanear placas',
          type: AppToastType.error,
        );
      }
      return null;
    }

    // Verificar disponibilidad de cámaras
    List<CameraDescription> cameras;
    try {
      cameras = await availableCameras();
    } catch (e) {
      print('❌ [OCR] Error al obtener cámaras: $e');
      if (context.mounted) {
        AppToastService.show(
          context,
          'Error al acceder a la cámara',
          type: AppToastType.error,
        );
      }
      return null;
    }

    if (cameras.isEmpty) {
      if (context.mounted) {
        AppToastService.show(
          context,
          'No hay cámaras disponibles',
          type: AppToastType.error,
        );
      }
      return null;
    }

    // Navegar a la pantalla de captura y esperar el resultado
    final result = await Navigator.push<String>(
      context,
      MaterialPageRoute(
        builder: (context) =>
            CameraScreen(cameras: cameras, useCloud: useCloud, region: region),
      ),
    );

    return result;
  }
}

/// Pantalla de cámara para capturar imagen
class CameraScreen extends StatefulWidget {
  final List<CameraDescription> cameras;
  final bool useCloud;
  final String? region;

  const CameraScreen({
    super.key,
    required this.cameras,
    this.useCloud = true,
    this.region,
  });

  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    // Usar cámara trasera por defecto
    _controller = CameraController(
      widget.cameras.firstWhere(
        (camera) => camera.lensDirection == CameraLensDirection.back,
        orElse: () => widget.cameras.first,
      ),
      ResolutionPreset.high, // Alta resolución para mejor OCR
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Escanear Placa'),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<void>(
        future: _initializeControllerFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Stack(
              children: [
                // Vista previa de cámara
                CameraPreview(_controller),

                // Guía para centrar la placa
                Center(
                  child: Container(
                    width: 300,
                    height: 150,
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.white, width: 3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Center(
                      child: Text(
                        'Centra la placa aquí',
                        style: TextStyle(
                          color: Colors.white,
                          backgroundColor: Colors.black54,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                ),

                // Botón de captura
                Positioned(
                  bottom: 30,
                  left: 30,
                  right: 30,
                  child: ElevatedButton(
                    onPressed: _isProcessing ? null : _takePicture,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: _isProcessing
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text(
                            'Tomar Foto',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                ),
              ],
            );
          } else {
            return const Center(child: CircularProgressIndicator());
          }
        },
      ),
    );
  }

  Future<void> _takePicture() async {
    if (_isProcessing) return;
    setState(() => _isProcessing = true);

    try {
      // Asegurar que la cámara esté inicializada
      await _initializeControllerFuture;

      // Tomar foto
      final image = await _controller.takePicture();
      print('📸 [OCR] Foto tomada: ${image.path}');

      String? plate;

      // Procesar según la opción seleccionada
      if (widget.useCloud) {
        // Usar servicio en la nube
        final service = PlateRecognizerService();
        plate = await service.recognizePlate(
          File(image.path),
          region: widget.region ?? 'sv',
        );
      } else {
        // Usar OCR local
        plate = await OcrService.recognizeTextFromImage(File(image.path));
      }

      // Regresar resultado
      if (plate != null && plate.isNotEmpty) {
        if (mounted) {
          Navigator.pop(context, plate);
        }
      } else {
        if (mounted) {
          setState(() => _isProcessing = false);
          AppToastService.show(
            context,
            'No se pudo reconocer la placa. Intenta de nuevo.',
            type: AppToastType.warning,
          );
        }
      }
    } catch (e) {
      print('❌ [OCR] Error al tomar foto: $e');
      if (mounted) {
        setState(() => _isProcessing = false);
        AppToastService.show(
          context,
          'Error al capturar imagen',
          type: AppToastType.error,
        );
      }
    }
  }
}
