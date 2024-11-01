import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;


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
      'posicion_empleado': posicion_empleado ?? '',
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
      
      // for (var emp in empleado) {
      //   print('ID: ${emp.id_empleado}, Nombre: ${emp.nombre_empleado}');
      // }


    return empleado;
  } else {
    // Si la petición falla, lanza una excepción
    throw Exception("Hubo un error al cargar los datos");
  }
}

class ListaEmpleados extends ChangeNotifier {
  List<Empleado> _empleados = [];

  /// Getter para acceder a la lista de empleados
  List<Empleado> get empleados => _empleados;

  /// Método para obtener empleados desde la API
  Future<void> fetchEmpleados(String search) async {
    try {
      _empleados = await fetchempleados(search);
      print(empleados);
      for (var emp in empleados) {
        print('ID: ${emp.id_empleado}, Nombre: ${emp.nombre_empleado}');
      }
      notifyListeners();
    } catch (e) {
      // Manejar errores según sea necesario
      print('Error al obtener empleados: $e');
      // Puedes agregar lógica para manejar errores en la UI
    }
  }


  /// Método para obtener un empleado por su ID
 Empleado? getEmpleadoByNombre(String nombre) {
    try {
      return _empleados.firstWhere(
        (empleado) => empleado.nombre_empleado.toLowerCase() == nombre.toLowerCase(),
      );
    } catch (e) {
      return null;
    }
  }
}