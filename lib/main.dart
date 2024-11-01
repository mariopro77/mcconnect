import 'package:flutter/material.dart';
import 'package:mcconnect/Providers/listaempleados.dart';
import 'package:mcconnect/Providers/visibilidadusuarios.dart';
import 'package:mcconnect/views/Screens/Desktop/Contacto.dart';
import 'package:mcconnect/views/Screens/Homescreen.dart';
import 'package:mcconnect/widgets/LoginForm/login_form.dart';
import 'package:provider/provider.dart';
import 'package:go_router/go_router.dart';

void main() {
  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(
        create: (context) => Visibilidadusuarios(),
      ),
      // ChangeNotifierProvider(
      //   create: (context) => Empleado(),
      // ),
      ChangeNotifierProvider(
        create: (context) => ListaEmpleados(),
      ),
    ],
    child: const MainApp(),
  ));
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Configuración de GoRouter
    final GoRouter router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          name: 'login',
          builder: (context, state) => const LoginForm(),
        ),
        GoRoute(
          path: '/home',
          name: 'home',
          builder: (context, state) => const Homescreen(),
        ),
        GoRoute(
          path: '/contacto/:nombre',
          name: 'contacto',
          builder: (context, state) {
            // Obtener el nombre codificado desde los parámetros de la ruta
            final nombreCodificado = state.pathParameters['nombre'];
            // Decodificar el nombre para manejar espacios y caracteres especiales
            final nombre = Uri.decodeComponent(nombreCodificado ?? '');

            if (nombre.isEmpty) {
              print('Nombre de empleado inválido.');
              return const Scaffold(
                body: Center(child: Text('Nombre de empleado inválido.')),
              );
            }

            final listaEmpleados =
                Provider.of<ListaEmpleados>(context, listen: false);

            return FutureBuilder<void>(
              future: listaEmpleados.fetchEmpleados(
                  ''), // Puedes pasar el término de búsqueda si es necesario
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  // Muestra un indicador de carga mientras se obtienen los datos
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                } else if (snapshot.hasError) {
                  // Maneja los errores si los hay
                  return const Scaffold(
                    body: Center(child: Text('Error al cargar los datos')),
                  );
                } else {
                  // Los datos ya están cargados, podemos obtener el empleado por nombre
                  final empleado = listaEmpleados.getEmpleadoByNombre(nombre);
                  if (empleado == null) {
                    print('Empleado no encontrado.');
                    return const Scaffold(
                      body: Center(child: Text('Empleado no encontrado.')),
                    );
                  }
                  return Contacto(empleado: empleado);
                }
              },
            );
          },
        ),
      ],
    );

    return MaterialApp.router(
      title: 'MCConnect',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
        primarySwatch: Colors.grey,
      ),
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
