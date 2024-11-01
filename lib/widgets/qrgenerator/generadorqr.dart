// Widget Stateful para generar y mostrar el QR
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:mcconnect/Providers/listaempleados.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:html' as html;

class QrGenerator extends StatefulWidget {
  final Empleado empleado; // Objeto empleado con datos para el QR
  final double size; // Tamaño del QR

  const QrGenerator({
    super.key,
    required this.empleado,
    required this.size,
  });

  @override
  State<QrGenerator> createState() => _QrGeneratorState();
}

// Clase para manejar el estilo del QR
class QrStyling {
  final Color color1; // Primer color para el gradiente
  final Color color2; // Segundo color para el gradiente
  final Color color3; // Tercer color para el gradiente
  final String pathLogo; // Ruta del logo dentro del QR

  QrStyling({
    required this.color1,
    required this.color2,
    required this.color3,
    required this.pathLogo,
  });
}

// Estado del widget QrGenerator
class _QrGeneratorState extends State<QrGenerator> {
  GlobalKey globalKey =
      GlobalKey(); // Clave global (no utilizada en este contexto)
  late Empleado empleados; // Objeto empleado local

  @override
  void initState() {
    super.initState();
    empleados = widget.empleado; // Inicializa el objeto empleado
  }

  // Método para obtener el estilo del QR basado en la compañía
  QrStyling obtenerLogo(String? compania) {
    switch (compania) {
      case 'Figibox':
        return QrStyling(
          color1: const Color(0xFF77A4E8),
          color2: const Color(0xFF163977),
          color3: const Color(0xFF163977),
          pathLogo: "../assets/Firma/figiboxSomos.jpeg",
        );
        case 'Figibox-Santiago':
        return QrStyling(
          color1: const Color(0xFF77A4E8),
          color2: const Color(0xFF163977),
          color3: const Color(0xFF163977),
          pathLogo: "../assets/Firma/figiboxSomos.jpeg",
        );
      case 'MCLogistics':
        return QrStyling(
          color1: const Color(0xFF8CC63F), // Verde claro
          color2: const Color(0xFF00A79D), // Verde azulado
          color3: const Color(0xFF0071BC),
          pathLogo: "../assets/Logo/Logo_mc.png",
        );
       case 'MCLogistics-Santiago':
        return QrStyling(
          color1: const Color(0xFF8CC63F), // Verde claro
          color2: const Color(0xFF00A79D), // Verde azulado
          color3: const Color(0xFF0071BC),
          pathLogo: "../assets/Logo/Logo_mc.png",
        );
      case 'ConsiliaLogistics':
        return QrStyling(
          color1: const Color(0xFF8CC63F), // Verde claro
          color2: const Color(0xFF00A79D), // Verde azulado
          color3: const Color(0xFF0071BC),
          pathLogo: "../assets/Logo/Concilialogo.png",
        );
      case 'HighPerformance':
        return QrStyling(
          color1: const Color(0xFF8CC63F), // Verde claro
          color2: const Color(0xFF00A79D), // Verde azulado
          color3: const Color(0xFF0071BC),
          pathLogo: "../assets/Logo/Logo_mc.png",
        );
      default:
        return QrStyling(
          color1: const Color(0xFF8CC63F), // Verde claro
          color2: const Color(0xFF00A79D), // Verde azulado
          color3: const Color(0xFF0071BC),
          pathLogo: "",
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    String nombreSinEspacios = widget.empleado.nombre_empleado
        .replaceAll(' ', ''); // Nombre sin espacios
    QrStyling qrStyling =
        obtenerLogo(empleados.division); // Obtiene el estilo del QR

    return Column(
      mainAxisAlignment: MainAxisAlignment.center, // Alineación vertical
      crossAxisAlignment: CrossAxisAlignment.center, // Alineación horizontal
      children: [
        Center(
            child: Stack(alignment: Alignment.center, children: [
          ShaderMask(
            shaderCallback: (Rect bounds) {
              return LinearGradient(
                colors: [
                  qrStyling.color1, // Primer color del gradiente
                  qrStyling.color2, // Segundo color del gradiente
                  qrStyling.color3, // Tercer color del gradiente
                ],
                begin: Alignment.topLeft, // Inicio del gradiente
                end: Alignment.bottomRight, // Fin del gradiente
              ).createShader(bounds);
            },
            blendMode: BlendMode.srcIn, // Modo de mezcla
            child: QrImageView(
              data:
                  "http://192.168.67.208:8080/#/contacto/${Uri.encodeComponent(widget.empleado.nombre_empleado)}", // Datos del QR (URL codificada)
              version: QrVersions.auto, // Versión automática del QR
              size: widget.size, // Tamaño del QR
              gapless: false, // Espacios entre módulos
              // ignore: deprecated_member_use
              foregroundColor: Colors.white, // Color base para el ShaderMask
              backgroundColor: Colors.transparent, // Fondo transparente
              errorCorrectionLevel:
                  QrErrorCorrectLevel.L, // Nivel de corrección de errores
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape:
                    QrDataModuleShape.circle, // Forma circular de los módulos
              ),
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.circle, // Forma circular de los ojos
              ),
              // Espaciado interno
            ),
          ),
          // Capa blanca en el centro del QR
          Container(
            width: 30, // Tamaño de la capa blanca
            height: 30,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: Colors.white,
            ), // Estilo de la capa blanca
          ),
          // Logo en el centro del QR
          SizedBox(
            width: 30,
            height: 30,
            child: Image.asset(
              qrStyling.pathLogo,
              fit: BoxFit.contain,
            ),
          )
        ])),
      ],
    );
  }
}

// Widget para mostrar el diálogo del QR
class QRDialog extends StatelessWidget {
  final Empleado empleado; // Objeto empleado con datos para el QR
  final ScreenshotController screenshotController =
      ScreenshotController(); // Controlador para capturar el QR

  QRDialog({super.key, required this.empleado});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10)), // Bordes redondeados
      child: Container(
        padding: const EdgeInsets.all(16.0), // Padding interno
        width: 300, // Ancho del diálogo
        height: 350, // Altura del diálogo
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center, // Alineación vertical
          children: [
            // Generador del QR dentro de un Screenshot
            Screenshot(
                controller: screenshotController,
                child: QrGenerator(empleado: empleado, size: 230)),
            const SizedBox(height: 20),
            // Botones para descargar o cancelar
            Row(
              mainAxisAlignment:
                  MainAxisAlignment.spaceEvenly, // Espaciado entre botones
              children: [
                // Botón para descargar el QR
                FilledButton(
                  onPressed: () async {
                    // Capturar el QR como imagen
                    final Uint8List? image =
                        await screenshotController.capture();

                    if (image != null) {
                      // Crear un blob de la imagen
                      final blob = html.Blob([image], 'image/png');
                      final url = html.Url.createObjectUrlFromBlob(blob);

                      // Crear un ancla invisible para descargar la imagen
                      final anchor = html.AnchorElement(href: url)
                        ..setAttribute('download', 'qr_code.png')
                        ..click();

                      // Limpiar la URL
                      html.Url.revokeObjectUrl(url);
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green[50], // Color de fondo
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10)), // Bordes redondeados
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 20), // Padding
                  ),
                  child: const Text(
                    "Descargar",
                    style: TextStyle(color: Colors.green), // Estilo del texto
                  ),
                ),
                // Botón para cancelar y cerrar el diálogo
                FilledButton(
                  onPressed: () {
                    Navigator.of(context).pop(); // Cierra el diálogo
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.red[50], // Color de fondo
                    shape: RoundedRectangleBorder(
                        borderRadius:
                            BorderRadius.circular(10)), // Bordes redondeados
                    padding: const EdgeInsets.symmetric(
                        horizontal: 30, vertical: 20), // Padding
                  ),
                  child: const Text(
                    "Cancelar",
                    style: TextStyle(color: Colors.red), // Estilo del texto
                  ),
                ),
              ],
            )
          ],
        ),
      ),
    );
  }
}
