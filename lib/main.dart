import 'package:flutter/material.dart';
import 'package:mcconnect/Providers/listaempleados.dart';
import 'package:mcconnect/Providers/visibilidadusuarios.dart';
import 'package:mcconnect/views/Screens/Desktop/Contacto.dart';
import 'package:mcconnect/widgets/LoginForm/login_form.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(
    MultiProvider(providers: [
      ChangeNotifierProvider(
        create: (context) => Visibilidadusuarios(),
      ),
      ChangeNotifierProvider(
        create: (context) => Empleado(nombre_empleado: ''),
      )
    ],
    child: const MainApp(),
    )
    
  );
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(seedColor: Colors.black),
          primarySwatch: Colors.grey,
        ),
        debugShowCheckedModeBanner: false,
        home: const LoginForm());
  }
}
