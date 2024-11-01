import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// Widget que representa el formulario de inicio de sesión
class LoginForm extends StatelessWidget {
  const LoginForm({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Fondo con degradado en la parte inferior
          Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              height: 300, // Altura del contenedor del degradado
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.center, // Inicio del degradado en el centro
                  end: Alignment.bottomCenter, // Fin del degradado en la parte inferior
                  colors: [
                    Colors.white.withOpacity(0.0), // Transparente en el inicio
                    const Color.fromARGB(152, 23, 163, 184).withOpacity(0.1), // Azul claro en el medio
                    const Color.fromARGB(167, 185, 185, 8).withOpacity(0.2), // Amarillo claro hacia el final
                    // Puedes agregar más colores si lo deseas
                  ],
                  stops: const [0.0, 0.6, 1.0], // Posiciones de los colores en el degradado
                ),
              ),
            ),
          ),
          // Formulario centrado en la pantalla
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0), // Espaciado alrededor del formulario
              child: Column(
                mainAxisSize: MainAxisSize.min, // El column ocupa el mínimo espacio vertical necesario
                children: [
                  // Logo de la aplicación
                  SizedBox(
                    width: 400, // Ancho del contenedor del logo
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 60), // Espaciado inferior del logo
                      child: Image.asset(
                        "Logo/Logo.png", // Ruta de la imagen del logo
                        height: 100, // Altura del logo
                        width: 400, // Ancho del logo
                      ),
                    ),
                  ),
                  // Campo de texto para el correo electrónico
                  const Formfield(
                    texthint: "Correo electrónico", // Texto de sugerencia
                    icono: Icons.mail_outlined, // Ícono al inicio del campo
                  ),
                  const SizedBox(height: 20), // Espaciado vertical
                  // Campo de texto para la contraseña
                  const Formfield(
                    texthint: "Contraseña", // Texto de sugerencia
                    icono: Icons.lock_outline, // Ícono al inicio del campo
                  ),
                  // Botón para recuperar la contraseña olvidada
                  Container(
                    width: 400, // Ancho del contenedor
                    alignment: Alignment.centerRight, // Alineación del contenido a la derecha
                    margin: const EdgeInsets.only(top: 5), // Margen superior
                    child: TextButton(
                      style: TextButton.styleFrom(
                        foregroundColor: const Color(0xFF03A9F4), // Color del texto
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10), // Bordes redondeados
                        ),
                      ),
                      onPressed: () {
                        // Funcionalidad para recuperar contraseña (a implementar)
                      },
                      child: const Text(
                        "¿Olvidaste tu Contraseña?", // Texto del botón
                        style: TextStyle(color: Color(0xFF17A2B8)), // Estilo del texto
                      ),
                    ),
                  ),
                  const SizedBox(height: 30), // Espaciado antes del botón de inicio de sesión
                  // Botón para iniciar sesión
                  ElevatedButton(
                    onPressed: () {
                      // Navegar a la pantalla de inicio después de iniciar sesión
                     context.go('/home');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF17A2B8), // Color de fondo del botón
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10), // Bordes redondeados del botón
                      ),
                      minimumSize: const Size(400, 50), // Tamaño mínimo del botón
                    ),
                    child: const Text(
                      "Iniciar Sesión", // Texto del botón
                      style: TextStyle(color: Colors.white, fontSize: 14), // Estilo del texto
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Widget personalizado para los campos del formulario
class Formfield extends StatelessWidget {
  final String texthint; // Texto de sugerencia en el campo
  final IconData icono; // Ícono al inicio del campo

  const Formfield({
    required this.texthint,
    required this.icono,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400, // Ancho del campo de texto
      child: TextFormField(
        decoration: InputDecoration(
          prefixIcon: Icon(icono), // Ícono al inicio del campo
          contentPadding:
              const EdgeInsets.symmetric(vertical: 20, horizontal: 10), // Espaciado interno del campo
          isDense: true, // Reduce el tamaño vertical del campo
          hintText: texthint, // Texto de sugerencia
          hintStyle: const TextStyle(fontSize: 14), // Estilo del texto de sugerencia
          border: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)), // Bordes redondeados
            borderSide: BorderSide(color: Color(0xFEEEEEEE)), // Color del borde por defecto
          ),
          enabledBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)), // Bordes redondeados
            borderSide:
                BorderSide(color: Color(0xFEEEEEEE)), // Color del borde cuando no está enfocado
          ),
          focusedBorder: const OutlineInputBorder(
            borderRadius: BorderRadius.all(Radius.circular(10)), // Bordes redondeados
            borderSide: BorderSide(
                color: Color.fromARGB(177, 158, 158, 158),
                width: 2), // Color y grosor del borde cuando está enfocado
          ),
          fillColor: const Color.fromARGB(54, 230, 230, 230), // Color de relleno del campo
          filled: true, // Activa el relleno
        ),
      ),
    );
  }
}
