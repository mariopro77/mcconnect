import 'package:flutter/material.dart';
import 'package:mcconnect/views/widgets/LoginForm/login_form.dart';


void main() {
  runApp(const MainApp());
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
      home: 
      LoginForm()
      
    );
  }
}


