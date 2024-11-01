import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mcconnect/Providers/listaempleados.dart';
import 'package:mcconnect/widgets/qrgenerator/generadorqr.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class Obtenerlogo {
  final String path;
  final double height;
  final double width;
  final Color color1;
  final Color color2;
  final Color color3;
  final Color color4;
  final Color colordeboton;

  Obtenerlogo(
      {required this.path,
      required this.height,
      required this.width,
      required this.color1,
      required this.color2,
      required this.color3,
      required this.color4,
      required this.colordeboton});
}

class Contacto extends StatefulWidget {
  final Empleado empleado;
  const Contacto({super.key, required this.empleado});

  @override
  State<Contacto> createState() => _ContactoState();
}

class _ContactoState extends State<Contacto> {
  late Empleado empleado;

  @override
  void initState() {
    super.initState();
    empleado = widget.empleado;
  }

  Obtenerlogo obtenerlogo(String? compania) {
    switch (compania) {
      case "Figibox":
        return Obtenerlogo(
            path: '../assets/Firma/figiboxSomos.jpeg',
            height: 40,
            width: 160,
            color1: const Color(0xFF083B8E),
            color2: const Color(0xFF05265B),
            color3: const Color(0xFF041B42),
            color4: const Color(0xFF021128),
            colordeboton: const Color(0xFF083B8E));
      case "MCLogistics":
        return Obtenerlogo(
            path: '../assets/Logo/logo2.png',
            height: 40,
            width: 160,
            color1: const Color(0xFF17A2B8),
            color2: const Color(0xFF117585),
            color3: const Color(0xFF0A4852),
            color4: const Color(0xFF0A4852),
            colordeboton: const Color(0xFF17A2B8));
      case "ConsiliaLogistics":
        return Obtenerlogo(
            path: '../assets/Logo/Concilialogo.png',
            height: 60,
            width: 60,
            color1: const Color(0xFF47601D),
            color2: const Color(0xFF6D932C),
            color3: const Color(0xFF80AD33),
            color4: const Color(0xFF93C63B),
            colordeboton: const Color(0xFF93C63B));
      case "HighPerformance":
        return Obtenerlogo(
            path: '../assets/Logo/high-performance.png',
            height: 80,
            width: 80,
            color1: const Color(0xFF093859),
            color2: const Color(0xFF0F598C),
            color3: const Color(0xFF47886C),
            color4: const Color(0xFF7FB74B),
            colordeboton: const Color(0xFF083B8E));
      case "MCLogistics-Santiago":
        return Obtenerlogo(
            path: '../assets/Logo/logo2.png',
            height: 40,
            width: 160,
            color1: const Color(0xFF17A2B8),
            color2: const Color(0xFF117585),
            color3: const Color(0xFF0A4852),
            color4: const Color(0xFF0A4852),
            colordeboton: const Color(0xFF17A2B8));
      default:
        return Obtenerlogo(
            path: '../assets/Logo/logo2.png', // Ruta por defecto
            height: 40,
            width: 160,
            color1: const Color(0xFF17A2B8),
            color2: const Color(0xFF117585),
            color3: const Color(0xFF0A4852),
            color4: const Color(0xFF0A4852),
            colordeboton: const Color(0xFF17A2B8));
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Map<String, dynamic>> obtenerDatosConIconos() {
      // Funciones auxiliares para construir las URLs
      String? construirTelUrl(String? telefono) {
        if (telefono == null || telefono.isEmpty) return null;
        // Asegúrate de que el teléfono esté en formato internacional
        // Ejemplo: +1234567890
        return 'tel:$telefono';
      }

      String? construirWhatsappUrl(String? whatsapp) {
        if (whatsapp == null || whatsapp.isEmpty) return null;
        // Quita símbolos como espacios, guiones, etc.
        String numero = whatsapp.replaceAll(RegExp(r'\D'), '');
        return 'https://wa.me/$numero';
      }

      String? construirCorreoUrl(String? correo) {
        if (correo == null || correo.isEmpty) return null;
        return 'mailto:$correo';
      }

      String? construirUbicacionUrl(String? ubicacion) {
        if (ubicacion == null || ubicacion.isEmpty) return null;
        // Puedes usar Google Maps para direcciones
        // Reemplaza espacios con '+'
        String direccion = Uri.encodeComponent(ubicacion);
        return 'https://www.google.com/maps/search/?api=1&query=$direccion';
      }

      String? construirWebUrl(String? web) {
        if (web == null || web.isEmpty) return null;
        if (!web.startsWith('http://') && !web.startsWith('https://')) {
          return 'https://$web';
        }
        return web;
      }

      return [
        {
          'link': construirTelUrl(empleado.telefono_empleado),
          'icon': Icons.phone,
          'encabezado': "Teléfono"
        },
        {
          'link': construirWhatsappUrl(empleado.flota_empleado),
          'icon': FontAwesomeIcons.whatsapp,
          'encabezado': "WhatsApp"
        },
        {
          'link': construirCorreoUrl(empleado.correo_empleado),
          'icon': Icons.mail_outline,
          'encabezado': "Correo"
        },
        {
          'link': construirUbicacionUrl(empleado.ubicacion),
          'icon': Icons.location_pin,
          'encabezado': "Ubicación"
        },
        {
          'link': construirWebUrl(empleado.web),
          'icon': Icons.web,
          'encabezado': "Página Web"
        }
      ];
    }

    Obtenerlogo empleadologo = obtenerlogo(empleado.division ?? 'default');

    List<Map<String, dynamic>> datosConIconos = obtenerDatosConIconos()
        .where((element) => element['link'] != null && element['link'] != "")
        .toList();

    return Scaffold(
      body: LayoutBuilder(
        builder: (BuildContext context, BoxConstraints constraints) {
          double breakpoint = 600;
          bool pantallapequena = constraints.maxWidth < breakpoint;

          return SingleChildScrollView(
            child: Center(
              child: Column(
                children: [
                  Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 1000),
                        child: Container(
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              gradient: LinearGradient(colors: [
                                empleadologo.color1,
                                empleadologo.color2,
                                empleadologo.color3,
                                empleadologo.color4,
                              ])),
                          child: Column(
                            children: [
                              Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    IconButton(
                                      onPressed: () {
                                        showDialog(
                                            context: context,
                                            builder: (BuildContext context) {
                                              return (QRDialog(
                                                  empleado:
                                                      empleado)); // Muestra el diálogo del QR
                                            });
                                      },
                                      icon: const Icon(
                                        Icons.qr_code_2_outlined,
                                        color: Colors.white,
                                        size: 30,
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        borderRadius: BorderRadius.circular(10),
                                        color: Colors.white,
                                      ),
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Image.asset(
                                          empleadologo.path,
                                          height: empleadologo.height,
                                          width: empleadologo.width,
                                          fit: BoxFit.contain,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      onPressed: () {

                                        Share.share('Hello Welcome to FlutterCampus', subject: 'Welcome Message');
                                        // String url =
                                        //     "http://192.168.67.208:8080/#/contacto/${Uri.encodeComponent(empleado.nombre_empleado)}";
                                        // // Usar Share.share para compartir el enlace
                                        // Share.share(
                                        //   'Visita el perfil de ${empleado.nombre_empleado}',
                                        //   subject:
                                        //       'Perfil de ${empleado.nombre_empleado}',
                                        // );
                                      },
                                      icon: const Icon(
                                        Icons.share_outlined,
                                        color: Colors.white,
                                        size: 25,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 50),
                              Center(
                                child: pantallapequena
                                    ? Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(100),
                                            child: empleado.imagen_empleado !=
                                                    null
                                                ? Image.network(
                                                    empleado.imagen_empleado!,
                                                    width: 150,
                                                    height: 150,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (BuildContext
                                                            context,
                                                        Widget child,
                                                        ImageChunkEvent?
                                                            loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) {
                                                        return child;
                                                      }
                                                      return Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          value: loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  (loadingProgress
                                                                          .expectedTotalBytes ??
                                                                      1)
                                                              : null,
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder:
                                                        (BuildContext context,
                                                            Object exception,
                                                            StackTrace?
                                                                stackTrace) {
                                                      return Image.asset(
                                                        "../assets/Icons/UserIcon.png",
                                                        width: 150,
                                                        height: 150,
                                                        fit: BoxFit.cover,
                                                      );
                                                    },
                                                  )
                                                : Image.asset(
                                                    "../assets/Icons/UserIcon.png",
                                                    width: 150,
                                                    height: 150,
                                                    fit: BoxFit.cover,
                                                  ),
                                          ),
                                          const SizedBox(
                                              height:
                                                  10), // Espacio entre la imagen y el texto
                                          SizedBox(
                                            height: 100,
                                            width: 200,
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.center,
                                              children: [
                                                Text(
                                                  empleado.nombre_empleado,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                  ),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  empleado.departamento!,
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                  textAlign: TextAlign.center,
                                                ),
                                                Text(
                                                  empleado.posicion_empleado!,
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                  textAlign: TextAlign.center,
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      )
                                    : Wrap(
                                        spacing: 10,
                                        direction: Axis.horizontal,
                                        children: [
                                          ClipRRect(
                                            borderRadius:
                                                BorderRadius.circular(100),
                                            child: empleado.imagen_empleado !=
                                                    null
                                                ? Image.network(
                                                    empleado.imagen_empleado!,
                                                    width: 180,
                                                    height: 180,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (BuildContext
                                                            context,
                                                        Widget child,
                                                        ImageChunkEvent?
                                                            loadingProgress) {
                                                      if (loadingProgress ==
                                                          null) {
                                                        return child;
                                                      }
                                                      return Center(
                                                        child:
                                                            CircularProgressIndicator(
                                                          value: loadingProgress
                                                                      .expectedTotalBytes !=
                                                                  null
                                                              ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  (loadingProgress
                                                                          .expectedTotalBytes ??
                                                                      1)
                                                              : null,
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder:
                                                        (BuildContext context,
                                                            Object exception,
                                                            StackTrace?
                                                                stackTrace) {
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
                                          SizedBox(
                                            height: 200,
                                            width: 200,
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: [
                                                Text(
                                                  empleado.nombre_empleado,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 20,
                                                  ),
                                                ),
                                                Text(
                                                  empleado.departamento!,
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                ),
                                                Text(
                                                  empleado.posicion_empleado!,
                                                  style: const TextStyle(
                                                      color: Colors.white),
                                                )
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                              const SizedBox(height: 50),
                              Center(
                                child: SizedBox(
                                  height: 50,
                                  width: 220,
                                  child: FilledButton(
                                      style: FilledButton.styleFrom(
                                          backgroundColor:
                                              empleadologo.colordeboton,
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 40, vertical: 15),
                                          shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(10))),
                                      onPressed: () {},
                                      child: const Row(
                                        children: [
                                          Icon(Icons.save_alt_rounded),
                                          SizedBox(width: 5),
                                          Text("Guardar contacto")
                                        ],
                                      )),
                                ),
                              ),
                              const SizedBox(height: 50),
                              Center(
                                child: Padding(
                                  padding: const EdgeInsets.all(12.0),
                                  child: GridView.builder(
                                    gridDelegate:
                                        SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: pantallapequena ? 1 : 3,
                                      // Ancho máximo por elemento
                                      mainAxisSpacing: 25, // Espacio vertical
                                      crossAxisSpacing:
                                          25, // Espacio horizontal
                                      childAspectRatio: 5 /
                                          1, // Relación de aspecto (ancho / altura)
                                    ),
                                    shrinkWrap: true, // Ajusta al contenido
                                    physics:
                                        const NeverScrollableScrollPhysics(), // Deshabilita scroll interno
                                    itemCount: datosConIconos.length,
                                    itemBuilder:
                                        (BuildContext context, int index) {
                                      final dato =
                                          datosConIconos[index]['encabezado'];
                                      final icono =
                                          datosConIconos[index]['icon'];
                                      final link =
                                          datosConIconos[index]['link'];

                                      return CustomButtonbox(
                                        texto: dato,
                                        icono: icono,
                                        link: link,
                                      );
                                    },
                                  ),
                                ),
                              )
                            ],
                          ),
                        ),
                      ))
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class CustomButtonbox extends StatelessWidget {
  final String? texto;
  final IconData icono;
  final String link;

  const CustomButtonbox({
    super.key,
    required this.texto,
    required this.icono,
    required this.link,
  });

  Future<void> _abrirEnlace(String url, BuildContext context) async {
    final Uri uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      // Manejar el error si la URL no se puede abrir
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo abrir el enlace')),
      );
      // Alternativamente, puedes lanzar una excepción
      // throw 'No se pudo abrir el enlace $url';
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      onPressed: () {
        String sitioWeb = link;
        if (sitioWeb.isNotEmpty) {
          _abrirEnlace(sitioWeb, context);
        } else {
          // Manejar el caso en que no hay URL disponible
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No hay enlace disponible')),
          );
        }
      },
      style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
      child: Row(
        children: [
          Icon(icono, color: Colors.black54),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto!,
              style: const TextStyle(
                  color: Colors.black87, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis, // Maneja textos largos
            ),
          ),
        ],
      ),
    );
  }
}
