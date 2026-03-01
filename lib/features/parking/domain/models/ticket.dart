// lib/features/parking/domain/models/ticket.dart

import 'package:uuid/uuid.dart';

class Ticket {
  final int? id; // ID autoincremental local (solo SQLite)
  final String serverId; // UUID único para el servidor
  final String placa;
  final String deviceId;
  final DateTime entrada;
  final DateTime? salida;
  final double? costo;
  final double tarifaAplicada;
  final String? generacionId;
  final int sincronizado; // 0=pendiente, 1=sincronizado, 2=error
  final int esTiempoManipulado; // 0/1

  Ticket({
    this.id,
    required this.serverId,
    required this.placa,
    required this.deviceId,
    required this.entrada,
    this.salida,
    this.costo,
    required this.tarifaAplicada,
    this.generacionId,
    required this.sincronizado,
    required this.esTiempoManipulado,
  });

  /// Crea un nuevo ticket de entrada (sin salida)
  factory Ticket.entrada({
    required String placa,
    required String deviceId,
    required DateTime entrada,
    required double tarifaAplicada,
    String? generacionId,
  }) {
    return Ticket(
      serverId: const Uuid().v4(),
      placa: placa.toUpperCase().trim(),
      deviceId: deviceId,
      entrada: entrada,
      tarifaAplicada: tarifaAplicada,
      generacionId: generacionId,
      sincronizado: 0,
      esTiempoManipulado: 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'serverId': serverId,
      'placa': placa,
      'deviceId': deviceId,
      'entrada': entrada.toIso8601String(),
      'salida': salida?.toIso8601String(),
      'costo': costo,
      'tarifaAplicada': tarifaAplicada,
      'generacionId': generacionId,
      'sincronizado': sincronizado,
      'es_tiempo_manipulado': esTiempoManipulado,
    };
  }

  /// Convierte desde un Map de SQLite, tolerando valores nulos
  factory Ticket.fromMap(Map<String, dynamic> map) {
    return Ticket(
      id: map['id'] as int?, // Ahora acepta null explícitamente
      serverId:
          map['serverId'] as String? ??
          '', // Si es null, string vacío (no debería ocurrir)
      placa: map['placa'] as String? ?? '',
      deviceId: map['deviceId'] as String? ?? '',
      entrada: map['entrada'] != null
          ? DateTime.parse(map['entrada'] as String)
          : DateTime.now(), // fallback (no debería)
      salida: map['salida'] != null
          ? DateTime.parse(map['salida'] as String)
          : null,
      costo: (map['costo'] as num?)?.toDouble(),
      tarifaAplicada: (map['tarifaAplicada'] as num?)?.toDouble() ?? 0.0,
      generacionId: map['generacionId'] as String?,
      sincronizado: map['sincronizado'] as int? ?? 0,
      esTiempoManipulado: map['es_tiempo_manipulado'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJsonForServer() {
    return {
      'id': serverId,
      'placa': placa,
      'hora_entrada': entrada.toIso8601String(),
      'hora_salida': salida?.toIso8601String(),
      'monto_total': costo ?? 0,
      'tarifa_aplicada': tarifaAplicada,
      'is_activo': salida == null,
      'generacion_id': generacionId,
    };
  }

  Ticket copyWith({
    int? id,
    String? serverId,
    String? placa,
    String? deviceId,
    DateTime? entrada,
    DateTime? salida,
    double? costo,
    double? tarifaAplicada,
    String? generacionId,
    int? sincronizado,
    int? esTiempoManipulado,
  }) {
    return Ticket(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      placa: placa ?? this.placa,
      deviceId: deviceId ?? this.deviceId,
      entrada: entrada ?? this.entrada,
      salida: salida ?? this.salida,
      costo: costo ?? this.costo,
      tarifaAplicada: tarifaAplicada ?? this.tarifaAplicada,
      generacionId: generacionId ?? this.generacionId,
      sincronizado: sincronizado ?? this.sincronizado,
      esTiempoManipulado: esTiempoManipulado ?? this.esTiempoManipulado,
    );
  }
}