import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/parking/domain/models/ticket.dart';

// El provider para inyectar la impresora en cualquier parte de la app
final printerServiceProvider = Provider<PrinterService>((ref) {
  return PrinterService();
});

class PrinterService {
  /// Simula la validación del estado del hardware (papel, temperatura, conexión)
  Future<bool> checkPrinterStatus() async {
    print('🖨️ [PrinterService] Verificando hardware térmico...');
    await Future.delayed(const Duration(milliseconds: 300));
    // Aquí en el futuro llamarás al SDK real (ej. SunmiPrinter.getPrinterStatus())
    return true; 
  }

  /// Imprime el comprobante al momento de entrar
  Future<void> printEntryTicket(Ticket ticket) async {
    print('🖨️ [PrinterService] Enviando comandos ESC/POS a la impresora...');
    
    // Simulamos el tiempo mecánico de impresión (1.5 segundos)
    await Future.delayed(const Duration(milliseconds: 1500)); 

    // Formateamos la fecha para que sea legible en el papel
    final String fechaEntrada = "${ticket.entrada.day.toString().padLeft(2, '0')}/${ticket.entrada.month.toString().padLeft(2, '0')}/${ticket.entrada.year} ${ticket.entrada.hour.toString().padLeft(2, '0')}:${ticket.entrada.minute.toString().padLeft(2, '0')}";

    final String receipt = '''
================================
      PARQUEO PLAZA MERCED      
================================
TICKET DE ENTRADA

ID: ${ticket.serverId.substring(0, 8).toUpperCase()}
PLACA: ${ticket.placa}
--------------------------------
ENTRADA:
$fechaEntrada

TARIFA APLICADA: \$${ticket.tarifaAplicada.toStringAsFixed(2)} / h
--------------------------------
Por favor, no pierda este ticket
================================
''';
    
    print(receipt);
  }

  /// Imprime el recibo final con el cobro total al salir
  Future<void> printExitReceipt(Ticket ticket, int minutosTotales) async {
    print('🖨️ [PrinterService] Imprimiendo recibo fiscal de salida...');
    await Future.delayed(const Duration(milliseconds: 1500));

    final String fechaEntrada = "${ticket.entrada.day.toString().padLeft(2, '0')}/${ticket.entrada.month.toString().padLeft(2, '0')}/${ticket.entrada.year} ${ticket.entrada.hour.toString().padLeft(2, '0')}:${ticket.entrada.minute.toString().padLeft(2, '0')}";
    final String fechaSalida = ticket.salida != null ? "${ticket.salida!.day.toString().padLeft(2, '0')}/${ticket.salida!.month.toString().padLeft(2, '0')}/${ticket.salida!.year} ${ticket.salida!.hour.toString().padLeft(2, '0')}:${ticket.salida!.minute.toString().padLeft(2, '0')}" : "N/A";

    final String receipt = '''
================================
      PARQUEO PLAZA MERCED      
================================
RECIBO DE PAGO

ID: ${ticket.serverId.substring(0, 8).toUpperCase()}
PLACA: ${ticket.placa}
--------------------------------
ENTRADA: $fechaEntrada
SALIDA:  $fechaSalida

TIEMPO TOTAL: $minutosTotales min
--------------------------------
TOTAL PAGADO:   \$${ticket.costo?.toStringAsFixed(2)}
================================
    ¡Gracias por su visita!     
================================
''';
    
    print(receipt);
  }
}