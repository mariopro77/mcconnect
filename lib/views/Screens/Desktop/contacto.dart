import 'package:flutter/material.dart';
import 'package:mcconnect/Providers/listaempleados.dart';

class Obtenerlogo {
  final String path;
  final double height;
  final double width;
  final Color color1;

  Obtenerlogo(
      {required this.path,
      required this.height,
      required this.width,
      required this.color1});
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
            path: '../assets/Logo/logo2.png',
            height: 40,
            width: 40,
            color1: Colors.blue);
      default:
        return Obtenerlogo(
            path: '../assets/Logo/logo2.png', // Ruta por defecto
            height: 60,
            width: 180,
            color1: Colors.grey);
    }
  }

  @override
  Widget build(BuildContext context) {
    Obtenerlogo empleadologo = obtenerlogo(empleado.division ?? 'default');
    return Scaffold(
        body: Center(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: IntrinsicHeight(
                child: Container(
              width: 800,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: const Color(0xFF17A2B8)),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.qr_code_2_outlined,
                                color: Colors.white, size: 30)),
                        IntrinsicHeight(
                          child: Container(
                            decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(10),
                                color: Colors.white),
                            child: Image.asset(
                              empleadologo.path,
                              height: empleadologo.height,
                              width: empleadologo.width,
                            ),
                          ),
                        ),
                        IconButton(
                            onPressed: () {},
                            icon: const Icon(Icons.share_outlined,
                                color: Colors.white, size: 25))
                      ],
                    ),
                  ),
                  Center(
                      child: Wrap(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15.0),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(
                              100), // Hace que la imagen tenga bordes circulares
                          child: empleado.imagen_empleado != null
                              ? Image.network(
                                  empleado.imagen_empleado!,
                                  width: 150,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (BuildContext context,
                                      Widget child,
                                      ImageChunkEvent? loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return Center(
                                      child: CircularProgressIndicator(
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
                                  errorBuilder: (BuildContext context,
                                      Object exception,
                                      StackTrace? stackTrace) {
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
                      ),
                      Container( 
                        height: 150,
                        width: 150,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          borderRadius: BorderRadius.circular(100)
                        ),
                      )                    
                    ],
                  )),
                ],
              ),
            )),
          )
        ],
      ),
    ));
  }
}
