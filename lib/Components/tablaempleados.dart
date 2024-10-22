

import 'package:flutter/material.dart';
import 'package:mcconnect/Providers/listaempleados.dart';
import 'package:mcconnect/Providers/visibilidadusuarios.dart';
import 'package:mcconnect/views/Screens/Desktop/Changeuser_desktop.dart';
import 'package:mcconnect/views/Screens/Desktop/CreateUser.dart';
import 'package:provider/provider.dart';

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
    final visibilidadusuarios =
        Provider.of<Visibilidadusuarios>(context, listen: false);
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
                    rows: empleadosList
                        .where((empleado) =>
                            visibilidadusuarios.mostrarUsuariosInactivos
                                ? empleado.estado == 'Inactivo'
                                : empleado.estado == 'Activo')
                        .map((empleado) {
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
