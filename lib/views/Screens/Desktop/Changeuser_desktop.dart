import 'dart:convert';
import 'dart:io';
import 'package:go_router/go_router.dart';
import 'package:http/http.dart' as http;
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:mcconnect/Decoraciones/decoracioninput.dart';
import 'package:mcconnect/Providers/listaempleados.dart';
import 'package:mcconnect/Providers/visibilidadusuarios.dart';
import 'package:mcconnect/views/Screens/Desktop/Contacto.dart';
import 'package:mcconnect/views/Screens/Desktop/Divisiones/divisiones.dart';
import 'package:mcconnect/views/Screens/Desktop/Divisiones/divisiones_backend.dart';
import 'package:mcconnect/views/Screens/Homescreen.dart';
import 'package:file_picker/file_picker.dart'; // Importa file_picker para Flutter Web
import 'package:http_parser/http_parser.dart';
import 'package:mcconnect/widgets/Botones/Botonesrectangulares.dart';
import 'package:mcconnect/widgets/Campos/campopersonalizado.dart';
import 'package:mcconnect/widgets/qrgenerator/generadorqr.dart';
import 'package:mime/mime.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:html' as html;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:screenshot/screenshot.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';

import 'package:url_launcher/url_launcher.dart';

// Enumeración para las opciones de encabezado
enum Opciones { departamento, posicion }

// Widget Stateful para cambiar datos de usuario en escritorio
class ChangeuserDesktop extends StatefulWidget {
  final Empleado empleado; // Objeto empleado con datos del usuario
  String? selectedDivisionId;
  final ValueChanged<bool>
      onSantiagoChanged; // Callback para cambios en Santiago

  ChangeuserDesktop({
    super.key,
    required this.empleado,
    required this.onSantiagoChanged,
  });

  late TextEditingController
      _direccionController; // Controlador para el campo de dirección

  @override
  ChangeuserDesktopState createState() => ChangeuserDesktopState();
}

// Clase para manejar imágenes de la compañía
class ImagenCompania {
  final String path; // Ruta de la imagen
  final double height; // Altura de la imagen
  final double width; // Ancho de la imagen
  final Color color1; // Primer color para el diseño
  final Color color2; // Segundo color para el diseño
  final double? contenedorheight; // Altura del contenedor
  final double? contenedorwidth; // Ancho del contenedor

  ImagenCompania({
    required this.path,
    required this.height,
    required this.width,
    required this.color1,
    required this.color2,
    this.contenedorheight,
    this.contenedorwidth,
  });
}

// Estado del widget ChangeuserDesktop
class ChangeuserDesktopState extends State<ChangeuserDesktop> {
  final Dio dio = Dio(); // Instancia única de Dio

  int? _value; // Valor seleccionado para el grupo
  String? _selectedDepartment; // Departamento seleccionado
  late bool _isChecked; // Estado del checkbox de ubicación en Santiago
  final Opciones _selectedOption =
      Opciones.departamento; // Opción seleccionada (departamento o posición)
  final GlobalKey qrGlobalKey = GlobalKey(); // Clave global para el QR

  static const double kFieldWidth = 250.0; // Ancho constante para campos
  static const EdgeInsets kFieldPadding =
      EdgeInsets.symmetric(vertical: 15.0); // Padding constante para campos
  late Empleado empleado; // Objeto empleado local

  final DivisionService divisionService =
      DivisionService(baseUrl: "http://localhost:4000");

  List<Division> divisiones = [];
  int? selectedDivisionId;
  String ubicacion = '';
  String web = '';
  String instagram = '';
  bool isLoadingDivisiones = true;

  final TextEditingController ubicacionController = TextEditingController();
  final TextEditingController webController = TextEditingController();
  late TextEditingController instagramController = TextEditingController();

  Uint8List? _webImage; // For storing image bytes on web
  File? _selectedImage;
  String? _uploadedImageUrl;

  // Controlador para el campo "Dirección"
  late TextEditingController _direccionController;
  ScreenshotController screenshotController =
      ScreenshotController(); // Controlador para capturar pantallas
  ScreenshotController qrScreenshotController =
      ScreenshotController(); // Controlador para capturar el QR

  @override
  void initState() {
    super.initState();
    empleado = widget.empleado; // Inicializar objeto empleado
    _value = empleado
        .id_division; // Asigna el tipo de empleado al valor seleccionado
    _selectedDepartment =
        empleado.departamento; // Asigna el departamento seleccionado
    selectedDivisionId = empleado.id_division;
    // Inicializa el controlador de texto con la ubicación actual
    instagramController = TextEditingController(text: empleado.instagram);
    _direccionController = TextEditingController(text: empleado.ubicacion);
    _fetchDivisiones();
  }

  @override
  void dispose() {
    _direccionController.dispose();
    ubicacionController.dispose();
    webController.dispose();
    instagramController.dispose();
    super.dispose();
  }

  Future<void> _fetchDivisiones() async {
    List<Division> fetchedDivisiones = await divisionService.getAllDivisiones();

    setState(() {
      divisiones = fetchedDivisiones;
      isLoadingDivisiones = false;

      // Una vez que las divisiones están cargadas, actualiza el nombre de la división
      if (selectedDivisionId != null) {
        final selectedDivision = divisiones.firstWhere(
          (d) => d.idDivision == selectedDivisionId,
          orElse: () => Division(idDivision: 0, division: ''),
        );
        empleado.division = selectedDivision.division;
      }
    });
  }

  // Método para descargar el código QR
  void _downloadQR() {
    String? url = empleado.qr_empleado;

    if (url == null || url.isEmpty) {
      print("La URL del código QR no está disponible.");
      return;
    }

    // Si la URL termina con 'blob', reemplazarlo por 'blob.png'
    if (url.endsWith('blob')) {
      url = url.replaceFirst(RegExp(r'blob$'), '.png');
    }
    // Si la URL no tiene una extensión, agregar '.png'
    else if (!url.contains('.')) {
      url = '$url.png';
    }

    // Genera un nombre de archivo basado en el nombre del empleado
    String fileName = '${empleado.nombre_empleado.replaceAll(' ', '_')}.png';

    // Crea un elemento de ancla para iniciar la descarga
    final anchor = html.AnchorElement(href: url)
      ..setAttribute('download', fileName)
      ..click();
  }

  // Método para obtener el texto del departamento en inglés basado en el valor seleccionado
  String obtenerTextoDepartamento(String? departamento) {
    switch (departamento) {
      case 'Operaciones':
        return 'Operations Department';
      case 'Ventas':
        return 'Sales Department';
      case 'Coordinación':
        return 'Coordination Department';
      case 'Aduanas':
        return 'Customs Department';
      case 'Cobros':
        return 'Créditos y Cobros';
      case 'Finanzas':
        return 'Finance Department';
      case 'Administración':
        return 'Administration Department';
      case 'Recursos Humanos':
        return 'Gestión de Talento Humano';
      case 'Servicio al cliente':
        return 'Customers Service';
      case 'Tecnología':
        return 'Technology Department';
      case 'Product Development':
        return 'Product Development';
      case 'Product Manager':
        return 'Product Manager';
      default:
        return 'Otro Departamento';
    }
  }

  // Método para obtener la imagen de la compañía basada en el tipo
  ImagenCompania obtenerImagenCompania(String? compania) {
    switch (compania) {
      case 'Figibox':
        return ImagenCompania(
          path: "../assets/Firma/figiboxSomos.jpeg",
          height: 50,
          width: 170,
          color1: const Color(0xFF77A4E8),
          color2: const Color(0xFF163977),
          // contenedorheight: 240,
          // contenedorwidth: 750
        );
      case 'MCLogistics':
        return ImagenCompania(
          path: "../assets/Firma/Mclogisticssomos.png",
          height: 120,
          width: 220,
          color1: const Color(0xFF8CC63F),
          color2: const Color(0xFF0071BC),
          // contenedorheight: 300,
          // contenedorwidth: 750
        );
      case 'ConsiliaLogistics':
        return ImagenCompania(
          path: "../assets/Firma/ConsiliaSomos.png",
          height: 140,
          width: 220,
          color1: const Color(0xFF2B388C),
          color2: const Color(0xFFA2C954),
          // contenedorheight: 300,
          // contenedorwidth: 750
        );
      case 'HighPerformance':
        return ImagenCompania(
          path: "../assets/Firma/highpSomos.png",
          height: 140,
          width: 200,
          color1: const Color(0xFF8CC63F),
          color2: const Color(0xFF0071BC),
          // contenedorheight: 300,
          // contenedorwidth: 750
        );

      case 'MCLogistics-Santiago':
        return ImagenCompania(
          path: "../assets/Firma/Mclogisticssomos.png",
          height: 120,
          width: 220,
          color1: const Color(0xFF8CC63F),
          color2: const Color(0xFF0071BC),
          // contenedorheight: 300,
          // contenedorwidth: 750
        );
      case 'Figibox-Santiago':
        return ImagenCompania(
          path: "../assets/Firma/figiboxSomos.jpeg",
          height: 50,
          width: 170,
          color1: const Color(0xFF77A4E8),
          color2: const Color(0xFF163977),
          // contenedorheight: 240,
          // contenedorwidth: 750
        );
      default:
        return ImagenCompania(
          path: "../assets/Firma/Mclogisticssomos.png",
          height: 120,
          width: 220,
          color1: const Color(0xFF8CC63F),
          color2: const Color(0xFF0071BC),
          // contenedorheight: 300,
          // contenedorwidth: 750
        );
    }
  }

  // Método para mostrar el diálogo de firma
  void mostrarDialogoFirma(BuildContext context) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          ImagenCompania imagenCompania =
              obtenerImagenCompania(widget.empleado.division);

          // Variable local para rastrear la opción seleccionada dentro del diálogo
          Opciones tempSelectedOption = _selectedOption;

          return StatefulBuilder(
            builder: (BuildContext context, StateSetter setState) {
              return Dialog(
                alignment: Alignment.topCenter,
                child: Padding(
                  padding: const EdgeInsets.all(30),
                  child: IntrinsicHeight(
                    child: SizedBox(
                      width: 800,
                      child: Column(
                        children: [
                          // Captura de pantalla para la firma
                          Screenshot(
                            controller: screenshotController,
                            child: IntrinsicHeight(
                              child: Container(
                                width: 750,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    left: BorderSide(
                                      width: 8,
                                      color: imagenCompania.color1,
                                    ),
                                  ),
                                ),
                                child: Container(
                                  width: double.infinity,
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border(
                                      left: BorderSide(
                                        width: 8,
                                        color: imagenCompania.color2,
                                      ),
                                    ),
                                  ),
                                  child: Column(
                                    children: [
                                      Expanded(
                                        child: Container(
                                          color: Colors.white,
                                          child: Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              Row(
                                                children: [
                                                  Stack(
                                                    children: [
                                                      ConstrainedBox(
                                                        constraints: BoxConstraints(
                                                          maxHeight: 280
                                                        ),
                                                        child: Image.asset(
                                                          "../assets/Firma/Background_firma.jpeg", // Asegúrate de que la ruta es correcta
                                                          width: 534,
                                                          fit: BoxFit.fill,
                                                        ),
                                                      ),
                                                      Row(
                                                        mainAxisAlignment:
                                                            MainAxisAlignment
                                                                .spaceBetween,
                                                        children: [
                                                          Padding(
                                                            padding:
                                                                const EdgeInsets
                                                                    .all(16.0),
                                                            child: Positioned(
                                                              child: Column(
                                                                crossAxisAlignment:
                                                                    CrossAxisAlignment
                                                                        .start,
                                                                children: [
                                                                  Row(
                                                                    children: [
                                                                      Positioned(
                                                                        top: 0,
                                                                        child:
                                                                            SizedBox(
                                                                          width:
                                                                              180,
                                                                          child:
                                                                              Text(
                                                                            widget.empleado.nombre_empleado,
                                                                            style:
                                                                                const TextStyle(
                                                                              fontWeight: FontWeight.bold,
                                                                              fontSize: 20,
                                                                            ),
                                                                          ),
                                                                        ),
                                                                      ),
                                                                    ],
                                                                  ),
                                                                  // Actualización del texto del departamento/posición
                                                                  Positioned(
                                                                    top: 0,
                                                                    left: 0,
                                                                    child:
                                                                        SizedBox(
                                                                      width:
                                                                          200,
                                                                      child:
                                                                          Text(
                                                                        tempSelectedOption ==
                                                                                Opciones.departamento
                                                                            ? obtenerTextoDepartamento(widget.empleado.departamento)
                                                                            : widget.empleado.posicion_empleado ?? "",
                                                                        style:
                                                                            const TextStyle(
                                                                          fontWeight:
                                                                              FontWeight.bold,
                                                                          color: Color.fromARGB(
                                                                              255,
                                                                              91,
                                                                              91,
                                                                              91),
                                                                        ),
                                                                      ),
                                                                    ),
                                                                  ),
                                                                  const SizedBox(
                                                                      height:
                                                                          15),
                                                                           Row(
                                                                      children: [
                                                                        const FaIcon(
                                                                          FontAwesomeIcons.envelope,
                                                                          size:
                                                                              15,
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                5),
                                                                        Text(
                                                                          widget.empleado.correo_empleado ??
                                                                              "",
                                                                          style:
                                                                              const TextStyle(),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                    const SizedBox(
                                                                      height:
                                                                          5),
                                                                  // Mostrar teléfono y extensión si están disponibles
                                                                  if ((widget.empleado.telefono_empleado !=
                                                                              null &&
                                                                          widget
                                                                              .empleado
                                                                              .telefono_empleado!
                                                                              .isNotEmpty) &&
                                                                      (widget.empleado.extension_empleado !=
                                                                              null &&
                                                                          widget.empleado.telefono_empleado !=
                                                                              null &&
                                                                          widget
                                                                              .empleado
                                                                              .telefono_empleado!
                                                                              .isNotEmpty))
                                                                    Row(
                                                                      children: [
                                                                        const FaIcon(
                                                                          FontAwesomeIcons
                                                                              .phone,
                                                                          size:
                                                                              15,
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                5),
                                                                        Text(
                                                                          widget.empleado.telefono_empleado ??
                                                                              "",
                                                                          style:
                                                                              const TextStyle(),
                                                                        ),
                                                                        Text(
                                                                          ", Ext${widget.empleado.extension_empleado ?? ""}",
                                                                          style:
                                                                              const TextStyle(),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  const SizedBox(
                                                                      height:
                                                                          5),
                                                                  // Mostrar WhatsApp si está disponible
                                                                  if (widget.empleado
                                                                              .flota_empleado !=
                                                                          null &&
                                                                      widget
                                                                          .empleado
                                                                          .flota_empleado!
                                                                          .isNotEmpty)
                                                                    Row(
                                                                      children: [
                                                                        const FaIcon(
                                                                          FontAwesomeIcons
                                                                              .whatsapp,
                                                                          size:
                                                                              15,
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                5),
                                                                        Text(
                                                                          widget.empleado.flota_empleado ??
                                                                              "",
                                                                          style:
                                                                              const TextStyle(),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  const SizedBox(
                                                                      height:
                                                                          5),
                                                                  // Mostrar sitio web si está disponible
                                                                  if (widget.empleado
                                                                              .web !=
                                                                          null &&
                                                                      widget
                                                                          .empleado
                                                                          .web!
                                                                          .isNotEmpty)
                                                                    Row(
                                                                      children: [
                                                                        const FaIcon(
                                                                          FontAwesomeIcons
                                                                              .globe,
                                                                          size:
                                                                              15,
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                5),
                                                                        Text(
                                                                          widget.empleado.web ??
                                                                              "",
                                                                          style:
                                                                              const TextStyle(),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                  const SizedBox(
                                                                      height:
                                                                          5),
                                                                  // Mostrar ubicación si está disponible
                                                                  if (widget.empleado
                                                                              .ubicacion !=
                                                                          null &&
                                                                      widget
                                                                          .empleado
                                                                          .ubicacion!
                                                                          .isNotEmpty)
                                                                    Row(
                                                                      children: [
                                                                        const FaIcon(
                                                                          FontAwesomeIcons
                                                                              .locationDot,
                                                                          size:
                                                                              20,
                                                                        ),
                                                                        const SizedBox(
                                                                            width:
                                                                                5),
                                                                        SizedBox(
                                                                          width:
                                                                              200,
                                                                          child:
                                                                              Text(
                                                                            widget.empleado.ubicacion ??
                                                                                "",
                                                                            style:
                                                                                const TextStyle(fontSize: 12),
                                                                          ),
                                                                        ),
                                                                      ],
                                                                    ),
                                                                ],
                                                              ),
                                                            ),
                                                          ),
                                                          const SizedBox(
                                                              width: 40),
                                                          // Imagen de la compañía
                                                          Image.asset(
                                                            imagenCompania.path,
                                                            height:
                                                                imagenCompania
                                                                    .height,
                                                            width:
                                                                imagenCompania
                                                                    .width,
                                                            fit: BoxFit.fill,
                                                          ),
                                                        ],
                                                      ),
                                                    ],
                                                  ),
                                                ],
                                              ),
                                              // Sección del QR
                                              Container(
                                                alignment: Alignment.center,
                                                height: 280,
                                                width: 200,
                                                decoration: const BoxDecoration(
                                                  color: Color.fromARGB(255, 244, 240, 240),
                                                ),
                                                child: Column(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment.center,
                                                  children: [
                                                    Visibility(
                                                      visible: true,
                                                      maintainState: true,
                                                      child: Screenshot(
                                                        controller:
                                                            qrScreenshotController,
                                                        child: QrGenerator(
                                                          empleado: empleado,
                                                          size: 170,
                                                        ),
                                                      ),
                                                    ),
                                                    const SizedBox(height: 1),
                                                    const Text(
                                                      "Contáctame",
                                                      style: TextStyle(
                                                          color: Colors.grey),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                      // Sección inferior del diálogo, si el tipo de empleado no es 'ASW'
                                      empleado.division != "Figibox" &&
                                              empleado.division !=
                                                  "Figibox-Santiago"
                                          ? Container(
                                              height: 50,
                                              color: const Color.fromARGB(
                                                  255, 228, 228, 228),
                                              child: Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 16.0),
                                                child: Row(
                                                  mainAxisAlignment:
                                                      MainAxisAlignment
                                                          .spaceBetween,
                                                  children: [
                                                    Row(
                                                      mainAxisAlignment:
                                                          MainAxisAlignment
                                                              .center,
                                                      children: [
                                                        const Text(
                                                          "Certified by",
                                                          style: TextStyle(
                                                              color:
                                                                  Colors.grey),
                                                        ),
                                                        const SizedBox(
                                                            width: 5),
                                                        // Imagen de certificación BASC
                                                        Image.asset(
                                                          "../assets/Firma/BASC.png", // Asegúrate de que la ruta es correcta
                                                          height: 40,
                                                          width: 40,
                                                        ),
                                                        const SizedBox(
                                                            width: 10),
                                                        Padding(
                                                          padding:
                                                              const EdgeInsets
                                                                  .only(
                                                                  top: 8.0),
                                                          child: Image.asset(
                                                            "../assets/Firma/OEA.png", // Asegúrate de que la ruta es correcta
                                                            height: 60,
                                                            width: 60,
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                                    // Si el tipo es 'McLogs', mostrar miembros adicionales
                                                    empleado.division ==
                                                            'MCLogistics'
                                                        ? Row(
                                                            children: [
                                                              const Text(
                                                                "Members",
                                                                style: TextStyle(
                                                                    color: Colors
                                                                        .grey),
                                                              ),
                                                              Image.asset(
                                                                "../assets/Firma/ADAA.png",
                                                                height: 70,
                                                                width: 60,
                                                              ),
                                                              const SizedBox(
                                                                  width: 5),
                                                              Image.asset(
                                                                "../assets/Firma/ASODEC.png",
                                                                height: 80,
                                                                width: 80,
                                                              ),
                                                              const SizedBox(
                                                                  width: 10),
                                                              Image.asset(
                                                                "../assets/Firma/Adacam.png",
                                                                height: 60,
                                                                width: 60,
                                                              ),
                                                            ],
                                                          )
                                                        : const SizedBox
                                                            .shrink(), // Si no, no mostrar nada
                                                  ],
                                                ),
                                              ),
                                            )
                                          : const SizedBox.shrink(),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 40),
                          // Sección de Radio Buttons para ajustes de encabezado
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 18.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.start,
                              crossAxisAlignment: CrossAxisAlignment
                                  .start, // Alinea el texto a la izquierda
                              children: [
                                Text(
                                  "Ajustes de encabezado",
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Radio Buttons para seleccionar entre departamento o posición
                          Column(
                            children: [
                              ListTile(
                                title: const Text("Departamento"),
                                leading: Radio<Opciones>(
                                  value: Opciones.departamento,
                                  groupValue: tempSelectedOption,
                                  fillColor: const WidgetStatePropertyAll(
                                      Color(0xFF8CC63F)),
                                  onChanged: (Opciones? value) {
                                    setState(() {
                                      tempSelectedOption = value!;
                                    });
                                  },
                                ),
                              ),
                              ListTile(
                                title: const Text("Posición"),
                                leading: Radio<Opciones>(
                                  value: Opciones.posicion,
                                  groupValue: tempSelectedOption,
                                  fillColor: const WidgetStatePropertyAll(
                                      Color(0xFF8CC63F)),
                                  onChanged: (Opciones? value) {
                                    setState(() {
                                      tempSelectedOption = value!;
                                    });
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 30),
                          // Botones para descargar o cancelar el diálogo de firma
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 18),
                            child: Row(
                              children: [
                                CustomButton(
                                  text: "Descargar",
                                  color: Colors.green[50],
                                  textColor: Colors.green,
                                  onPressed: () async {
                                    // Captura el widget como una imagen PNG
                                    final image =
                                        await screenshotController.capture();

                                    if (image != null) {
                                      // Crea un Blob con el tipo MIME correcto
                                      final blob =
                                          html.Blob([image], 'image/png');
                                      // Genera una URL de objeto a partir del Blob
                                      final url =
                                          html.Url.createObjectUrlFromBlob(
                                              blob);
                                      // Crea un elemento de ancla y establece el atributo de descarga
                                      final anchor =
                                          html.AnchorElement(href: url)
                                            ..download = 'screenshot.png'
                                            ..style.display = 'none';
                                      // Añade el ancla al DOM
                                      html.document.body?.append(anchor);
                                      // Dispara un clic en el elemento de ancla
                                      anchor.click();
                                      // Remueve el ancla del DOM
                                      anchor.remove();
                                      // Revoca la URL de objeto para liberar recursos
                                      html.Url.revokeObjectUrl(url);
                                    }
                                  },
                                ),
                                const SizedBox(width: 10),
                                CustomButton(
                                    text: "Cancelar",
                                    textColor: Colors.red,
                                    color: Colors.red[50],
                                    onPressed: () {
                                      Navigator.of(context)
                                          .pop(); // Cierra el diálogo
                                    }),
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        });
  }

  // Método para seleccionar y subir una imagen
  Future<void> _pickAndUploadImage() async {
    // Utiliza file_picker para seleccionar archivos
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png'], // Extensiones permitidas
      withData: kIsWeb, // Para obtener bytes en Web
    );

    if (result != null) {
      PlatformFile file = result.files.first;

      setState(() {
        if (kIsWeb) {
          _webImage = file.bytes;
          _selectedImage = null; // Asegura que solo uno esté seleccionado
        } else {
          _selectedImage = File(file.path!);
          _webImage = null;
        }
      });

      // Muestra un indicador de carga mientras se sube la imagen
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      try {
        MultipartFile multipartFile;

        if (kIsWeb) {
          // Obtiene el tipo MIME del archivo
          String? mimeType = lookupMimeType(file.name);
          mimeType ??= 'application/octet-stream';
          MediaType mediaType = MediaType.parse(mimeType);

          // Para Flutter Web, usa fromBytes
          multipartFile = MultipartFile.fromBytes(
            file.bytes!,
            filename: file.name,
            contentType: mediaType,
          );
        } else {
          // Para plataformas móviles, usa fromFile
          multipartFile = await MultipartFile.fromFile(
            file.path!,
            filename: file.name,
          );
        }

        // Crea los datos del formulario para la subida
        FormData formData = FormData.fromMap({
          'file': multipartFile,
        });

        // Realiza la petición POST para subir la imagen
        Response response = await dio.post(
          'http://localhost:4000/api/upload-image', // Asegúrate de que esta URL sea correcta
          data: formData,
          options: Options(
            contentType: 'multipart/form-data',
          ),
        );

        // Cierra el indicador de carga
        Navigator.of(context).pop();

        if (response.statusCode == 200 || response.statusCode == 201) {
          // Obtiene 'name_saved' desde la respuesta
          String nameSaved = response.data['name_saved'];

          // Construye la URL completa de la imagen
          String imageUrl = 'http://192.168.67.208:4000/public/$nameSaved';

          setState(() {
            _uploadedImageUrl = imageUrl; // Almacena la URL de la imagen subida
            empleado.imagen_empleado =
                imageUrl; // Actualiza la imagen del empleado
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Imagen subida correctamente')),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content:
                    Text('Error al subir la imagen: ${response.statusCode}')),
          );
        }
      } catch (e) {
        // Cierra el indicador de carga en caso de error
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al subir la imagen: $e')),
        );
      }
    }
  }

  void _MostrarContactoURL(BuildContext context) async {
    final Uri url =
        Uri.parse('http://localhost:4000/contacto/${empleado.nombre_empleado}');

    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir la página de contacto')),
      );
    }
  }

  // Método para enviar los datos del usuario al servidor
  Future<void> postUserData() async {
    try {
      var uri = Uri.parse(
          'http://localhost:4000/api/actualizarempleado/${empleado.id_empleado}');

      var request = http.Request('PUT', uri);
      request.headers.addAll({'Content-Type': 'application/json'});
      request.body = jsonEncode(empleado.toJson());

      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        print('Datos enviados correctamente');
        final Map<String, dynamic> responseData = jsonDecode(response.body);

        if (responseData.containsKey('empleado')) {
          setState(() {
            empleado = Empleado.fromJson(responseData['empleado']);
          });
        } else {
          print("La respuesta no contiene 'empleado'");
        }
      } else {
        print(
            "Error al enviar los datos. Código de estado: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content:
                  Text('Error al enviar los datos: ${response.statusCode}')),
        );
      }
    } catch (e) {
      print("Error al enviar los datos: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al enviar los datos: $e')),
      );
    }
  }

  // Widget que construye los campos del formulario
  Widget buildFormFields() {
    return Wrap(
      spacing: 20, // Espacio horizontal entre widgets
      runSpacing: 20, // Espacio vertical entre líneas de widgets
      alignment: WrapAlignment.start, // Alineación de los widgets
      children: [
        Column(
          children: [
            // Imagen del usuario con funcionalidad para seleccionar y subir una nueva imagen
            GestureDetector(
              onTap:
                  _pickAndUploadImage, // Maneja el evento de toque para seleccionar una imagen
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                    100), // Hace que la imagen tenga bordes circulares
                child: empleado.imagen_empleado != null
                    ? Image.network(
                        empleado.imagen_empleado!,
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                        loadingBuilder: (BuildContext context, Widget child,
                            ImageChunkEvent? loadingProgress) {
                          if (loadingProgress == null) return child;
                          return Center(
                            child: CircularProgressIndicator(
                              value: loadingProgress.expectedTotalBytes != null
                                  ? loadingProgress.cumulativeBytesLoaded /
                                      (loadingProgress.expectedTotalBytes ?? 1)
                                  : null,
                            ),
                          );
                        },
                        errorBuilder: (BuildContext context, Object exception,
                            StackTrace? stackTrace) {
                          return Image.asset(
                            "../assets/Icons/UserIcon.png",
                            width: 200,
                            height: 200,
                            fit: BoxFit.cover,
                          );
                        },
                      )
                    : Image.asset(
                        "../assets/Icons/UserIcon.png",
                        width: 200,
                        height: 200,
                        fit: BoxFit.cover,
                      ),
              ),
            ),
            const SizedBox(height: 25),
            // Campo de texto para el nombre
            CustomTextFormField(
              initialValue: empleado.nombre_empleado,
              labelText: "Nombre",
              onChange: (v) {
                setState(() {
                  empleado.nombre_empleado = v;
                });
              },
            ),
            const SizedBox(height: 25),
            // Campo de texto para el correo electrónico
            CustomTextFormField(
              initialValue: empleado.correo_empleado,
              labelText: "Correo electrónico",
              onChange: (v) {
                setState(() {
                  empleado.correo_empleado = v;
                });
              },
            ),
            const SizedBox(height: 25),
            // Campos para teléfono y extensión
            SizedBox(
                width: 250,
                height: 45,
                child: Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        initialValue: empleado.telefono_empleado,
                        onChanged: (v) {
                          setState(() {
                            empleado.telefono_empleado = v;
                          });
                        },
                        decoration: InputDecoration(
                          label: const Text("Teléfono"),

                          labelStyle: const TextStyle(
                              color: Colors.grey), // Estilo de la etiqueta
                          floatingLabelStyle: const TextStyle(
                              color: Colors
                                  .black), // Estilo de la etiqueta al flotar
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10), // Bordes redondeados
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10), // Bordes redondeados
                            borderSide: const BorderSide(
                                color: Colors.grey,
                                width: 1.0), // Color y ancho del borde
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10), // Bordes redondeados
                            borderSide: const BorderSide(
                                color: Color(0xFF17A2B8),
                                width:
                                    2.0), // Color y ancho del borde al enfocar
                          ),
                        ),
                        cursorColor: Colors.black,
                      ),
                    ),
                    const SizedBox(width: 10),
                    SizedBox(
                      width: 70,
                      height: 45,
                      child: TextFormField(
                        initialValue: empleado.extension_empleado,
                        onChanged: (v) {
                          setState(() {
                            empleado.extension_empleado = v;
                          });
                        },
                        decoration: InputDecoration(
                          label: const Text("Ext"),
                          labelStyle: const TextStyle(
                              color: Colors.grey), // Estilo de la etiqueta
                          floatingLabelStyle: const TextStyle(
                              color: Colors
                                  .black), // Estilo de la etiqueta al flotar
                          border: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10), // Bordes redondeados
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10), // Bordes redondeados
                            borderSide: const BorderSide(
                                color: Colors.grey,
                                width: 1.0), // Color y ancho del borde
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius:
                                BorderRadius.circular(10), // Bordes redondeados
                            borderSide: const BorderSide(
                                color: Color(0xFF17A2B8),
                                width:
                                    2.0), // Color y ancho del borde al enfocar
                          ),
                        ),
                        cursorColor: Colors.black,
                      ),
                    ),
                  ],
                )),
            const SizedBox(height: 25),
            // Campo de texto para WhatsApp o flota
            CustomTextFormField(
              initialValue: empleado.flota_empleado,
              labelText: "Flota/Whatsapp",
              onChange: (v) {
                setState(() {
                  empleado.flota_empleado = v;
                });
              },
            ),
          ],
        ),
        Column(
          children: [
            // Campo de texto para Instagram
            empleado.division != "ConsiliaLogistics" &&
                    empleado.division != "HighPerformance"
                ? CustomTextFormField(
                    controller: instagramController, // Corregido
                    readOnly: true,
                    labelText: "Instagram",
                    onChange: (v) {
                      setState(() {
                        empleado.instagram = v;
                      });
                    },
                  )
                : const SizedBox.shrink(),
            const SizedBox(height: 25),
            // Dropdown para seleccionar el grupo (tipo de compañía)
            SizedBox(
              width: kFieldWidth,
              child: isLoadingDivisiones
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<int>(
                      decoration: customInputDecoration(labelText: "División"),
                      value: selectedDivisionId,
                      hint: const Text("Seleccione una División"),
                      items: divisiones.map((Division division) {
                        return DropdownMenuItem<int>(
                          value: division.idDivision,
                          child: Text(division.division),
                        );
                      }).toList(),
                      onChanged: (newValue) async {
                        if (newValue == null) return;

                        setState(() {
                          selectedDivisionId = newValue;
                          empleado.id_division =
                              newValue; // Actualiza el ID de la división en empleado

                          // Obtiene el nombre de la división seleccionada
                          final selectedDivision = divisiones.firstWhere(
                              (d) => d.idDivision == newValue,
                              orElse: () =>
                                  Division(idDivision: 0, division: ''));
                          empleado.division = selectedDivision.division;

                          // Restablece otros campos relacionados si es necesario
                          ubicacion = '';
                          web = '';
                          instagram = '';
                          _direccionController.text = '';
                          ubicacionController.text = '';
                          webController.text = '';
                          instagramController.text = '';
                        });

                        // Obtener los detalles de la división seleccionada
                        Map<String, dynamic>? divisionDetails =
                            await divisionService
                                .getDivisionDetails(newValue.toString());

                        if (divisionDetails != null) {
                          setState(() {
                            ubicacion = divisionDetails['ubicacion'] ?? '';
                            web = divisionDetails['web'] ?? '';
                            instagram = divisionDetails['instagram'] ?? '';
                            _direccionController.text = ubicacion;
                            ubicacionController.text = ubicacion;
                            webController.text = web;
                            instagramController.text = instagram;
                          });
                        } else {
                          // Manejar el error, por ejemplo, mostrar un SnackBar
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                                content: Text(
                                    'No se pudieron cargar los detalles de la división')),
                          );
                        }
                      },
                      validator: (value) {
                        if (value == null) {
                          return 'Por favor, selecciona una división';
                        }
                        return null;
                      },
                    ),
            ),

            const SizedBox(height: 25),
            // Dropdown para seleccionar el departamento
            SizedBox(
              width: kFieldWidth,
              child: DropdownButtonFormField<String>(
                onChanged: (String? newValue) {
                  setState(() {
                    _selectedDepartment = newValue;
                    empleado.departamento = newValue;
                  });
                },
                value: _selectedDepartment,
                decoration: customInputDecoration(labelText: "Departamento"),
                hint: const Text("Seleccione un departamento"),
                isExpanded: true,
                items: const [
                  DropdownMenuItem(value: "Ventas", child: Text("Ventas")),
                  DropdownMenuItem(
                      value: "Operaciones", child: Text("Operaciones")),
                  DropdownMenuItem(
                      value: "Coordinación", child: Text("Coordinación")),
                  DropdownMenuItem(value: "Aduanas", child: Text("Aduanas")),
                  DropdownMenuItem(
                      value: "Créditos y Cobros",
                      child: Text("Créditos y Cobros")),
                  DropdownMenuItem(value: "Finanzas", child: Text("Finanzas")),
                  DropdownMenuItem(
                      value: "Administración", child: Text("Administración")),
                  DropdownMenuItem(
                      value: "Recursos Humano", child: Text("Recursos Humano")),
                  DropdownMenuItem(
                      value: "Servicio al cliente",
                      child: Text("Servicio al cliente")),
                  DropdownMenuItem(
                      value: "Tecnología", child: Text("Tecnología")),
                  DropdownMenuItem(
                      value: "Product Development",
                      child: Text("Product Development")),
                  DropdownMenuItem(
                      value: "Product Manager", child: Text("Product Manager")),
                ],
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor, selecciona un departamento';
                  }
                  return null;
                },
              ),
            ),
            const SizedBox(height: 25),
            // Campo de texto para la posición
            CustomTextFormField(
              initialValue: empleado.posicion_empleado,
              labelText: "Posición",
              onChange: (v) {
                setState(() {
                  empleado.posicion_empleado = v;
                });
              },
            ),
            const SizedBox(height: 25),
            // Campo de texto para la dirección, solo lectura
            SizedBox(
              width: kFieldWidth,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CustomTextFormField(
                    controller: _direccionController,
                    labelText: "Dirección",
                    readOnly: true,
                  ),
                  // Checkbox para ubicar en Santiago si el tipo es "McLogs"
                ],
              ),
            ),
            const SizedBox(height: 15),
            // Botón para abrir el enlace de contacto
            SizedBox(
                height: 45,
                width: 250,
                child: TextButton(
                  onPressed: () => _MostrarContactoURL(context),
                  style: TextButton.styleFrom(
                    backgroundColor:
                        Colors.green[50], // Cambia el color de fondo
                    shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(10), // Bordes redondeados
                    ),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize
                        .min, // Ajusta el tamaño del botón al contenido
                    children: [
                      Icon(Icons.link, color: Colors.green), // Ícono
                      SizedBox(width: 8), // Espacio entre el ícono y el texto
                      Text('Link de Contacto',
                          style: TextStyle(color: Colors.green)), // Texto
                    ],
                  ),
                )),
          ],
        ),
      ],
    );
  }

  // Widget que construye los botones de acción
  Widget buildButtons() {
    final visibilidadusuario =
        Provider.of<Visibilidadusuarios>(context, listen: false);
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Wrap(
        runSpacing: 10, // Espacio vertical entre botones
        spacing: 10, // Espacio horizontal entre botones
        alignment: WrapAlignment.spaceEvenly, // Alineación de los botones
        children: [
          // Botón para guardar los datos
          CustomButton(
            textColor: Colors.white,
            text: visibilidadusuario.mostrarUsuariosInactivos
                ? "Reactivar"
                : "Guardar",
            color: const Color(0xFF4CAF50),
            onPressed: () async {
              setState(() {
                empleado.estado = "Activo"; // Marca al empleado como inactivo
              });
              await postUserData(); // Envía los datos al servidor
              if (mounted) {
                Navigator.of(context)
                    .pop(true); // Cierra el diálogo y retorna true
              }
            },
          ),
          // Botón para eliminar al usuario (marcar como inactivo)
          if (visibilidadusuario.mostrarUsuariosInactivos == false) ...[
            CustomButton(
              textColor: Colors.white,
              text: "Desactivar",
              color: const Color(0xFFFF5252),
              onPressed: () async {
                setState(() {
                  empleado.estado =
                      "Inactivo"; // Marca al empleado como inactivo
                });

                await postUserData(); // Envía los cambios al servidor

                if (mounted) {
                  Navigator.of(context)
                      .pop(true); // Cierra el diálogo y retorna true
                }
              },
            ),
            // Botón para mostrar el diálogo del QR
            CustomButton(
              textColor: Colors.white,
              text: "QR",
              color: const Color(0xFF17A2B8),
              onPressed: () {
                showDialog(
                    context: context,
                    builder: (BuildContext context) {
                      return (QRDialog(
                          empleado: empleado)); // Muestra el diálogo del QR
                    });
              },
            ),
            // Botón para mostrar el diálogo de firma
            CustomButton(
              textColor: Colors.white,
              text: "Firma",
              color: const Color(0xFF17A2B8),
              onPressed: () {
                mostrarDialogoFirma(
                    context); // Llama al método para mostrar el diálogo de firma
              },
            ),
            // Botón para cancelar y cerrar el diálogo
          ],
          CustomButton(
            text: "Cancelar",
            textColor: Colors.white,
            color: const Color(0xFF9E9E9E),
            onPressed: () {
              Navigator.of(context).pop(); // Cierra el diálogo
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    String divisionName = '';

    if (selectedDivisionId != null) {
      final selectedDivision = divisiones.firstWhere(
        (d) => d.idDivision == selectedDivisionId,
        orElse: () => Division(idDivision: 0, division: ''),
      );
      divisionName = selectedDivision.division;
    }

    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(10),
      ),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 600, // Ancho del diálogo
          maxHeight: MediaQuery.of(context).size.height *
              0.9, // Altura máxima del 80% de la pantalla
        ),
        child: Column(
          mainAxisSize: MainAxisSize
              .min, // Ajusta el tamaño del Column al contenido mínimo
          children: [
            // Encabezado del diálogo
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Editar Usuario",
                    style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    divisionName.isNotEmpty
                        ? divisionName
                        : "", // Muestra el tipo de empleado o "Figibox" si es "ASW"
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
            // Formulario con scroll para los campos
            Flexible(
              fit: FlexFit.loose,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20.0),
                child: buildFormFields(), // Construye los campos del formulario
              ),
            ),
            // Botones al final del diálogo
            Padding(
              padding: const EdgeInsets.all(10.0),
              child: buildButtons(), // Construye los botones de acción
            ),
          ],
        ),
      ),
    );
  }
}
