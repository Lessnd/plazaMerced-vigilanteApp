class CalculadoraTarifa {
  /// Calcula el costo total del parqueo basado en las reglas de negocio de Plaza Merced.
  /// No depende de Flutter ni de bases de datos. Es matemática pura.
  static double calcularCosto({
    required DateTime entrada,
    required DateTime salida,
    required double tarifaHora, // $1.00
    required int minutosCortesia, // 3
  }) {
    if (salida.isBefore(entrada)) {
      throw ArgumentError('La fecha de salida no puede ser anterior a la entrada. Revisa el reloj del hardware.');
    }

    final duracion = salida.difference(entrada);
    final minutosTotales = duracion.inMinutes;

    // 1. Regla de Cortesía: Si sale antes del tiempo de gracia, es gratis.
    if (minutosTotales <= minutosCortesia) {
      return 0.0;
    }

    // 2. Regla de Fracciones: 
    // Ej: 61 minutos / 60 = 1.016. ceil() lo redondea a 2.0 (2 horas cobradas).
    // Ej: 59 minutos / 60 = 0.983. ceil() lo redondea a 1.0 (1 hora cobrada).
    final horasACobrar = (minutosTotales / 60.0).ceil();

    return horasACobrar * tarifaHora;
  }
}