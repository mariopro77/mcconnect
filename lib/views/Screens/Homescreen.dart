import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:mcconnect/views/Screens/Desktop/Changeuser_desktop.dart';
import 'package:mcconnect/views/Screens/Desktop/CreateUser.dart';
// Importa file_picker para Flutter Web
import 'dart:html' as html;
import '../widgets/Drawer.dart'; // Importa el widget Drawer personalizado

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
  void _createUser() {
    // Crea un nuevo objeto Empleados con valores predeterminados
    Empleado nuevoEmpleado = Empleado(
      nombre_empleado: '',
      departamento: '',
      division: '',
      // Asigna valores predeterminados para los demás campos si es necesario
    );

    // Muestra un diálogo que contiene el formulario de creación de usuario
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateUser(
          empleado: nuevoEmpleado,
        );
      },
    );
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
              e.nombre_empleado ?? '',
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
                              "Crear Usuario", // Texto del botón
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


class Empleado {
  int? id_empleado;
  String nombre_empleado;
  String? telefono_empleado;
  String? correo_empleado;
  String? flota_empleado;
  String? extension_empleado;
  String? qr_empleado;
  String? fecha_creacion_empleado;
  String? imagen_empleado;
  int? id_division;
  String? division;
  String? departamento;
  String? estado;
  String? instagram;
  String? ubicacion;
  String? posicion_empleado;
  String? web;

  // Constructor
  Empleado(
      {this.id_empleado,
      required this.nombre_empleado,
      this.telefono_empleado,
      this.correo_empleado,
      this.departamento,
      this.division,
      this.id_division,
      this.estado,
      this.extension_empleado,
      this.fecha_creacion_empleado,
      this.flota_empleado,
      this.imagen_empleado,
      this.qr_empleado,
      this.posicion_empleado,
      this.instagram,
      this.ubicacion,
      this.web});

  // Método factory para crear una instancia de Empleado desde un Map (JSON)
  factory Empleado.fromJson(Map<String, dynamic> json) {
    return Empleado(
      id_empleado:
          json['id_empleado'] != null ? json['id_empleado'] as int : null,
      nombre_empleado: json['nombre_empleado'] as String,
      telefono_empleado: json['telefono_empleado'] as String?,
      correo_empleado: json['correo_empleado'] as String?,
      flota_empleado: json['flota_empleado'] as String?,
      extension_empleado: json['extension_empleado'] as String?,
      qr_empleado: json['qr_empleado'] as String?,
      fecha_creacion_empleado: json['fecha_creacion_empleado'] as String?,
      imagen_empleado: json['imagen_empleado'] as String?,
      division: json['division'] as String?,
      departamento: json['departamento'] as String?,
      estado: json['estado'] as String?,
      instagram: json['instagram'] as String?,
      ubicacion: json['ubicacion'] as String?,
      posicion_empleado: json['posicion_empleado'] as String?,
      web: json['web'] as String?,
      id_division: json['id_division'],
      
    );
  }

  // Método para convertir la instancia de Empleado a un Map (para enviar a la API)
  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = {
      'nombre_empleado': nombre_empleado,
      'telefono_empleado': telefono_empleado ?? '',
      'correo_empleado': correo_empleado ?? '',
      'flota_empleado': flota_empleado ?? '',
      'extension_empleado': extension_empleado ?? '',
      'qr_empleado': qr_empleado ?? '',
      'fecha_creacion_empleado': fecha_creacion_empleado,
      'imagen_empleado': imagen_empleado ?? '',
      'departamento': departamento,
      'estado': estado ?? '',
      'instagram': instagram ?? '',
      'ubicacion': ubicacion ?? '',
      'posicion_empleado': posicion_empleado?? '',
      'web': web ?? '',
      "id_division": id_division,
      
    };

    // Remover id_empleado si es null para no enviarlo al backend
    if (id_empleado != null) {
      data['id_empleado'] = id_empleado;
    }

    return data;
  }
}

/// Función asíncrona que recupera una lista de empleados desde una API basada en una consulta de búsqueda.
Future<List<Empleado>> fetchempleados(String search) async {
  // Codifica la consulta de búsqueda para usarla en una URL
  final encodedSearch = Uri.encodeQueryComponent(search);

  // Construye la URL de la API con la consulta de búsqueda
  final url = 'http://localhost:4000/api/verempleado?search=$encodedSearch';

  // Realiza una petición GET a la API
  final response = await http.get(Uri.parse(url));

  if (response.statusCode == 200) {
    // Decodifica la respuesta JSON
    List<dynamic> data = json.decode(response.body);

    // Convierte cada elemento del JSON en una instancia de [Empleados]
    List<Empleado> empleado =
        data.map((item) => Empleado.fromJson(item)).toList();

    return empleado;
  } else {
    // Si la petición falla, lanza una excepción
    throw Exception("Hubo un error al cargar los datos");
  }
}

/// Widget que representa una tabla de empleados.
/// Extiende de [StatefulWidget] para manejar el estado de la lista de empleados.
class Tabladeempleados extends StatefulWidget {
  final String search; // Consulta de búsqueda para filtrar los empleados
  const Tabladeempleados({super.key, this.search = ''});

  @override
  _TabladeempleadosState createState() => _TabladeempleadosState();
}

/// Estado asociado al widget [Tabladeempleados].
class _TabladeempleadosState extends State<Tabladeempleados> {
  late Future<List<Empleado>>
      futureEmpleados; // Future que contiene la lista de empleados

  @override
  void initState() {
    super.initState();
    // Inicializa el Future con la lista de empleados basada en la búsqueda
    futureEmpleados = fetchempleados(widget.search);
  }

  @override
  void didUpdateWidget(covariant Tabladeempleados oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Si la consulta de búsqueda cambia, actualiza el Future para obtener nuevos datos
    if (oldWidget.search != widget.search) {
      setState(() {
        futureEmpleados = fetchempleados(widget.search);
      });
    }
  }

  /// Función que se ejecuta al seleccionar una fila de la tabla.
  /// Muestra un diálogo para editar el usuario seleccionado.
  _onRowTap(Empleado empleado) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return ChangeuserDesktop(
          empleado: empleado,
          onSantiagoChanged: (bool value) {},
        );
      },
    ).then((shouldRefresh) {
      if (shouldRefresh == true) {
        // Si el diálogo indica que se deben refrescar los datos, actualiza el Future
        setState(() {
          futureEmpleados = fetchempleados(widget.search);
        });
      }
    });
  }

  /// Función para mostrar el diálogo de creación de usuario desde la tabla.
  _Createuser(Empleado empleado, List<String> listaDepartamentos) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return CreateUser(
          empleado: empleado,
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Empleado>>(
      future: futureEmpleados, // Future que contiene la lista de empleados
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Si está esperando la respuesta, muestra un indicador de carga
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          // Si hay un error, muestra un mensaje de error
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (snapshot.hasData) {
          // Si hay datos disponibles, muestra la tabla de empleados
          List<Empleado> empleadosList = snapshot.data!;

          return LayoutBuilder(
            builder: (context, constraints) {
              return Container(
                width: constraints.maxWidth, // Ancho máximo disponible
                height: constraints.maxHeight, // Altura máxima disponible
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10), // Bordes redondeados
                  color: Colors.white, // Color de fondo blanco
                ),
                child: SingleChildScrollView(
                  scrollDirection:
                      Axis.vertical, // Permite el desplazamiento vertical
                  child: DataTable(
                    showCheckboxColumn:
                        false, // No muestra la columna de checkboxes
                    dividerThickness:
                        0.1, // Grosor de los divisores entre filas
                    border: const TableBorder(
                      top: BorderSide.none,
                      bottom: BorderSide.none,
                      left: BorderSide.none,
                      right: BorderSide.none,
                      horizontalInside: BorderSide.none,
                      verticalInside: BorderSide.none,
                    ), // Define bordes personalizados para la tabla
                    columns: const [
                      // Definición de las columnas de la tabla
                      DataColumn(
                        label: Text(
                          'Nombre',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Ext',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Departamento',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Grupo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                      DataColumn(
                        label: Text(
                          'Correo',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black,
                          ),
                        ),
                      ),
                    ],
                    rows: empleadosList.map((empleado) {
                      return DataRow(
                        onSelectChanged: (bool? selected) {
                          if (selected == true) {
                            _onRowTap(
                                empleado); // Llama a la función al seleccionar una fila
                          }
                        },
                        color: WidgetStateProperty.all(
                          // Alterna el color de fondo de las filas para mejor legibilidad
                          empleadosList.indexOf(empleado) % 2 == 0
                              ? Colors.grey.withOpacity(0.2)
                              : Colors.grey.withOpacity(0.1),
                        ),
                        cells: [
                          // Definición de las celdas de cada fila
                          DataCell(
                            Text(
                              empleado.nombre_empleado ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A6A6A),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              empleado.extension_empleado ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A6A6A),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              empleado.departamento!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A6A6A),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              empleado.division == "ASW"
                                  ? "Figibox"
                                  : empleado.division!,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A6A6A),
                              ),
                            ),
                          ),
                          DataCell(
                            Text(
                              empleado.correo_empleado ?? '',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF6A6A6A),
                              ),
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              );
            },
          );
        } else {
          // Si no hay datos, muestra un mensaje indicando que no hay datos disponibles
          return const Center(child: Text('No hay datos disponibles'));
        }
      },
    );
  }
}
