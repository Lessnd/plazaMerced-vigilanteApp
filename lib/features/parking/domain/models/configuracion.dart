class Configuracion {
  final int id;
  final double tarifaParqueoHora;
  final double tarifaBano;
  final DateTime ultimaActualizacion;
  final int timeOffset; // Diferencia con NTP en ms

  Configuracion({
    required this.id,
    required this.tarifaParqueoHora,
    required this.tarifaBano,
    required this.ultimaActualizacion,
    required this.timeOffset,
  });

  factory Configuracion.fromMap(Map<String, dynamic> map) {
    return Configuracion(
      id: map['id'] as int,
      tarifaParqueoHora: (map['tarifaParqueoHora'] as num).toDouble(),
      tarifaBano: (map['tarifaBano'] as num).toDouble(),
      ultimaActualizacion: DateTime.parse(map['ultimaActualizacion'] as String),
      timeOffset: map['timeOffset'] as int,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'tarifaParqueoHora': tarifaParqueoHora,
      'tarifaBano': tarifaBano,
      'ultimaActualizacion': ultimaActualizacion.toIso8601String(),
      'timeOffset': timeOffset,
    };
  }

  /// Convierte desde JSON del servidor (endpoint /api/config)
  factory Configuracion.fromJsonServer(Map<String, dynamic> json) {
    return Configuracion(
      id: 1, // Fija en local
      tarifaParqueoHora: (json['precio_hora'] as num).toDouble(),
      tarifaBano: 0.5, // Ajusta según tu backend (puede venir en otro campo)
      ultimaActualizacion: DateTime.now(),
      timeOffset: 0, // Se mantiene el offset local
    );
  }
}
