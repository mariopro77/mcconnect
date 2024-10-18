// services/division_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mcconnect/views/Screens/Desktop/Divisiones/divisiones.dart'; // Ajusta la ruta según tu estructura

class DivisionService {
  final String baseUrl;

  DivisionService({required this.baseUrl});

  // Obtener todas las divisiones
  Future<List<Division>> getAllDivisiones() async {
    final url = Uri.parse('$baseUrl/api/divisiones');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => Division.fromJson(json)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  // Obtener los detalles de una división específica
  Future<Map<String, dynamic>?> getDivisionDetails(String divisionId) async {
    final url = Uri.parse('$baseUrl/api/division/$divisionId');

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }
}
