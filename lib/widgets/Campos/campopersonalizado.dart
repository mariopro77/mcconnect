import 'package:flutter/material.dart';

// Widget personalizado para campos de texto
class CustomTextFormField extends StatelessWidget {
  final String labelText; // Texto de la etiqueta
  final bool readOnly; // Indica si el campo es de solo lectura
  final ValueChanged<String>? onChange; // Callback para cambios en el texto
  final String? initialValue; // Valor inicial del campo
  final TextEditingController? controller; // Controlador de texto

  const CustomTextFormField({
    super.key,
    required this.labelText,
    this.readOnly = false,
    this.onChange,
    this.initialValue,
    this.controller, String? Function(dynamic value)? validator,
  });

  static const double kFieldWidth = 250.0; // Ancho constante para campos

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: kFieldWidth, // Establece el ancho del campo
      child: TextFormField(
        controller: controller, // Asigna el controlador si existe
        readOnly: readOnly, // Establece si el campo es de solo lectura
        initialValue: controller == null
            ? initialValue
            : null, // Asigna el valor inicial si no hay controlador
        textAlign: TextAlign.start, // Alineación del texto
        decoration: InputDecoration(
          labelText: labelText, // Texto de la etiqueta
          labelStyle:
              const TextStyle(color: Colors.grey), // Estilo de la etiqueta
          floatingLabelStyle: const TextStyle(
              color: Colors.black), // Estilo de la etiqueta al flotar
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // Bordes redondeados
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // Bordes redondeados
            borderSide: const BorderSide(
                color: Colors.grey, width: 1.0), // Color y ancho del borde
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10), // Bordes redondeados
            borderSide: const BorderSide(
                color: Color(0xFF17A2B8),
                width: 2.0), // Color y ancho del borde al enfocar
          ),
        ),
        onChanged: (v) => onChange != null
            ? onChange!(v)
            : null, // Maneja cambios en el texto
        cursorColor: Colors.black, // Color del cursor
        maxLines: null, // Permite múltiples líneas
        style: const TextStyle(color: Colors.black), // Estilo del texto
      ),
    );
  }
}