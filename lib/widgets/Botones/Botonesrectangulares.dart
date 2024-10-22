import 'package:flutter/material.dart';

// Widget personalizado para botones
class CustomButton extends StatelessWidget {
  final String text; // Texto del botón
  final Color? textColor; // Color del texto
  final Color? color; // Color de fondo del botón
  final VoidCallback onPressed; // Callback al presionar el botón

  const CustomButton({
    super.key,
    required this.text,
    required this.color,
    required this.onPressed,
    this.textColor,
  });

  static const EdgeInsets kButtonPadding = EdgeInsets.symmetric(
      horizontal: 40, vertical: 20); // Padding constante para botones

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: onPressed, // Asigna la función al presionar
      style: FilledButton.styleFrom(
        backgroundColor: color, // Color de fondo
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10)), // Bordes redondeados
        padding: kButtonPadding, // Padding del botón
      ),
      child: Text(
        text,
        style: TextStyle(color: textColor), // Estilo del texto
      ),
    );
  }
}