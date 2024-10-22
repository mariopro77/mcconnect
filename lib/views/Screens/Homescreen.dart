import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:mcconnect/Components/tablaempleados.dart';
import 'package:mcconnect/Providers/listaempleados.dart';
import 'package:mcconnect/Providers/visibilidadusuarios.dart';
import 'package:mcconnect/views/Screens/Desktop/CreateUser.dart';
import 'package:provider/provider.dart';
// Importa file_picker para Flutter Web
import 'dart:html' as html;
import '../../widgets/Drawer.dart'; // Importa el widget Drawer personalizado

import 'package:csv/csv.dart'; // Importa el paquete csv
// Importa dart:html para manejar la descarga en la web

/// Clase que representa la pantalla de inicio de la aplicación.
/// Extiende de [StatefulWidget] ya que mantiene el estado interno.
class Homescreen extends StatefulWidget {
  const Homescreen({super.key});

  @override
  State<Homescreen> createState() => _HomescreenState();
}

/// Estado asociado al widget [Homescreen].
class _HomescreenState extends State<Homescreen> {
  int refreshKey = 0;
  // Controlador para el campo de búsqueda
  TextEditingController searchController = TextEditingController();

  // Variable que almacena la consulta de búsqueda actual
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    // Añade un listener al controlador de búsqueda para actualizar la consulta en tiempo real
    searchController.addListener(() {
      setState(() {
        searchQuery = searchController.text;
      });
    });
  }

  @override
  void dispose() {
    // Libera el controlador de búsqueda cuando el widget se elimina
    searchController.dispose();
    super.dispose();
  }

  /// Función para mostrar el diálogo de creación de un nuevo usuario.
  Future<void> _createUser() async {
    // Crea un nuevo objeto Empleado con valores predeterminados
    Empleado nuevoEmpleado = Empleado(
      nombre_empleado: '',
      departamento: '',
      division: '',
      // Asigna valores predeterminados para los demás campos si es necesario
    );

    // Muestra el diálogo y espera su resultado
    bool? result = await showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateUser(
          empleado: nuevoEmpleado,
        );
      },
    );

    // Si el resultado es true, significa que se agregó un nuevo empleado
    if (result == true) {
      setState(() {
        refreshKey++; // Incrementa refreshKey para forzar la reconstrucción
      });
      // Opcional: Muestra un mensaje de confirmación
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Empleado agregado exitosamente')),
      );
    }
  }

  /// Función para exportar la tabla de empleados a un archivo CSV.
  void _exportToCSV() async {
    try {
      // 1. Recupera la lista de empleados basada en la consulta de búsqueda actual
      List<Empleado> empleados = await fetchempleados(searchQuery);

      if (empleados.isEmpty) {
        // Si no hay empleados para exportar, muestra un mensaje al usuario
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No hay empleados para exportar')),
        );
        return;
      }

      // 2. Convierte los datos a formato CSV
      List<List<String>> csvData = [
        // Encabezados del CSV
        ['Nombre', 'Ext', 'Departamento', 'Grupo', 'Correo'],
        // Datos de cada empleado
        ...empleados.map((e) => [
              e.nombre_empleado,
              e.extension_empleado ?? '',
              e.departamento ?? '',
              e.division ?? '',
              e.correo_empleado ?? '',
            ]),
      ];

      // Convierte la lista de listas a una cadena CSV
      String csv = const ListToCsvConverter().convert(csvData);

      // 3. Crea un Blob a partir de la cadena CSV
      final bytes = utf8.encode(csv);
      final blob = html.Blob([bytes], 'text/csv');

      // 4. Crea una URL para el Blob
      final url = html.Url.createObjectUrlFromBlob(blob);

      // 5. Crea un elemento de ancla invisible y desencadena la descarga
      final anchor = html.AnchorElement(href: url)
        ..setAttribute('download', 'empleados.csv')
        ..click();

      // 6. Revoca la URL del Blob para liberar recursos
      html.Url.revokeObjectUrl(url);

      // Opcional: Notifica al usuario que la exportación se completó
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Exportación completada')),
      );
    } catch (e) {
      // Maneja cualquier error que ocurra durante el proceso de exportación
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error al exportar: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final visibilidadProvider =
        Provider.of<Visibilidadusuarios>(context, listen: false);
    return Scaffold(
      backgroundColor: Colors.white, // Color de fondo de la pantalla
      appBar: AppBar(
        backgroundColor:
            Colors.white, // Color de fondo de la barra de aplicaciones
        forceMaterialTransparency:
            true, // Hace que la barra de aplicaciones sea transparente
      ),
      drawer: const ContenidoDrawer(), // Incluye el widget Drawer personalizado
      body: Container(
        decoration: const BoxDecoration(
          // Define un degradado de colores como fondo de la pantalla
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF17A2B8), // Color al inicio del degradado
              Color(0xFF117585), // Color en el medio del degradado
              Color.fromARGB(255, 21, 95, 107), // Color intermedio
              Color.fromARGB(255, 6, 72, 82), // Color al final del degradado
            ],
            stops: [
              0.0,
              0.5,
              0.75,
              1.0
            ], // Posiciones de los colores en el degradado
          ),
        ),
        child: Center(
          child: Padding(
            padding:
                const EdgeInsets.all(26.0), // Espaciado alrededor del contenido
            child: LayoutBuilder(
              builder: (context, constraints) {
                return ConstrainedBox(
                  constraints: BoxConstraints(minWidth: constraints.maxWidth),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment
                        .start, // Alineación horizontal a la izquierda
                    children: [
                      Wrap(
                        spacing: 20, // Espaciado horizontal entre widgets
                        runSpacing:
                            20, // Espaciado vertical entre líneas de widgets
                        children: [
                          // Campo de búsqueda de empleados
                          Material(
                            elevation: 5, // Nivel de sombra
                            shadowColor: Colors.grey, // Color de la sombra
                            borderRadius:
                                BorderRadius.circular(10), // Bordes redondeados
                            child: SizedBox(
                              height: 50, // Altura del campo de búsqueda
                              width: 400, // Ancho del campo de búsqueda
                              child: TextField(
                                controller:
                                    searchController, // Controlador del campo de búsqueda
                                cursorColor: Colors.black, // Color del cursor
                                decoration: const InputDecoration(
                                  fillColor: Colors
                                      .white, // Color de relleno del campo
                                  hintText: "Buscar...", // Texto de sugerencia
                                  hintStyle: TextStyle(
                                      color: Colors
                                          .black), // Estilo del texto de sugerencia
                                  prefixIcon: Icon(Icons
                                      .search), // Ícono al inicio del campo
                                  filled: true, // Activa el relleno
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.all(
                                        Radius.circular(
                                            10)), // Bordes redondeados
                                    borderSide: BorderSide
                                        .none, // Sin borde por defecto
                                  ),
                                ),
                              ),
                            ),
                          ),
                          // Botón para crear un nuevo usuario
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                  0xFF117585), // Color de fondo del botón
                              elevation: 5, // Nivel de sombra
                              shadowColor: Colors.grey, // Color de la sombra
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    10), // Bordes redondeados
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 45,
                                  vertical: 22), // Padding interno del botón
                            ),
                            onPressed: () {
                              _createUser(); // Llama a la función para crear un nuevo usuario
                            },
                            child: const Text(
                              "Agregar Usuario", // Texto del botón
                              style: TextStyle(
                                color: Colors.white, // Color del texto
                                fontWeight: FontWeight.w800, // Grosor del texto
                              ),
                            ),
                          ),
                          // Botón para exportar la tabla a CSV
                          ElevatedButton(
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(
                                    0xFF0A4852), // Color de fondo del botón
                                elevation: 5, // Nivel de sombra
                                shadowColor: Colors.grey, // Color de la sombra
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      10), // Bordes redondeados
                                ),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 45,
                                    vertical: 22), // Padding interno del botón
                              ),
                              onPressed: () {
                                setState(() {
                                  visibilidadProvider
                                      .toggleMostrarUsuariosInactivos();
                                }); // Llama a la función para exportar a CSV
                              },
                              child: Consumer<Visibilidadusuarios>(
                                builder: (context, provider, child) {
                                  return Text(
                                    provider.mostrarUsuariosInactivos
                                        ? "Mostrar Activos"
                                        : "Mostrar Inactivos",
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  );
                                },
                              )
                              // showInactiveUsersOnly ?
                              // Text("Mostrar Activos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                              // :
                              // Text("Mostrar Inactivos", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
                              ),
                          ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(
                                  0xFF0A4852), // Color de fondo del botón
                              elevation: 5, // Nivel de sombra
                              shadowColor: Colors.grey, // Color de la sombra
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    10), // Bordes redondeados
                              ),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 45,
                                  vertical: 22), // Padding interno del botón
                            ),
                            onPressed: () {
                              _exportToCSV(); // Llama a la función para exportar a CSV
                            },
                            child: const Text(
                              "Exportar", // Texto del botón
                              style: TextStyle(
                                color: Colors.white, // Color del texto
                                fontWeight: FontWeight.w800, // Grosor del texto
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20), // Espaciado vertical
                      // Tabla de empleados expandida para ocupar el espacio restante
                      Expanded(
                        child: Material(
                          elevation: 5, // Nivel de sombra
                          shadowColor: Colors.grey, // Color de la sombra
                          borderRadius:
                              BorderRadius.circular(10), // Bordes redondeados
                          child: Tabladeempleados(
                              key: ValueKey(refreshKey),
                              search:
                                  searchQuery), // Widget que muestra la tabla de empleados
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}



